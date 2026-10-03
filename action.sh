#!/system/bin/sh
# Magisk Action Button Trigger: Run IPC namespace test
if [ -x /system/bin/ipc_ns_test ]; then
    /system/bin/ipc_ns_test
elif [ -x "$MODDIR/system/bin/ipc_ns_test" ]; then
    "$MODDIR/system/bin/ipc_ns_test"
else
    echo "Galaxy IPC Namespace Enabler is Active!"
fi
