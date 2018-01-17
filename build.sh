#! /bin/sh

# Download the specified file.

get () {
	if ! wget -q $1 $2; then
		echo "Unable to fetch '$1'."
		exit 1
	fi
}

# Clone the specified repository.

get () {
	if ! git clone $1 $2 --depth=1; then
		echo "Unable to clone '$1'."
		exit 1
	fi
}

# Build.

# TODO:
# I must add the right URLs for the files.

get http://archive.ubuntu.com/ubuntu/dists/zesty/main/installer-amd64/current/images/netboot/mini.iso

mkdir repos

for repo in $(cat nomad-desktop-files); do
	clone $repo repos/${repo##*/}
done

mkdir mnt
mount mini.iso mnt

