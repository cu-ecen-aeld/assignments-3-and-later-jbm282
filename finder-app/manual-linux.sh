#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    make -j 4 HOSTCC='gcc -fcommon' ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
cp linux-stable/arch/$ARCH/boot/Image $OUTDIR
mkdir rootfs
cd rootfs
mkdir bin dev etc home lib proc sbin sys tmp usr var
mkdir usr/bin usr/lib usr/sbin
mkdir -p var/log
ln -s lib lib64
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$OUTDIR/rootfs busybox
sudo make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$OUTDIR/rootfs install
cd $OUTDIR/rootfs
echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cd $OUTDIR
sysroot=$(${CROSS_COMPILE}gcc -print-sysroot)
sudo cp -a $sysroot/lib64/ld-2.31.so $OUTDIR/rootfs/lib
sudo ln -s ld-2.31.so $OUTDIR/rootfs/lib/ld-linux-aarch64.so.1
sudo cp -a $sysroot/lib64/libm.so.6 $OUTDIR/rootfs/lib
sudo cp -a $sysroot/lib64/libm-2.31.so $OUTDIR/rootfs/lib
sudo cp -a $sysroot/lib64/libresolv.so.2 $OUTDIR/rootfs/lib
sudo cp -a $sysroot/lib64/libresolv-2.31.so $OUTDIR/rootfs/lib
sudo cp -a $sysroot/lib64/libc.so.6 $OUTDIR/rootfs/lib
sudo cp -a $sysroot/lib64/libc-2.31.so $OUTDIR/rootfs/lib
# TODO: Make device nodes
cd $OUTDIR/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
# TODO: Clean and build the writer utility
cd $FINDER_APP_DIR
make clean
make CROSS_COMPILE=$CROSS_COMPILE writer
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

#It says the home dir but finder-test.sh assumes conf is in the parent dir?
sudo cp finder.sh $OUTDIR/rootfs/home
sudo cp finder-test.sh $OUTDIR/rootfs/home
sudo cp writer $OUTDIR/rootfs/home
sudo cp writer.sh $OUTDIR/rootfs/home
sudo cp autorun-qemu.sh $OUTDIR/rootfs/home
mkdir $OUTDIR/rootfs/conf #cuz finder-test needs it
sudo ln -s ../conf $OUTDIR/rootfs/home/conf
sudo cp ../conf/username.txt $OUTDIR/rootfs/conf
sudo cp ../conf/assignment.txt $OUTDIR/rootfs/conf
# TODO: Chown the root directory
cd $OUTDIR/rootfs
sudo chown -R root:root *
# TODO: Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip -f initramfs.cpio
#mkimage -A $ARCH -O linux -T ramdisk -d initramfs.cpio.gz uRamdisk
