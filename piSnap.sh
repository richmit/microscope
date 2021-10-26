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
# @todo      Add file-annotation to exif comment field..@EOL
# @filedetails
#
#
################################################################################################################################################################

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
read -r -d '' HELPT <<EOF

Take one (or more) snapshot(s) using the Raspberry Pi HQ Camera and save them off in a standard way

Use: piSnap.sh [options] [file-annotation]
       Options: -k      Capture multiple images.  
                        An image is captured for each [enter], exit with [x] followed by [enter]
                -p      Preview mode -- all other arguments are ignored (not supported yet)
                -v      Verbose mode
                -b BIN  Full path to the raspistill binary
                        Default: /usr/bin/raspistill
                -d DIR  Directory to store captured images.  
                        Default: $HOME/tmp/pi-images
                        Note: The related ImageJ/Fiji macro expects the default value!
                -e ENC  File format: jpg, bmp, gif, png
                        Default: jpg

Image names are like: YYYYMMDDHHMMSS_COUNT-ANNOTATION.ENC -- Note the _COUNT and/or -ANNOTATION bits may be missing.

EOF


#---------------------------------------------------------------------------------------------------------------------------------------------------------------
MULTI='N'
VERB='N'
PREVIEW='N'
ANNOT=''
ODIR="$HOME/tmp/pi-images"
IFMT='jpg'
RASPISP='/usr/bin/raspistill'
while [[ "$1" = -* ]]; do
   case "$1" in
    -k ) MULTI='Y';                                             ;; # Capture multiple images
    -d ) ODIR="$2"; shift;                                      ;; # Output directory
    -v ) VERB='Y';                                              ;; # Verbose mode
    -e ) IFMT="$2"; shift;                                      ;; # Output image format
    -b ) RASPISP="$2"; shift;                                   ;; # Location of raspistill binary
    *  ) echo "ERROR: Unknown option: $1"; echo "$HELPT"; exit; ;;
   esac
   shift;
done
if [ -n "$1" ]; then
  ANNOT="-$1"
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ "$VERB" = 'Y' ]; then                     
  echo "MULTI    $MULTI    "
  echo "VERB     $VERB     " 
  echo "PREVIEW  $PREVIEW  "
  echo "ANNOT    $ANNOT    "
  echo "ODIR     $ODIR     " 
  echo "IFMT     $IFMT     "
fi    

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ -n "$2" ]; then
  echo "ERROR: Arguments ignored: $@"
  exit
fi

if [[ ! "$IFMT" =~ ^(jpg|bmp|gif|png)$ ]]; then
  echo "ERROR: Encodeing of '$IFMT' is not supported.  Use one of jpg, bmp, gif, or png!"
  exit
fi

if [ ! -x "$RASPISP" ]; then
  echo "ERROR: $RASPISP not found!"
  exit
fi

if [ ! -d "$ODIR" ]; then
  echo "ERROR: Output directory not found: $ODIR"
  exit
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ "$MULTI" = "Y" ]; then
  FILE=$ODIR'/'`date '+%Y%m%d%H%M%S'`'_%d'${ANNOT}'.'$IFMT
  MARG='-t 0 -k'
else
  FILE=$ODIR'/'`date '+%Y%m%d%H%M%S'`${ANNOT}'.'$IFMT
  MARG='-t 1 -n'
fi
DACMD="$RASPISP $MARG -q 100 -e $IFMT -o $FILE"
if [ "$VERB" = 'Y' ]; then                     
  echo "DEBUG: Command to run: DACMD"
fi
$DACMD

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
TFILE=`echo "$FILE" | sed 's/%d/0/'`
if [ -e "$TFILE" ]; then
  echo "Captured Image File(s):"
  ls -l `echo "$TFILE" | sed 's/_0/_*/'`
else
  echo "ERROR: No image(s) captured!"
fi
