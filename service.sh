#!/system/bin/sh
MODDIR=${0%/*}
LOG=/data/local/tmp/galaxy_ipc_namespace.log

echo "[$(date)] Galaxy IPC Namespace Service starting" > "$LOG"

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done
sleep 3

# 1. Ensure /proc/config.gz bind mount
if [ -f "$MODDIR/proc_config/config.gz" ] && [ -f /proc/config.gz ]; then
    mount --bind "$MODDIR/proc_config/config.gz" /proc/config.gz 2>>"$LOG"
    echo "[*] Mounted patched /proc/config.gz (CONFIG_IPC_NS=y)" >> "$LOG"
fi

# 2. Ensure /dev/shm (POSIX shared memory)
if ! mount | grep -q " /dev/shm "; then
    mkdir -p /dev/shm
    mount -t tmpfs -o mode=1777,size=512m tmpfs /dev/shm 2>>"$LOG"
    chmod 1777 /dev/shm
    echo "[*] Mounted /dev/shm (512MB tmpfs)" >> "$LOG"
fi

# 3. Ensure /dev/mqueue (POSIX message queues)
if ! mount | grep -q " /dev/mqueue "; then
    mkdir -p /dev/mqueue
    mount -t mqueue none /dev/mqueue 2>>"$LOG" || mount -t tmpfs -o mode=1777 none /dev/mqueue 2>>"$LOG"
    chmod 1777 /dev/mqueue
    echo "[*] Mounted /dev/mqueue" >> "$LOG"
fi

# 4. Ensure cgroup controllers for Droidspaces / Linux containers
if [ ! -d /sys/fs/cgroup/devices ]; then
    mkdir -p /sys/fs/cgroup/devices 2>/dev/null
    mount -t cgroup -o devices none /sys/fs/cgroup/devices 2>>"$LOG"
fi
if [ ! -d /sys/fs/cgroup/freezer ]; then
    mkdir -p /sys/fs/cgroup/freezer 2>/dev/null
    mount -t cgroup -o freezer none /sys/fs/cgroup/freezer 2>>"$LOG"
fi

# 5. Enable kernel network packet forwarding for container networking
echo 1 > /proc/sys/net/ipv4/ip_forward 2>>"$LOG"
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding 2>>"$LOG"

# 6. Increase inotify limits for containers
echo 1048576 > /proc/sys/fs/inotify/max_user_watches 2>/dev/null
echo 1024 > /proc/sys/fs/inotify/max_user_instances 2>/dev/null

echo "[$(date)] Galaxy IPC Namespace Service initialized successfully" >> "$LOG"
