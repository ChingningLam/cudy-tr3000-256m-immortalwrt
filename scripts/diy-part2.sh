#!/usr/bin/env bash
# OpenWrt DIY part 2: apply device defaults after feeds have been installed.

set -euo pipefail

replace_all_or_fail() {
  local pattern="$1"
  local replacement="$2"
  local file="$3"

  if ! grep -qF "$pattern" "$file"; then
    echo "Expected text was not found in $file: $pattern" >&2
    exit 1
  fi
  local sed_pattern="${pattern//./\\.}"
  sed -i "s|$sed_pattern|$replacement|g" "$file"
}

BASE_FILES=package/base-files/files/bin/config_generate
DEVICE_TREE=target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dtsi
HNAT_CONFIG=target/linux/mediatek/filogic/config-6.12
AURORA_DEFAULTS=package/luci-app-aurora-config/root/usr/share/aurora/default.template
SHADOW_FILE=package/base-files/files/etc/shadow

# ===== User settings: edit these to change login details =====
LAN_IP="192.168.6.1"
ROUTER_HOSTNAME="Cudy-TR3000"
# Leave empty to keep the source tree's default root password setting.
# To set one, generate a SHA-512 crypt hash with: openssl passwd -6
ROOT_PASSWORD_HASH=""

replace_all_or_fail '192.168.1.1' "$LAN_IP" "$BASE_FILES"
replace_all_or_fail 'ImmortalWrt' "$ROUTER_HOSTNAME" "$BASE_FILES"

# If provided, install only the encrypted hash in /etc/shadow; never store a
# plaintext password in the repository.
if [[ -n "$ROOT_PASSWORD_HASH" ]]; then
  if [[ ! "$ROOT_PASSWORD_HASH" =~ ^\$6\$[A-Za-z0-9./]+\$[A-Za-z0-9./]+$ ]]; then
    echo "ROOT_PASSWORD_HASH must be a SHA-512 crypt hash (openssl passwd -6)" >&2
    exit 1
  fi
  if [[ ! -f "$SHADOW_FILE" ]]; then
    echo "Root password file not found: $SHADOW_FILE" >&2
    exit 1
  fi
  SHADOW_TMP=$(mktemp "${SHADOW_FILE}.XXXXXX")
  if ! awk -F: -v hash="$ROOT_PASSWORD_HASH" 'BEGIN { OFS = ":" } $1 == "root" { $2 = hash; found = 1 } { print } END { if (!found) exit 1 }' "$SHADOW_FILE" > "$SHADOW_TMP"; then
    rm -f "$SHADOW_TMP"
    echo "Could not update the root entry in $SHADOW_FILE" >&2
    exit 1
  fi
  chmod 600 "$SHADOW_TMP"
  mv "$SHADOW_TMP" "$SHADOW_FILE"
fi

# Seed the Aurora theme's first-boot UCI config with dropdown navigation.
if grep -qF "option nav_type 'dropdown'" "$AURORA_DEFAULTS"; then
  echo "Aurora dropdown navigation is already the default"
else
  replace_all_or_fail "option nav_type 'mega-menu'" "option nav_type 'dropdown'" "$AURORA_DEFAULTS"
fi

# Enable the MTK HNAT kernel driver, which is disabled in this source tree's
# default Filogic kernel configuration.
if grep -q '^CONFIG_NET_MEDIATEK_HNAT=y$' "$HNAT_CONFIG"; then
  echo "MediaTek HNAT is already enabled in $HNAT_CONFIG"
elif grep -q '^# CONFIG_NET_MEDIATEK_HNAT is not set$' "$HNAT_CONFIG"; then
  sed -i 's/^# CONFIG_NET_MEDIATEK_HNAT is not set$/CONFIG_NET_MEDIATEK_HNAT=y/' "$HNAT_CONFIG"
else
  echo "Could not locate the MediaTek HNAT option in $HNAT_CONFIG" >&2
  exit 1
fi

# The 25.12 TR3000 device tree no longer exports the old modem_power GPIO.
# Do not carry the 6.6-specific GPIO edit into this source tree.
if [[ -e "$DEVICE_TREE" ]]; then
  echo "Using TR3000 device tree: $DEVICE_TREE"
fi

# Pull the UA3F core and LuCI package.
if [[ -e package/UA3F ]]; then
  echo 'Package destination already exists: package/UA3F' >&2
  exit 1
fi
git clone --depth 1 https://github.com/SunBK201/UA3F.git package/UA3F
