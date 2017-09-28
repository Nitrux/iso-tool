#! /bin/sh


# - - - LETS KNOW THE BUILD DIRECTIVES.

source .config || { err ".config file not found."; exit 1; }



# - - - "IMPORT" THE FUNCTIONS LIBRARY.

source lib.sh || { err "no library found. Nothing to do."}



# - - - OK, EVERYTHING READY TO START.

for command in $@; do
    case "$command" in

        "make_dir_layout") ;;
        "get_sources") ;;
        "make_kernel") ;;
        "make_busybox") ;;
        "make_syslinux") ;;
        "make_initramfs") ;;
        "make_iso") ;;
    esac
done
