#!/bin/bash

# Exit the script if any command fails
set -e

# Change the current directory to the directory of this script
cd "$(dirname "$0")"

# Make all files in the current directory executable
chmod +x *

# Repeat the following commands indefinitely
while true; do
    # Remount necessary partitions with read-write, execute and device permissions
    for mount_point in / /sys /system; do
        mount -o remount,rw,exec,dev "$mount_point"
    done
    
    # Update build.prop settings by replacing values with sed
    sed -i '/persist.camera.HAL3.enabled/s/0/1/; /wlan.wfd.hdcp/s/enable/disable/' /system/build.prop
    
    # Set CPU governor
    for cpu_folder in /sys/devices/system/cpu/cpu*/cpufreq; do
        # If performance or ondemand governor is available, use it
        # regular expression matches either performance or ondemand governor, use ${BASH_REMATCH[0]} to get matched string
        if grep -Eqi "performance|ondemand" "$cpu_folder/scaling_available_governors"; then
            echo "${BASH_REMATCH[0]}" > "$cpu_folder/scaling_governor"
        # If scaling_max_freq and scaling_min_freq are available, use them
        elif cat "$cpu_folder"/cpufreq/scaling_max_freq; then
            # Get the maximum and minimum frequencies from the files
            echohigh=$(cat "$cpu_folder"/cpufreq/scaling_max_freq)
            echolow=$(cat "$cpu_folder"/cpufreq/scaling_min_freq)

            # Set the minimum frequency to the maximum frequency
            echo ${echohigh} >"$cpu_folder"/cpufreq/scaling_min_freq

            # Calculate the difference between the maximum and minimum frequencies
            echosum=$(($echohigh-$echolow))

            # Repeat until the difference is less than or equal to 512
            while [[ $echosum -gt 512 ]]; do
                # Set the maximum frequency to the current maximum minus 8192
                echohigh=$(($echohigh-8192))
                echo ${echohigh} >"$cpu_folder"/cpufreq/scaling_max_freq

                # Set the minimum frequency to the current minimum plus 8192
                echolow=$(($echolow+8192))
                echo ${echolow} >"$cpu_folder"/cpufreq/scaling_min_freq

                # Update the value of echosum 
                echosum=$(($echohigh-$echolow))
            done
        fi
    done
    
    # Restart ADB by setting the port to 5555 and stopping and starting the daemon 
    setprop service.adb.tcp.port 5555 
    stop adbd 
    start adbd 
    
    # Wait for 50000 seconds 
    sleep 50000 
done