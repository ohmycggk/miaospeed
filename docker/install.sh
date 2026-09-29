#!/bin/sh

# 获取系统架构信息
ARCH=$(uname -m)

echo "平台: ${ARCH}"

# 获取系统位数
BITS=$(getconf LONG_BIT)

# 获取最新的标签名称
LATEST_TAG=$(curl -s https://api.github.com/repos/ohmycggk/miaospeed/releases/latest | grep 'tag_name' | cut -d '"' -f 4)

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

curl -L "https://github.com/ohmycggk/miaospeed/releases/download/$LATEST_TAG/miaospeed-$ARCH-$LATEST_TAG.tar.gz" -o "/opt/miaospeed.tar.gz"
tar -xzf /opt/miaospeed.tar.gz -C /opt/
mv /opt/miaospeed-$ARCH /opt/miaospeed
chmod +x /opt/miaospeed