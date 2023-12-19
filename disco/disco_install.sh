#!/bin/sh
echo "=== Installing UAVPAL softmod on Disco ==="
echo "Copying softmod files to target directory"
cp -fr /tmp/disco4g/disco/uavpal /data/ftp
echo "Removing softmod kernel modules from previous releases, if any exist"
rm -f /data/ftp/uavpal/mod/*.ko 2>/dev/null
echo "Making binaries and scripts executable"
chmod +x /data/ftp/uavpal/bin/*
echo "Remounting filesystem as read/write"
mount -o remount,rw /
echo "Creating symlink udev rule"
ln -s /data/ftp/uavpal/conf/70-huawei-e3372.rules /lib/udev/rules.d/70-huawei-e3372.rules 2>&1 |grep -v 'File exists'
echo "Remounting filesystem as read-only"
mount -o remount,ro /
echo "Creating openvpn directory"
mkdir -p /data/lib/openvpn
echo "Creating symlink for openvpn local config file"
ln -s /data/ftp/uavpal/conf/openvpn.conf /data/lib/openvpn/openvpn.conf 2>&1 |grep -v 'File exists'
echo "Removing uavpal softmod installation files"
rm -rf /data/ftp/disco4g*
echo "All done! :)"
echo