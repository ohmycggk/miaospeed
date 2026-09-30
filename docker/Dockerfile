FROM alpine:latest

ENV TZ=Asia/Shanghai

# TARGETARCH/TARGETVARIANT are injected by buildx (386, amd64, arm+v7, arm64/v8)
ARG TARGETARCH
ARG TARGETVARIANT
ARG MIAOSPEED_VERSION

COPY bin/miaospeed-linux-${TARGETARCH}${TARGETVARIANT}-${MIAOSPEED_VERSION}.tar.gz /tmp/miaospeed.tar.gz

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    tar -xzf /tmp/miaospeed.tar.gz -C /opt && \
    mv /opt/miaospeed-linux-* /opt/miaospeed && \
    chmod +x /opt/miaospeed && \
    rm /tmp/miaospeed.tar.gz

ENTRYPOINT ["/opt/miaospeed"]
