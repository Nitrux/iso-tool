#!/bin/sh

set -x

for i in $(find /sys/devices/pci* -name boot_vga); do
        GPU=$(dirname $i)
        
        if [ $(cat $i) -eq 0 ]; then
                AUDIO=$(echo $GPU | sed -e "s/0$/1/")
                echo "vfio-pci" > $GPU/driver_override
                if [ -d $AUDIO ]; then
                        echo "vfio-pci" > $AUDIO/driver_override
                fi
        else
                pci_device_id="$(echo "$i"| tr "/" "\n" | tail -n -2 | head -n 1)"
                pci_device_info="$(lspci -s $pci_device_id)"
                
                if echo "$pci_device_info" | grep -qi nvidia; then
                    echo "nvidia" > $GPU/driver_override
                elif echo "$pci_device_info" | grep -qi intel; then
                    echo "i915" > $GPU/driver_override
                elif echo "$pci_device_info" | grep -qi amd; then
                    echo "amdgpu" > $GPU/driver_override
                fi
        fi
done

modprobe -i vfio-pci

exit 0
