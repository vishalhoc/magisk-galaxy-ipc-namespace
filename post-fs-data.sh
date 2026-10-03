#!/system/bin/sh
MODDIR=${0%/*}

# 1. Overlay patched /proc/config.gz so apps and diagnostic tools see CONFIG_IPC_NS=y early
if [ -f "$MODDIR/proc_config/config.gz" ] && [ -f /proc/config.gz ]; then
    mount --bind "$MODDIR/proc_config/config.gz" /proc/config.gz 2>/dev/null
fi

# 2. Setup /dev/shm (POSIX shared memory)
mkdir -p /dev/shm 2>/dev/null
mount -t tmpfs -o mode=1777,size=512m tmpfs /dev/shm 2>/dev/null
chmod 1777 /dev/shm 2>/dev/null

# 3. Setup /dev/mqueue (POSIX message queues)
mkdir -p /dev/mqueue 2>/dev/null
mount -t mqueue none /dev/mqueue 2>/dev/null || mount -t tmpfs -o mode=1777 none /dev/mqueue 2>/dev/null
chmod 1777 /dev/mqueue 2>/dev/null

exit 0
