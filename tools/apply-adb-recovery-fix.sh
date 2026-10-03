#!/system/bin/sh
# Apply the debug init fix to the active system partition from recovery.
set -eu

payload=${1:-/tmp/nabu-adb-fix/init.nabu.debug.rc}
[ -x /system/bin/recovery ] || { echo 'Run this script in recovery.' >&2; exit 1; }
[ -f "$payload" ] || { echo "Missing payload: $payload" >&2; exit 1; }
slot=$(getprop ro.boot.slot_suffix)
case "$slot" in _a|_b) ;; *) echo "Unknown slot: $slot" >&2; exit 1 ;; esac
device=/dev/block/mapper/system${slot}
[ -b "$device" ] || { echo "Missing $device. Mount system in recovery first." >&2; exit 1; }
mountpoint=/mnt/nabu-adb-system
mkdir -p "$mountpoint"
mounted=0
cleanup() {
    if [ "$mounted" = 1 ]; then
        sync
        mount -o remount,ro "$mountpoint" || true
        umount "$mountpoint" || true
    fi
}
trap cleanup EXIT
mount -t ext4 -o ro "$device" "$mountpoint"
mounted=1
destination=
for path in "$mountpoint/system/etc/init/init.nabu.debug.rc" "$mountpoint/etc/init/init.nabu.debug.rc"; do
    if [ -f "$path" ]; then destination=$path; break; fi
done
[ -n "$destination" ] || { echo 'Debug init file not found in active system.' >&2; exit 1; }
cp "$destination" /tmp/init.nabu.debug.rc.before-adb-fix
mount -o remount,rw "$mountpoint"
# Update the existing inode to preserve its SELinux label and ownership.
if ! cat "$payload" > "$destination"; then
    cat /tmp/init.nabu.debug.rc.before-adb-fix > "$destination" || true
    echo 'Write failed; attempted to restore the original.' >&2
    exit 1
fi
chmod 0644 "$destination"
cmp "$payload" "$destination"
echo "Updated system${slot}; original saved in /tmp/init.nabu.debug.rc.before-adb-fix"
echo 'Reboot into Android, then run adb devices -l.'
