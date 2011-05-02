#!/usr/bin/env bash

USAGE="Usage: ./install </your/preferred/backfire/installation/path>"

if (( $# < 1 ))
then
	echo "Error. Not enough arguments."
	echo $USAGE
	exit 1
elif (( $# > 1 ))
then
	echo "Error. Too many arguments."
	echo $USAGE
	exit 2
elif [ $1 == "--help" ]
then
	echo $USAGE
	exit 3
fi

REPO_PATH=$(pwd)
BACKFIRE_PATH=$1

# checkout the stock OpenWRT build environment to the path specified on the command line
mkdir -p $BACKFIRE_PATH
svn co svn://svn.openwrt.org/openwrt/branches/backfire $BACKFIRE_PATH

# add the specific flukso packages as a feed
echo "src-link flukso $REPO_PATH/package" > $BACKFIRE_PATH/feeds.conf
$BACKFIRE_PATH/scripts/feeds update
$BACKFIRE_PATH/scripts/feeds install -a -p flukso

# copy over the build config settings and the files directory
cp .config $BACKFIRE_PATH
cp -r files $BACKFIRE_PATH

# add patches to the toolchain
cp patches/990-add_timerfd_support.patch $BACKFIRE_PATH/toolchain/uClibc/patches-0.9.30.1

# add patches to the linux atheros target
cp patches/300-set_AR2315_RESET_GPIO_to_6.patch $BACKFIRE_PATH/target/linux/atheros/patches-2.6.30
cp patches/310-hotplug_button_jiffies_calc.patch $BACKFIRE_PATH/target/linux/atheros/patches-2.6.30
cp patches/400-spi_gpio_support.patch $BACKFIRE_PATH/target/linux/atheros/patches-2.6.30
cp patches/410-spi_gpio_enable_cs_line.patch $BACKFIRE_PATH/target/linux/atheros/patches-2.6.30
cp patches/420-tune_spi_bitbanging_for_avr.patch $BACKFIRE_PATH/target/linux/atheros/patches-2.6.30

# backport loglevel fix to busybox v1.15.3-2
# see: https://bugs.busybox.net/show_bug.cgi?id=681
cp patches/920-fix_crond_loglevel.patch $BACKFIRE_PATH/package/busybox/patches

# patch the default OpenWRT Lua package
rm $BACKFIRE_PATH/package/lua/patches/400-luaposix_5.1.4-embedded.patch
rm $BACKFIRE_PATH/package/lua/patches/500-eglibc_config.patch
cp patches/600-lua-tablecreate.patch $BACKFIRE_PATH/package/lua/patches

# patch files of the OpenWRT build system
cd $BACKFIRE_PATH
patch -p0 < $REPO_PATH/patches/900-disable_console.patch
patch -p0 < $REPO_PATH/patches/910-set_ttyS0_baud_to_115200.patch

# we don't need rdate, relying on ntpclient instead
rm $BACKFIRE_PATH/package/base-files/files/etc/hotplug.d/iface/40-rdate

# and then build the Fluksometer firmware...
echo 
echo " ============================================================================ "
echo " To compile this custom Backfire build for Flukso, just type: make -j8 in the "
echo " installation path you selected. Use at least as many jobs as the number of   "
echo " cores available on your build machine.                                       "
echo
echo " IMPORTANT: make sure your machine has a recent version (>= v4.3.4) of the    "
echo " avr-gcc toolchain installed                                                  "
echo " ============================================================================ "
echo 
