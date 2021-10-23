#!/bin/sh

# Take one (or more) snapshot(s) 
# Use: piSnap.sh [-k] [file-annotation]
#      Without -k, one image is capgured.  
#      With -k multiple images are captured.  An image is captured for each [enter], exit with [x] followed by [enter]
# Images land in ~/tmp/pi-images
# Image names are like: YYYYMMDDHHMMSS_COUNT-ANNOTATION.jpg -- Note the _COUNT and/or -ANNOTATION bits may be missing.
#
# TODO: 
#   1 Add some command line  error checking. ;)
#   2 Support PNG & JPEG+RAW

MULTI='N'
ANNOT=''
if [ -n "$1" ]; then
  if [ "$1" = '-k' ]; then
    MULTI='Y'
    ANNOT="$2"
  else
    ANNOT="$1"
  fi
fi
if [ -n "$ANNOT" ]; then
  ANNOT='-'$ANNOT
fi

ODIR=~/tmp/pi-images/
IFMT='jpg'
if [ "$MULTI" = "Y" ]; then
  FILE=$ODIR`date '+%Y%m%d%H%M%S'`'_%d'${ANNOT}'.'$IFMT
  MARG='-t 0 -k'
else
  FILE=$ODIR`date '+%Y%m%d%H%M%S'`${ANNOT}'.'$IFMT
  MARG='-t 1 -n'
fi
raspistill $MARG -q 100 -e $IFMT -o $FILE

TFILE=`echo "$FILE" | sed 's/%d/0/'`
if [ -e "$TFILE" ]; then
  echo "Captured Image File(s):"
  ls -l `echo "$TFILE" | sed 's/_0/_*/'`
else
  echo "ERROR: No image(s) captured!"
fi
