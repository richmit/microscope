#!/bin/bash

TOOL_TO_INSTALL='RPI_tools.ijm'
RUN_IMAGEJ_AFTER_INSTALL='Y'

for pp in ~/winHome/PF/Fiji.app/ ~/Fiji.app/; do
  if [ -z "$IMAGEJ_PATH" -a -e "$pp" ]; then
    IMAGEJ_PATH=$pp
  fi
done

if [ -n "$IMAGEJ_PATH" ]; then
  echo "INFO: ImageJ Path: $IMAGEJ_PATH"
else
  echo "ERROR: ImageJ Path Not Set!"
  exit
fi

if [ ! -d "$IMAGEJ_PATH" ]; then
  echo "ERROR: ImageJ Path Set, but directory not found!"
  exit
fi

TOOLSET_PATH="$IMAGEJ_PATH/macros/toolsets/"
if [ ! -d "$TOOLSET_PATH" ]; then
  echo "ERROR: ImageJ Path Set, but macros/toolsets directory not found!"
  exit
fi

cp "$TOOL_TO_INSTALL" "$TOOLSET_PATH"

if [ -e "$TOOLSET_PATH/$TOOL_TO_INSTALL" ]; then
  if diff -q "$TOOL_TO_INSTALL" "$TOOLSET_PATH/$TOOL_TO_INSTALL"; then
    echo "INFO: $TOOL_TO_INSTALL successfully installed!"
    if [ "$RUN_IMAGEJ_AFTER_INSTALL" = "Y" ]; then
      echo "INFO: Attempting to run ImageJ now"
      for pe in 'ImageJ.sh' 'ImageJ-win64.exe'; do # Note .sh is listed first!!
        if [ -e "$IMAGEJ_PATH/$pe" ]; then
          "$IMAGEJ_PATH/$pe" 
          exit
        fi
      done
    fi
  else
    echo "ERROR: Installed $TOOL_TO_INSTALL file dosen't match newest version!"
    exit
  fi
else
  echo "ERROR: $TOOL_TO_INSTALL not found in install directory after copy!"
  exit
fi


