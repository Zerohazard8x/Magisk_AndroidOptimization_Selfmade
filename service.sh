#!/bin/bash

set -e
cd "$(dirname "$0")"

sleep 5
chmod +x *

while true; do
    sleep 5
    
    # Remount necessary partitions
    for mount_point in / /sys /system; do
        mount -o remount,rw,exec,dev "$mount_point"
    done
    
    # Update build.prop settings
    if grep -Eqi "persist.camera.HAL3.enabled" /system/build.prop; then
        sed -i 's/persist.camera.HAL3.enabled=0/persist.camera.HAL3.enabled=1/g' /system/build.prop
    else
        echo "persist.camera.HAL3.enabled=1" >> /system/build.prop
    fi
    
    # grep -Eqi "sys.use_fifo_ui" /system/build.prop; then
    #     sed -i 's/sys.use_fifo_ui=0/sys.use_fifo_ui=1/g' /system/build.prop
    # else
    #     echo "sys.use_fifo_ui=1" >>/system/build.prop
    # fi
    
    if grep -Eqi "wlan.wfd.hdcp" /system/build.prop; then
        sed -i 's/wlan.wfd.hdcp=enable/wlan.wfd.hdcp=disable/g' /system/build.prop
    else
        echo "wlan.wfd.hdcp=disable" >> /system/build.prop
    fi
    
    # Set GPU governor and CPU scaling governor
    echo "performance" > /sys/kernel/gpu/gpu_governor
    for cpu_folder in /sys/devices/system/cpu/cpu*/cpufreq; do
        echo "performance" > "$cpu_folder/scaling_governor"
    done
    
    # Restart ADB
    setprop service.adb.tcp.port 5555
    stop adbd
    start adbd
    
    sleep 50000
done
