#!/bin/sh


grep -q 'iommu=pt' /proc/cmdline ||
	exit

for i in $(find /sys/devices/pci* -name boot_vga); do
	GPU="${i%/*}"
	AUDIO="${GPU%.0}.1"

	grep -q 0 "$i" && {
		echo "vfio-pci" > "$GPU"/driver_override
		test -d "$AUDIO" && echo "vfio-pci" > "$AUDIO"/driver_override
	} || {
		grep -q vfio-pci "$GPU"/driver ||
			continue

		dev=$(echo "$i" | grep -Eo '[0-9]{4}:[0-9]{2}:[0-9]{2}\.[0-9]')

		lspci -s "$dev" |
			grep -Ei 'nvidia|amd' |
			sed 's/amd/amdgpu/' > "$GPU"/driver_override
	}
done

modprobe -i vfio-pci
