#!/system/bin/sh
ui_print "=========================================="
ui_print "   Galaxy IPC Namespace Enabler v1.0"
ui_print "        Full Droidspaces Support"
ui_print "=========================================="
ui_print " "
ui_print "Target Device: Samsung Galaxy M32 5G (MT6853)"
ui_print " "
ui_print "[*] Installing IPC Syscall & Namespace Shim..."
ui_print "[*] Installing Patched /proc/config.gz (CONFIG_IPC_NS=y)..."
ui_print "[*] Configuring /dev/shm, /dev/mqueue and Cgroups..."
ui_print "[*] Installing Droidspaces & unshare Wrappers..."
ui_print " "

set_perm_recursive $MODPATH root root 0755 0644
set_perm_recursive $MODPATH/system/bin root shell 0755 0755
set_perm $MODPATH/system/lib64/libipc_ns_shim.so root root 0755
set_perm $MODPATH/service.sh root root 0755
set_perm $MODPATH/post-fs-data.sh root root 0755
set_perm $MODPATH/action.sh root root 0755

ui_print " "
ui_print "✅ Installation successful!"
ui_print "   Run 'su -c ipc_ns_test' in terminal to verify."
ui_print "   Please REBOOT your device to activate."
ui_print "=========================================="
