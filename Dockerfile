FROM amazonlinux:2023 AS builder

ARG SENTIEON_VERSION
RUN test -n "$SENTIEON_VERSION"

LABEL container.base.image="amazonlinux:2023" \
      software.version="${SENTIEON_VERSION}" \
      software.website="https://www.sentieon.com/"

# Install igzip
RUN yum update -y \
  && yum install -y tar gzip automake libtool nasm gcc make \
  && mkdir -p /opt/isa-l \
  && curl -L "https://github.com/intel/isa-l/archive/refs/tags/v2.30.0.tar.gz" | \
        tar -C /opt/isa-l -zxf - \
  && cd /opt/isa-l/isa-l-2.30.0 \
  && ./autogen.sh \
  && ./configure --prefix=/usr --libdir=/usr/lib \
  && make install

# Install samtools
RUN yum update -y \
  && yum install -y autoconf automake make gcc perl-Data-Dumper zlib-devel bzip2 bzip2-devel xz-devel curl-devel openssl-devel ncurses-devel tar \
  && mkdir -p /opt/samtools/ \
  && curl -L "https://github.com/samtools/samtools/releases/download/1.19.2/samtools-1.19.2.tar.bz2" | \
      tar -C /opt/samtools/ -jxf - \
  && cd /opt/samtools/samtools-1.19.2 \
  && ./configure \
  && make install

# Install bcftools
RUN yum update -y \
  && yum install -y autoconf automake make gcc perl-Data-Dumper zlib-devel bzip2 bzip2-devel xz-devel curl-devel openssl-devel gsl-devel perl-ExtUtils-Embed tar && \
    mkdir -p /opt/bcftools/ && \
    curl -L "https://github.com/samtools/bcftools/releases/download/1.19/bcftools-1.19.tar.bz2" | \
      tar -C /opt/bcftools/ -jxf - && \
    cd /opt/bcftools/bcftools-1.19/ && \
    ./configure && \
    make install

# Install bedtools
RUN yum update -y && \
    curl -L -o /usr/local/bin/bedtools-2.30.0 "https://github.com/arq5x/bedtools2/releases/download/v2.30.0/bedtools.static.binary"

# Install sentieon
RUN yum update -y && yum install -y tar && \
    mkdir -p /opt/sentieon/ && \
    curl -L "https://s3.amazonaws.com/sentieon-release/software/sentieon-genomics-${SENTIEON_VERSION}.tar.gz" | \
      tar -C /opt/sentieon -zxf -

# Build the container
FROM amazonlinux:2023
ARG SENTIEON_VERSION
ENV SENTIEON_VERSION=$SENTIEON_VERSION

# Copy dependencies from the first stage
COPY --from=builder /opt/sentieon/sentieon-genomics-${SENTIEON_VERSION} /opt/sentieon/sentieon-genomics-${SENTIEON_VERSION}
COPY --from=builder /usr/bin/igzip /usr/bin/igzip
COPY --from=builder /usr/lib/libisal.a /usr/lib/libisal.a
COPY --from=builder /usr/lib/libisal.so.2.0.30 /usr/lib/libisal.so.2.0.30
COPY --from=builder /usr/lib/libisal.la /usr/lib/libisal.la
COPY --from=builder /usr/local/bin/samtools /usr/local/bin/samtools
COPY --from=builder /usr/local/bin/bcftools /usr/local/bin/bcftools
COPY --from=builder /usr/local/bin/bedtools-2.30.0 /usr/local/bin/bedtools-2.30.0

ENV SENTIEON_INSTALL_DIR=/opt/sentieon/sentieon-genomics-${SENTIEON_VERSION}
ENV PATH $SENTIEON_INSTALL_DIR/bin:$PATH
# Install dependencies
RUN yum update -y && yum install -y jemalloc python3 parallel findutils 
ENV LD_PRELOAD=/usr/lib64/libjemalloc.so.2
# A default jemalloc configuration that should work well for most use-cases, see http://jemalloc.net/jemalloc.3.html
ENV MALLOC_CONF=metadata_thp:auto,background_thread:true,dirty_decay_ms:30000,muzzy_decay_ms:30000

# Create links
RUN cd /usr/local/bin/ && \
    ln -s bedtools-2.30.0 bedtools && \
    chmod ugo+x bedtools-2.30.0

RUN cd /usr/lib && \
    ln -s libisal.so.2 libisal.so

# Test the container
RUN sentieon driver --help && \
    igzip --help && \
    samtools --help && \
    bcftools --help && \
    bedtools --help

CMD ["/bin/bash"]

