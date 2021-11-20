#!/bin/bash
# -*- Mode:Shell-script; Coding:us-ascii-unix; fill-column:158 -*-
################################################################################################################################################################
##
# @file      piSnap.sh
# @author    Mitch Richling https://www.mitchr.me
# @brief     @EOL
# @keywords  raspberry pi hq camera image capture
# @std       bash
# @copyright 
#  @parblock
#  Copyright (c) 2021, Mitchell Jay Richling <https://www.mitchr.me> All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without
#     specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
#  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#  @endparblock
################################################################################################################################################################

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
read -r -d '' HELPT <<EOF

Take one (or more) snapshot(s) using the Raspberry Pi HQ Camera and save them off in a standard way

Use: piSnap.sh [options] [file-annotation]
       Options: -k      Show a preview, and capture on keypress.
                        An image is captured for [enter], exit with [x] followed by [enter]
                -f      Printf format for numeric index in filenames created with -k option
                        Default: %02d
                -p      Preview only.  No images are captured. All other arguments are ignored
                -s      Show image(s) after capture with nomacs (my favorite lightweight image viewer)
                -v      Verbose mode
                -b BIN  Full path to the libcamera-still binary
                        Default: /usr/bin/libcamera-still
                -d DIR  Directory to store captured images.  
                        Default: $HOME/Pictures/pi-cam
                        Note: The related ImageJ/Fiji macro expects the default value!
                -e ENC  File format: jpg, bmp, gif, png
                        Default: jpg

Image names are like: YYYYMMDDHHMMSS_COUNT-ANNOTATION.ENC -- Note the _COUNT and/or -ANNOTATION bits may be missing.

Note: Older versions of the image capture tool would capture multiple images with -k option.  The current versions don't 
      work like this.  I'm waiting to see if this functionality comes back.  If it looks like single capture is the 
      future, then I'll rework this code a bit.

EOF

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
SHOW='N'
PFMT='%02d'
MULTI='N'
VERB='N'
PREVIEW='N'
ANNOT=''
ODIR="$HOME/Pictures/pi-cam"
IFMT='jpg'
RASPISP='/usr/bin/libcamera-still'
while [[ "$1" = -* ]]; do
   case "$1" in
    -k ) MULTI='Y';                                             ;; # Capture multiple images
    -d ) ODIR="$2"; shift;                                      ;; # Output directory
    -v ) VERB='Y';                                              ;; # Verbose mode
    -e ) IFMT="$2"; shift;                                      ;; # Output image format
    -s ) SHOW='Y';                                              ;; # Open captured images
    -p ) PREVIEW='Y';                                           ;; # Preview only
    -b ) RASPISP="$2"; shift;                                   ;; # Location of libcamera-still binary
    *  ) echo "ERROR: Unknown option: $1"; echo "$HELPT"; exit; ;;
   esac
   shift;
done
if [ -n "$1" ]; then
  ANNOT="-$1"
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ "$VERB" = 'Y' ]; then                     
  echo "DEBUG: MULTI    $MULTI    "
  echo "DEBUG: VERB     $VERB     " 
  echo "DEBUG: PREVIEW  $PREVIEW  "
  echo "DEBUG: ANNOT    $ANNOT    "
  echo "DEBUG: ODIR     $ODIR     " 
  echo "DEBUG: IFMT     $IFMT     "
fi    

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ -n "$2" ]; then
  echo "ERROR: Arguments ignored: $@"
  echo "$HELPT"
  exit
fi

if [[ ! "$IFMT" =~ ^(jpg|bmp|gif|png)$ ]]; then
  echo "ERROR: Encodeing of '$IFMT' is not supported!"
  echo "$HELPT"
  exit
fi

if [ ! -x "$RASPISP" ]; then
  echo "ERROR: $RASPISP not found!"
  echo "$HELPT"
  exit
fi

if [ ! -d "$ODIR" ]; then
  mkdir "$ODIR"
  if [ -d "$ODIR" ]; then
    echo "WARNING: Output directory was created: $ODIR"
  else
    echo "ERROR: Output directory not found/created: $ODIR"
    echo "$HELPT"
    exit
  fi
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ "$PREVIEW" = 'Y' ]; then
  DACMD="$RASPISP -t 0"
else
  if [ "$MULTI" = "Y" ]; then
    FILE=$ODIR'/'`date '+%Y%m%d%H%M%S'`'_'${PFMT}${ANNOT}'.'$IFMT
    MARG='-t 0 -k'
  else
    FILE=$ODIR'/'`date '+%Y%m%d%H%M%S'`${ANNOT}'.'$IFMT
    MARG='-t 1 -n'
  fi
  DACMD="$RASPISP $MARG -q 100 -e $IFMT -o $FILE"
fi
if [ "$VERB" = 'Y' ]; then                     
  echo "DEBUG: Command to run: $DACMD"
fi
$DACMD

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
TFILE=`printf "$FILE" 0`
if [ -e "$TFILE" ]; then
  echo "INFO: Captured Image File(s):"
  ls -l `echo "$TFILE" | sed 's/_00*/_*/'`
  if [ "$SHOW" = 'Y' ]; then
    if [ -x '/usr/bin/nomacs' ]; then
      /usr/bin/nomacs `echo "$TFILE" | sed 's/_0/_*/'`
    else
      echo 'ERROR: Unable to open images (/usr/bin/nomacs) not found.'
    fi
  fi
else
  echo "ERROR: No image(s) captured!"
fi
