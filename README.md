# mkiso

`mkiso` is a command that generates a minimal linux
OS with customized features.
It creates a ISO image that can be written directly
to a USB stick or hard drive.

Don't run it without reading it. You'll have to
adapt some things to your convenience. I plan to 
separate the configuration and improve the detection
and build system to let more customization and
automation to be done without effort (less wold be a
better word instead).

Some things don't work (there aren't broken, I mean
that they doesn't exist yet). For example, `initramfs/layer`
is suppossed to contain files and directories that
will be added to the initramfs file just after creating
a basic layout for it inside `rootfs` for later
compression. Similar happens with `layer`. A squash
filesystem should be created, added to the ISO file
and mounted by the initramfs during boot.
