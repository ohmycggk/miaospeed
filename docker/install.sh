#!/bin/sh

set -e

# 获取系统架构信息
ARCH=$(uname -m)

echo "平台: ${ARCH}"

# 获取系统位数
BITS=$(getconf LONG_BIT)

if [ "$ARCH" = "x86_64" ] && [ "$BITS" = "64" ]; then
  echo "架构: linux/amd64"
  ARCH="linux-amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  echo "架构: linux/arm64"
  ARCH="linux-arm64"
elif [ "$ARCH" = "armv7l" ]; then
  echo "架构: linux/arm/v7"
  ARCH="linux-armv7"
elif [ "$ARCH" = "x86_64" ] && [ "$BITS" = "32" ]; then
  echo "架构: linux/386"
  ARCH="linux-386"
fi

# 获取最新的 release 信息
RELEASE_JSON=$(curl -sf https://api.github.com/repos/ohmycggk/miaospeed/releases/latest)
LATEST_TAG=$(echo "$RELEASE_JSON" | grep 'tag_name' | head -n 1 | cut -d '"' -f 4)
echo "最新版本: ${LATEST_TAG}"

# 从 release 的 assets 中解析对应架构的下载地址，避免安装包命名与版本号不一致导致 404
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | cut -d '"' -f 4 | grep -E "miaospeed-$ARCH-[^/]*\.tar\.gz$" | grep -v -- "-v3-" | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
  DOWNLOAD_URL="https://github.com/ohmycggk/miaospeed/releases/download/$LATEST_TAG/miaospeed-$ARCH-$LATEST_TAG.tar.gz"
fi

echo "下载: $DOWNLOAD_URL"

curl -fSL "$DOWNLOAD_URL" -o /opt/miaospeed.tar.gz
tar -tzf /opt/miaospeed.tar.gz > /dev/null
tar -xzf /opt/miaospeed.tar.gz -C /opt/
mv /opt/miaospeed-$ARCH /opt/miaospeed
chmod +x /opt/miaospeed
