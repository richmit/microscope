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
       Options: -p      Preview only.  No images are captured. All other arguments are ignored
                -k      Show a preview, and capture when [enter] is pressed.  
                        Without the -k option an image is immediatly captured with no preview
                -s      Show image after capture with nomacs (my favorite lightweight image viewer)
                -v      Verbose mode
                -b BIN  Full path to the libcamera-still binary
                        Default: /usr/bin/libcamera-still
                -d DIR  Directory to store captured images.  
                        Default: $HOME/Pictures/pi-cam
                        Note: The related ImageJ/Fiji macro expects the default value!
                -e ENC  File format: jpg, bmp, gif, png, rgb
                        Default: jpg
       Annotation
           The file-annotation argument is translated automatically into something suitable for a 
           file name.  White space and non-printable characters are converted to underscores.  
           Multiple underscores are reduced to a single underscore.
       File Names
           Image names are like: YYYYMMDDHHMMSS-ANNOTATION.ENC

EOF

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
FAKE_CAP='Y'
SHOW='N'
WKEY='N'
VERB='N'
PREVIEW='N'
ANNOT=''
OANNOT=''
ODIR="$HOME/Pictures/pi-cam"
IENC='jpg'
RASPISP='/usr/bin/libcamera-still'
while [[ "$1" = -* ]]; do
   case "$1" in
    -k ) WKEY='Y';                                             ;; # Capture multiple images
    -d ) ODIR="$2"; shift;                                      ;; # Output directory
    -v ) VERB='Y';                                              ;; # Verbose mode
    -e ) IENC="$2"; shift;                                      ;; # Output image format
    -s ) SHOW='Y';                                              ;; # Open captured images
    -p ) PREVIEW='Y';                                           ;; # Preview only
    -b ) RASPISP="$2"; shift;                                   ;; # Location of libcamera-still binary
    *  ) echo "ERROR: Unknown option: $1"; echo "$HELPT"; exit; ;;
   esac
   shift;
done
if [ -n "$1" ]; then
  OANNOT="$1"
  ANNOT="-"`echo -n "$OANNOT" | tr -sc '[[:graph:]]' '_'`
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ "$VERB" = 'Y' ]; then                     
  echo "DEBUG: WKEY     $WKEY     "
  echo "DEBUG: VERB     $VERB     " 
  echo "DEBUG: PREVIEW  $PREVIEW  "
  echo "DEBUG: ANNOT    $ANNOT    "
  echo "DEBUG: OANNOT   $OANNOT   "
  echo "DEBUG: ODIR     $ODIR     " 
  echo "DEBUG: IENC     $IENC     "
fi    

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ -n "$2" ]; then
  echo "ERROR: Arguments ignored: $@"
  echo "$HELPT"
  exit
fi

if [[ ! "$IENC" =~ ^(jpg|bmp|gif|png|rgb)$ ]]; then
  echo "ERROR: Encodeing of '$IENC' is not supported!"
  echo "$HELPT"
  exit
fi

if [ ! -x "$RASPISP" ]; then
  if [ "$FAKE_CAP" = 'Y' ]; then
    if [ "$VERB" = 'Y' ]; then                     
      echo "DEBUG: In FAKE_CAP mode. Didn't find $RASPISP"
    fi
  else
    echo "ERROR: $RASPISP not found!"
    echo "$HELPT"
    exit
  fi
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
DACMD="$RASPISP"
OFILE=''
if [ "$IENC" = "raw" ]; then
  DACMD="$DACMD -r"
  IENC='jpg'
fi

if [ "$PREVIEW" = 'Y' ]; then
  DACMD="$DACMD -t 0"
else
  if [ "$WKEY" = "Y" ]; then
    DACMD="$DACMD -t 0 -k"
  else
    DACMD="$DACMD -t 1 -n"
  fi
  if [ "$IENC" = "jpg" ]; then
    DACMD="$DACMD -q 100"
  fi
  OFILE=$ODIR'/'`date '+%Y%m%d%H%M%S'`${ANNOT}'.'$IENC
  DACMD="$DACMD -e $IENC -o $OFILE"
fi
if [ "$VERB" = 'Y' ]; then                     
  echo "DEBUG: Command to run: $DACMD"
fi
if [ "$FAKE_CAP" = 'Y' ]; then
  if [ "$PREVIEW" = 'Y' ]; then
    DACMD='true'
  else
    DACMD="convert -size 1024x1024 xc:white $OFILE"
  fi
  if [ "$VERB" = 'Y' ]; then                     
    echo "DEBUG: In FAKE_CAP mode. New command to run: $DACMD"
  fi
fi
$DACMD

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ -n "$OFILE" -a -e "$OFILE" ]; then
  echo "INFO: Captured Image File:"
  ls -l "$OFILE" | sed 's/^/    /'
  if [ "$SHOW" = 'Y' ]; then
    if [ -x '/usr/bin/nomacs' ]; then
      /usr/bin/nomacs "$OFILE"
    else
      echo 'ERROR: Unable to open image (/usr/bin/nomacs) not found.'
    fi
  fi
else
  echo "ERROR: No image captured!"
fi
