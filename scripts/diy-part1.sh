#!/usr/bin/env bash
# OpenWrt DIY part 1: register additional packages before feeds are updated.

set -euo pipefail

clone_package() {
  local url="$1"
  local destination="$2"

  if [[ -e "$destination" ]]; then
    echo "Package destination already exists: $destination" >&2
    exit 1
  fi

  git clone --depth 1 "$url" "$destination"
}

# Uncomment a feed source when needed.
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >> feeds.conf.default

clone_package https://github.com/eamonxg/luci-theme-aurora package/luci-theme-aurora
clone_package https://github.com/eamonxg/luci-app-aurora-config package/luci-app-aurora-config
clone_package https://github.com/timsaya/luci-app-bandix package/luci-app-bandix
clone_package https://github.com/timsaya/openwrt-bandix package/openwrt-bandix
