#!/bin/bash

###############
### Get arguments
###############

# Defaults
SHOW_HELP=TRUE
DO_CLEAN=FALSE
DO_KERNEL=FALSE
DO_BOOTIMG=FALSE

POSITIONAL=()
while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
		-c)
		DO_CLEAN=TRUE
		SHOW_HELP=FALSE
		shift
		;;
		-k)
		DO_KERNEL=TRUE
		SHOW_HELP=FALSE
		shift
		;;
		-b)
		DO_BOOTIMG=TRUE
		SHOW_HELP=FALSE
		shift
		;;
		-r)
		DO_CLEAN=TRUE
		DO_KERNEL=TRUE
		DO_BOOTIMG=TRUE
		SHOW_HELP=FALSE
		shift
		;;
		*)    # unknown option
		POSITIONAL+=("$1") # add it to an array for later
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
# $@ can contain jobs

if [ "${SHOW_HELP}" == "TRUE" ]; then
	echo "-c"
	echo "	Clean everything"
	echo "-k"
	echo "	Build Poco kernel image"
	echo "-b"
	echo "	Build boot image from kernel and ramdisk (does NOT imply -k)."
	echo "-r"
	echo "	Release build (implies all of the above)"
	echo ""
	echo "	Can provide any/all arguments, e.g. ./build.sh -k -b"
	exit 0
fi

if [ "${DO_CLEAN}" == "TRUE" ]; then
	echo ""
	echo "---------------------------------------"
	echo "[#] Removing ./out/ ..."
	echo "---------------------------------------"
	rm -rf ./out
	echo ""
	echo "[i] Clean done."
	echo ""
fi

if [ "${DO_KERNEL}" == "TRUE" ]; then
	echo ""
	echo "---------------------------------------"
	echo "[#] Starting kernel image build ..."
	echo "---------------------------------------"
	rm $(pwd)/out/arch/arm64/boot/Image.gz-dtb
	export ARCH=arm64
	export CROSS_COMPILE=$(pwd)/toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-
	make O=out beryllium_cosmicdan_defconfig
	make O=out -j4
	echo ""
	if [ -f "$(pwd)/out/arch/arm64/boot/Image.gz-dtb" ]; then
		echo "[i] Kernel image done."
	else
		echo "[!] Kernel image failed."
	fi
	echo ""
fi

if [ "${DO_BOOTIMG}" == "TRUE" ]; then
	echo ""
	echo "---------------------------------------"
	echo "[#] Starting boot.img build ..."
	echo "---------------------------------------"
	echo ""
	# cleanup old files, if any
	rm -f "$(pwd)/ramdisk/ramdisk-new.cpio.gz"
	rm -f "$(pwd)/ramdisk/unsigned-new.img"
	rm -f "$(pwd)/ramdisk/image-new.img"
	rm -f "$(pwd)/ramdisk/boot.img"
	if [ ! -f "$(pwd)/out/arch/arm64/boot/Image.gz-dtb" ]; then
		echo "[!] No kernel image has been built yet!"
		exit -1
	fi
	cp -r "$(pwd)/out/arch/arm64/boot/Image.gz-dtb" "$(pwd)/ramdisk/split_img/boot.img-zImage"
	"$(pwd)/ramdisk/repackimg.sh" > "$(pwd)/ramdisk/repackimg.log"
	# cleanup intermediates
	rm -f "$(pwd)/ramdisk/unsigned-new.img"
	rm -f "$(pwd)/ramdisk/ramdisk-new.cpio.gz"
	if [ -f "$(pwd)/ramdisk/image-new.img" ]; then
		mv "$(pwd)/ramdisk/image-new.img" "$(pwd)/ramdisk/boot.img"
		echo "[i] Boot.img image done."
	else
		echo "[!] Boot.img image failed."
	fi
	echo ""
fi

