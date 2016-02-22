#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin

busybox cd /
busybox date >>boot.txt
exec >>boot.txt 2>&1
busybox rm /init

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys

# check /cache/recovery/boot
if busybox grep -q warmboot=0x77665502 /proc/cmdline ; then

busybox echo "found reboot into recovery flag"  >>boot.txt

else

# trigger green LED
busybox echo 255 > sys/class/leds/green/brightness
busybox echo 0 > sys/class/leds/red/brightness

# trigger vibration
busybox echo 100 > /sys/class/timed_output/vibrator/enable

# keycheck
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 3

fi
# android ramdisk
load_image=/sbin/ramdisk.cpio

# boot decision
if [ -s /dev/keycheck ] || busybox grep -q warmboot=0x77665502 /proc/cmdline ; then

busybox echo 'RECOVERY BOOT' >>boot.txt

# recovery ramdisk

# default recovery ramdisk is PhilZ 
load_image=/sbin/ramdisk-recovery-philz.cpio

else
	busybox echo 'ANDROID BOOT' >>boot.txt
fi

# poweroff LED
busybox echo 0 > sys/class/leds/green/brightness
busybox echo 0 > sys/class/leds/red/brightness

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

# unpack the ramdisk image
busybox cpio -i < ${load_image}

busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*
busybox date >>boot.txt
export PATH="${_PATH}"
exec /init
