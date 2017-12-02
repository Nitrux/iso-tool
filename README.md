This document is a short manual about using `mkiso`.

`mkiso` can build a Linux based OS with a little
effort of the user. It aims to keep simple.

The process of generating a bootable image is divided
in three steps:

- Kernel and kernel modules compilation.
- Initial RAM disk generation (this compiles busybox).
- Userspace filesystem construction and compression.

#### Kernel compilation.

---

`mkiso` will download the kernel as specified in `build/.config`
You will be in charge of setting the kernel version you
want to build, modifying the `KERNEL_VERSION` variable.
It will take care of the rest.

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
(squashfs) with the contents of `build/rootfilesystem`.
Those contents can be automatically generated or the
directory can be populated by hand. **This is left to
the user**.
