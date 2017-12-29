#!/bin/sh

# see also update-pciids.sh (fancier)

[ "$1" = "-q" ] && quiet="true" || quiet="false"

set -e
SRC="http://www.linux-usb.org/usb.ids"
DEST=usb.ids.gz

# if usb.ids.gz is read-only (because the filesystem is read-only),
# then just skip this whole process.
if ! touch ${DEST} >&2 >/dev/null ; then
	${quiet} || echo "${DEST} is read-only, exiting."
	exit 0
fi

if which wget >/dev/null 2>&1 ; then
	DL="eval wget -O- $SRC | gzip >$DEST.new"
	${quiet} && DL="$DL -q"
elif which lynx >/dev/null 2>&1 ; then
	DL="eval lynx -source $SRC | gzip >$DEST.new"
else
	echo >&2 "update-usbids: cannot find wget nor lynx"
	exit 1
fi

if ! $DL ; then
	echo >&2 "update-usbids: download failed"
	rm -f $DEST.new
	exit 1
fi

if ! zcat $DEST.new | grep >/dev/null "^C " ; then
	echo >&2 "update-usbids: missing class info, probably truncated file"
	exit 1
fi

if [ -f $DEST ] ; then
	mv $DEST $DEST.old
	# --reference is supported only by chmod from GNU file, so let's ignore any errors
	chmod -f --reference=$DEST.old $DEST.new 2>/dev/null || true
fi
mv $DEST.new $DEST

${quiet} || echo "Done."
