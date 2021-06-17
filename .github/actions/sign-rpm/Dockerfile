# FROM centos:7

# RUN yum install -y \
# 	gcc \
# 	make \
# 	rpm-build \
# 	rpm-sign && yum clean all

# COPY entrypoint.sh /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]

FROM centos:7

RUN yum install -y gcc gcc-c++ \
                   libtool libtool-ltdl \
                   make cmake \
                   git \
                   pkgconfig \
                   sudo \
                   automake autoconf \
                   expect \
                   yum-utils rpm-build rpm-sign && \
    yum clean all

RUN useradd builder -u 1000 -m -G users,wheel && \
    echo "builder ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir /home/builder/rpmbuild && \
	mkdir /home/builder/.gnupg && \
	chown -R builder /home/builder

COPY entrypoint.sh /entrypoint.sh
COPY rpmmacros /home/builder/.rpmmacros
RUN chown builder /home/builder/.rpmmacros

# USER builder
ENTRYPOINT ["/entrypoint.sh"]