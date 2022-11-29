#!/bin/bash
cd $(dirname "$0")

sleep 5
chmod +x *
sleep 5

COUNT_FINAL=999
until [[ $COUNT_FINAL == 0 ]]; do
    sleep 5
    mount -o rw,exec,dev,remount /
    mount -o rw,exec,dev,remount /sys
    mount -o rw,exec,dev,remount /system

    echo -n 0 >/sys/fs/selinux/enforce
    setenforce 0

    swapoff -a

    #################################################################################
    cat /system/build.prop
    RESULT=$?
    if [ $RESULT == 0 ]; then
        if [[ $(cat /system/build.prop | egrep -i persist.camera.HAL3.enabled) != $null ]]; then
            sed -i 's/persist.camera.HAL3.enabled=0/persist.camera.HAL3.enabled=1/g' /system/build.prop
        else
            echo "persist.camera.HAL3.enabled=1" >>/system/build.prop
        fi

        if [[ $(cat /system/build.prop | egrep -i sys.use_fifo_ui) != $null ]]; then
            sed -i 's/sys.use_fifo_ui=0/sys.use_fifo_ui=1/g' /system/build.prop
        else
            echo "sys.use_fifo_ui=1" >>/system/build.prop
        fi

        if [[ $(cat /system/build.prop | egrep -i wlan.wfd.hdcp) != $null ]]; then
            sed -i 's/wlan.wfd.hdcp=enable/wlan.wfd.hdcp=disable/g' /system/build.prop
        else
            echo "wlan.wfd.hdcp=disable" >>/system/build.prop
        fi
    fi

    echo performance >/sys/kernel/gpu/gpu_governor
    #################################################################################
    for cpu_folder in $(find /sys/devices/system/cpu/cpu* -type d -maxdepth 0 | sort); do
        echo ondemand >"$cpu_folder"/cpufreq/scaling_governor
        echo performance >"$cpu_folder"/cpufreq/scaling_governor
    done
    setprop service.adb.tcp.port 5555
    stop adbd
    start adbd
    ((COUNT_FINAL = COUNT_FINAL - 1))
    ((COUNT_FINAL = COUNT_FINAL + 1))
    sleep 50000
done
