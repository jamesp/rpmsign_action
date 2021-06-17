#!/bin/sh -l
# ARGUMENTS
# $1 rpm spec directory
# $2 gpg name
# $3 gpg passphrase
# $4 gpg exported key

SPEC_DIR=$1
GPG_NAME=$2
GPG_PHRASE=$3
GPG_KEY_ENC=$4

echo dir=$SPEC_DIR
echo name=$GPG_NAME

# setup the RPM signing expect utility
cat <<EOF > rpm-sign.exp
#!/usr/bin/expect -f
set timeout 120
spawn rpm --addsign {*}\$argv
expect -exact "Enter pass phrase: "
send -- "$GPG_PHRASE\\r"
expect eof
EOF
chmod +x rpm-sign.exp

printf "$GPG_KEY_ENC" | base64 --decode > private.key
sudo -u builder gpg --batch --import private.key
rm private.key
sudo -u builder gpg -k
sudo -u builder echo "%_gpg_name $GPG_NAME" >> /home/builder/.rpmmacros
sudo -u builder echo "$GPG_PHRASE" >> /home/builder/passphrase
sudo -u builder chmod -R 700 /home/builder/.gnupg
#cat /home/builder/.rpmmacros
#cat /dev/null | sudo -u builder rpmsign --addsign /home/builder/rpmbuild/x86_64/Hello-1-0.x86_64.rpm

echo "Building RPMs"
SPEC_FILES="$SPEC_DIR/*.spec"
for spec in $SPEC_FILES
do
	sudo -u builder rpmbuild -bb $spec 2> build.log
	if [ $? -eq 0 ]; then
		echo "Built: $spec"
	else
		echo "FAILED: Building $spec"
		cat build.log
	fi
done

echo "Signing RPMs"
RPM_FILES="/home/builder/rpmbuild/RPMS/x86_64/*.rpm"
for rpm in $RPM_FILES
do
	sudo -u builder ./rpm-sign.exp $rpm > sign.log
	# we can't check the error code of the expect script as
	# it is always zero, so grep the log for failure instead
	if grep -q "signing failed" sign.log; then
	    echo "FAILED: Signing $rpm"
	    cat sign.log
	    exit 1
	else
	    echo "Signed: $rpm"
	fi

done

cp -r /home/builder/rpmbuild/RPMS $GITHUB_WORKSPACE/RPMS
