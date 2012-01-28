# unpack boot.img
cd out/ramdisk

# pack ramdisk
find . | cpio -o -H newc | gzip > ../ramdisk.img
cd ..
# pack boot.img
mkbootimg --kernel boot.img-zImage --ramdisk ramdisk.img --base $(cat boot.img-base) --pagesize $(cat boot.img-pagesize) -o ../newboot.img
