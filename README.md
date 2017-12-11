This document is a short manual about using `mkiso`.

`mkiso` can build a Linux based OS with a little
effort of the user. It aims to keep simple.

The process of generating a bootable image is divided
in three steps:

- Kernel and kernel modules compilation.
- Initial RAM disk generation (this compiles busybox).
- Userspace filesystem construction and compression.

Each step is managed by a script in `steps/`

#### Kernel compilation.

---

`mkiso` will download the kernel as specified in
`steps/config`. This file has documentation inside, so
you know what to do with each setting.
There you can tweak things like kernel version, if
busybox will be downloaded as a precompiled binary or
source files will be downloaded, syslinux version and
how many `make` jobs will be running at build time.

#### Initial RAM disk.

---

The early userspace, also known as initramfs, is the
first thing that gets loaded after the kernel into
RAM. It is usually a file system, or a compressed
file that contains a small collection of programs
neccessary to: initialize the hardware, load firmware,
find where are the user files (root filesystem) and
make them accessible, etc. Later, it starts the `/sbin/init`
program, which is in charge of further (more complex)
initialization (daemon startup, login management, etc.)

#### Userspace.

---

This is the biggest part, but not exactly the worst.
Here, `mkiso` will generate a compressed filesystem
(squashfs) with the contents of `build/rootfs`.
Those contents can be automatically generated or the
directory can be populated manually. The best way to
do this is by adding scripts in `steps/rootfs.d/`.
Those scripts, then, have to be called in a correct
order from `steps/rootfs`.
