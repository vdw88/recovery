```bash
nano wipe_out_disk.sh
```


```bash
#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: sudo $0 /dev/sdX"
  exit 1
fi

DEVICE="$1"
LABEL="intel_180GB"
MOUNTPOINT="/mnt/intel180gb"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root."
  exit 1
fi

if [[ ! -b "$DEVICE" ]]; then
  echo "Invalid device: $DEVICE"
  exit 1
fi

ROOTDISK=$(lsblk -no PKNAME "$(findmnt / -o SOURCE -n)")
if [[ "$DEVICE" == "/dev/$ROOTDISK" ]]; then
  echo "ABORT: $DEVICE is system disk!"
  exit 1
fi

echo "🚀 ULTRA SECURE WIPE on $DEVICE starting..."
sleep 2

umount ${DEVICE}* 2>/dev/null || true

echo "🧨 Phase A: full random overwrite..."
dd if=/dev/urandom of="$DEVICE" bs=16M status=progress || true
sync

echo "🔐 Phase B: cryptographic destruction..."
printf "YES" | cryptsetup luksFormat "$DEVICE" --batch-mode
printf "YES" | cryptsetup luksErase "$DEVICE"

echo "🧱 Phase C: rebuilding disk..."

wipefs -a "$DEVICE"
sgdisk --zap-all "$DEVICE"

parted "$DEVICE" --script mklabel gpt
parted "$DEVICE" --script mkpart primary 1MiB 100%
parted "$DEVICE" --script set 1 msftdata on

mkfs.exfat -n "$LABEL" "${DEVICE}1"
partprobe "$DEVICE"

mkdir -p "$MOUNTPOINT"

UUID=$(blkid -s UUID -o value "${DEVICE}1")

grep -q "$UUID" /etc/fstab || \
echo "UUID=$UUID $MOUNTPOINT exfat defaults,nofail,uid=1000,gid=1000 0 0" >> /etc/fstab

systemctl daemon-reexec
mount -a

df -h | grep "$MOUNTPOINT"

echo ""
echo "🔥 SSD COMPLETELY DESTROYED AND REBUILT"
echo "✔️ Forensic recovery: practically impossible"
echo "✔️ Ready for Linux & Windows"

```

```bash
chmod +x wipe_out_disk.sh
```

```bash
./wipe_out_disk.sh
```
