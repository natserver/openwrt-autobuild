#!/bin/bash
# Patch the LuCI rpcd script so the independent SoC status panel has a backend.
# Must run after ./scripts/feeds install -a so the injected method survives.

set -e

TARGET="${OPENWRT_PATH:?OPENWRT_PATH is not set}/feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci"

[ -f "$TARGET" ] || { echo "ERROR: LuCI rpcd script not found: $TARGET" >&2; exit 1; }

python3 - "$TARGET" <<'PY'
import sys

path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    src = f.read()

marker = 'return { luci: methods };'
if marker not in src:
    raise SystemExit('ERROR: cannot locate luci methods return marker')

if 'getHomepageStats' in src:
    print('LuCI homepage fix already applied')
    raise SystemExit(0)

addition = """methods.getHomepageStats = {
	call: function() {
		let result = { ok: true };
		let fields = {
			cpufreq: 'cpu_freq',
			governor: 'cpu_governor',
			cputemp: 'cpu_temp',
			wifitemp: 'wifi_temp',
			cpuusage: 'cpu_usage',
			nssusage: 'nss_usage'
		};

		for (let key in fields) {
			let fd = popen('soc-status ' + fields[key]);
			if (fd) {
				result[key] = trim(fd.read('all'));
				fd.close();
			}
			else {
				result[key] = '';
			}
		}

		return result;
	}
};

"""

src = src.replace(marker, addition + marker, 1)
with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print('Injected getHomepageStats into LuCI rpcd script')
PY

if [ -f "$OPENWRT_PATH/files/sbin/soc-status" ]; then
	chmod 755 "$OPENWRT_PATH/files/sbin/soc-status"
fi
