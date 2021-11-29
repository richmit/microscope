////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var gbl_ALL_debug     = false;                    // RPI-CODE
var gbl_ALL_doScl     = true;                     // RPI-CODE
var gbl_lil_group     = "";                       // RPI-CODE
var gbl_lil_which     = "Last";                   // RPI-CODE
var gbl_pic_anno      = "";                       // RPI-CODE
var gbl_pic_doSet     = true;                     // RPI-CODE
var gbl_pic_group     = "";                       // RPI-CODE
var gbl_pic_ifmt      = "jpg";                    // RPI-CODE
var gbl_pic_ipad      = 3;                        // RPI-CODE
var gbl_pic_loadem    = true;                     // RPI-CODE
var gbl_pic_pviewDo   = true;                     // RPI-CODE
var gbl_pic_pviewScl  = 4;                        // RPI-CODE
var gbl_pic_repeat    = false;                    // RPI-CODE
var gbl_pic_res       = "100%";                   // RPI-CODE
var gbl_pic_useCam    = true;                     // RPI-CODE
var gbl_ssm_aux       = "0.63";                   // RPI-CODE
var gbl_ssm_cam       = "RPI";                    // RPI-CODE
var gbl_ssm_gbl       = false;                    // RPI-CODE
var gbl_ssm_res       = false;                    // RPI-CODE
var gbl_ssm_scope     = "Leica S8API";            // RPI-CODE
var gbl_ssm_vobj      = "0.32";                   // RPI-CODE
var gbl_ssm_zoom      = "1.00";                   // RPI-CODE

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

macro "Capture From RPI Camera Action Tool - Cc11 F06fa F16fa F4472 F6333 Ld2e3 Le0e3 Lf2e3 Cfff V5866" {
  captureImageFromRPI();
}

macro "Setup RPI Camera Action Tool - Cc11 F06fa F16fa F4472 F6333 C000 T5f14s" {
  configureRPI();
}

macro "Set Scale Action Tool - Cc11 L1cfc L1a1e Lfafe L8b8d L5b5d Lbbbd T4707R T9707P Te707I" {
  setScaleForMicrograph(false);
}

macro "Open Previous RPI Capture(s) Action Tool - Cc11 L000f L0fff Lfff3 Lf363 L6340 L4000 T3c07R T8c07P Tdc07I" {
  getCaptureRPI();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Capture an image.  See piSnap.sh filename conventions.
// RPI-CODE
function configureRPI() {
  do {
    needMoreData = false;
    Dialog.create("Configure RPI Capture Settings");
    Dialog.addString("File group name:",                                   gbl_pic_group, 5);
    Dialog.addString("File annotation:",                                   gbl_pic_anno,  15);
    Dialog.addChoice("Image Format:", newArray("jpg", "png"),              gbl_pic_ifmt);
    Dialog.addChoice("Image Size:", newArray("100%", "50%"),               gbl_pic_res);
    Dialog.addChoice("Preview Scale (1/n):", newArray("1", "2", "4", "8"), gbl_pic_pviewScl);
    Dialog.addCheckbox("Change settings before capture",                   gbl_pic_doSet);
    Dialog.addCheckbox("Repeated capture mode",                            gbl_pic_repeat);
    Dialog.addCheckbox("Video preview before capture",                     gbl_pic_pviewDo);
    Dialog.addCheckbox("Load image after capture",                         gbl_pic_loadem);
    Dialog.addCheckbox("Set scale after capture/load",                     gbl_ALL_doScl);
    Dialog.addCheckbox("Debuging",                                         gbl_ALL_debug);

    Dialog.show();
    gbl_pic_group    = Dialog.getString();
    gbl_pic_anno     = Dialog.getString();
    gbl_pic_ifmt     = Dialog.getChoice();
    gbl_pic_res      = Dialog.getChoice();
    gbl_pic_pviewScl = Dialog.getChoice();
    gbl_pic_doSet    = Dialog.getCheckbox();
    gbl_pic_repeat   = Dialog.getCheckbox();
    gbl_pic_pviewDo  = Dialog.getCheckbox();
    gbl_pic_loadem   = Dialog.getCheckbox();
    gbl_ALL_doScl    = Dialog.getCheckbox();
    gbl_ALL_debug    = Dialog.getCheckbox();
    if ( (lengthOf(gbl_pic_group)>0) && !(matches(gbl_pic_group, "(^\\p{Alnum}+$)"))) {
      showMessage("ERROR(configureRPI)", "Group name must contain only alphanumeric characters!");
      needMoreData = true;
    }
    if ( (lengthOf(gbl_pic_anno)>0) && !(matches(gbl_pic_anno, "(^\\p{Alnum}+$)"))) {
      showMessage("ERROR(configureRPI)", "Annotation name must contain only alphanumeric characters!");
      needMoreData = true;
    }
  } while (needMoreData);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Capture an image.  See piSnap.sh filename conventions.
// RPI-CODE
function captureImageFromRPI() {
  needOne = true;
  while (needOne || gbl_pic_repeat) {
    needOne = false;
    // Make sure we have libcamera-still installed -- if we don't, then we are probably
    // not running on a RPI..
    if (gbl_pic_useCam)
      if (!(File.exists("/usr/bin/libcamera-still")))
        exit("ERROR(captureImageFromRPI): Could not find /usr/bin/libcamera-still!");

    // Make sure we can find the user home directory
    piImagePath = getDirectory("home");
    if (!(File.exists(piImagePath)))
      exit("ERROR(captureImageFromRPI): Could not find home directory!");

    // Look for ~/Pictures.  Try to create it if it is missing.
    piImagePath = String.join(newArray(piImagePath, "Pictures"), File.separator);
    if (!(File.exists(piImagePath))) {
      if (gbl_ALL_debug)
        print("DEBUG(captureImageFromRPI): Attempting to create directory: " + piImagePath);
      File.makeDirectory(piImagePath);
      if (!(File.exists(piImagePath))) {
        exit("ERROR(captureImageFromRPI): Directory creation failed: " + piImagePath);
      }
    }

    // Look for ~/Pictures/pi-cam.  Try to create it if it is missing.
    piImagePath = String.join(newArray(piImagePath, "pi-cam"), File.separator);
    if (!(File.exists(piImagePath))) {
      if (gbl_ALL_debug)
        print("DEBUG(captureImageFromRPI): Attempting to create directory: " + piImagePath);
      File.makeDirectory(piImagePath);
      if (!(File.exists(piImagePath))) {
        exit("ERROR(captureImageFromRPI): Directory creation failed: " + piImagePath);
      }
    }

    // Check again that piImagePath really exists...
    if (!(File.exists(piImagePath))) {
      exit("ERROR(captureImageFromRPI): Could not find/create image directory: " + piImagePath);
    }

    // Ask for camera settings
    if (gbl_pic_doSet)
      configureRPI();

    // Construct filename: timestamp
    piImageFileName = makeDateString();
    // Construct filename: group
    if (gbl_pic_group != "")
      piImageFileName = piImageFileName + "_" + gbl_pic_group;   
    // Construct filename: anno
    if (lengthOf(gbl_pic_anno)>0)
      piImageFileName = piImageFileName + "-" + gbl_pic_anno;
    // Construct filename: ext
    piImageFileName = piImageFileName + "." + gbl_pic_ifmt;

    // Construct full file name path
    piImageFullFileName = String.join(newArray(piImagePath, piImageFileName), File.separator);
    if (gbl_ALL_debug)
      print("DEBUG(captureImageFromRPI): Image file: " + piImageFullFileName);

    resOpt = "";
    if (gbl_pic_res == "50%")
      resOpt = "--width 2028 --height 1520";

    // Run libcamera-still
    if (gbl_pic_useCam) {
      if (gbl_pic_pviewDo) {
        procList = exec("/bin/bash", "-c", "ps -eo cmd | grep '^ *libcamera-still'");
        if (lengthOf(procList) > 10)
          exit("ERROR(captureImageFromRPI): libcamera-still is already running.  Close it first");

        psv = parseInt(gbl_pic_pviewScl);
        pww = round(4056/psv);
        pwh = round(3040/psv);

        pid = exec("/bin/bash", "-c", "libcamera-still -t 0" + " -p 0,0," + pww + "," + pwh + " -s " + resOpt + " -e " + gbl_pic_ifmt + " -o '" + piImageFullFileName + "' >/dev/null 2>&1 & echo $!", "&");

        pid = String.trim(pid);

        if ( !(matches(pid, "(^[0-9][0-9]*$)")))
          exit("ERROR(captureImageFromRPI): Can't get PID of libcamera-still process -- it may not have started!");

        showMessage("RPI Capture", "Click OK to Capture Image");

        procList = exec("/bin/bash", "-c", "ps -eo pid,cmd | grep '^ *" + pid + "  *libcamera-still'");
        if (lengthOf(procList) < 10)
          exit("ERROR(captureImageFromRPI): Unable to trigger capture (Can't find libcamera-still process)!");
        showStatus("Waiting for capture process");
        exec("/bin/bash", "-c", "kill -SIGUSR1 " + pid);
        c=1;
        do {
          showProgress(c, 30);
          wait(40);
          procList = exec("/bin/bash", "-c", "ps -eo pid,cmd | grep '^ *" + pid + "  *libcamera-still'");
          c++;
        } while ( (c<30) && (lengthOf(procList) > 10));
        wait(100);
      } else {
        exec("libcamera-still -t 1 -n -q 100 " + resOpt + " -e " + gbl_pic_ifmt + " -o " + piImageFullFileName);
      }
    } else {
      if (gbl_pic_pviewDo)
        showMessage("RPI Capture", "Click OK to Capture Image");
      File.append("FAKE RPI CAPTURE", piImageFullFileName);
    }

    // If we got an image, then we load it
    if (File.exists(piImageFullFileName)) {
      if (gbl_pic_useCam && gbl_pic_loadem) {
        open(piImageFullFileName);
        if (gbl_ALL_doScl && !(isImageScaled()))
          setScaleForMicrograph(true);
      }
    } else {
      exit("ERROR(captureImageFromRPI): Image file not found!: " + piImageFullFileName);
    }

    if (gbl_pic_repeat && !(gbl_pic_doSet))
      showMessageWithCancel("RPI Capture", "Capture another image?");
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Get a list of group names for captured files
// RPI-CODE
function getCaptureGroupsRPI() {
  piFilesDir = String.join(newArray(getDirectory("home"), "Pictures", "pi-cam"), File.separator);

  // Make sure the pi-cam directory exists
  files = newArray(0);
  if ( !(File.exists(piFilesDir)))
    return files;

  // List of files in pi-cam directory
  files = getFileList(piFilesDir);
  if (files.length == 0)
    return files;

  // Filter out non-image files
  files = Array.filter(files, "(\\.(png|jpg)$)");
  if (files.length == 0)
    return files;

  // Transform to group names
  for(i=0; i<files.length; i++) {
    if (matches(files[i], "(^.............._.*)")) {
      tmp = indexOf(files[i], "-");
      files[i] = substring(files[i], 15, tmp);
    } else {
      files[i] = "_NONE_";
    }
  }

  // Sort group list
  files = Array.sort(files);

  // Replace duplicate group names with _
  lastGrp = "";
  for(i=0; i<files.length; i++) {
  	if (files[i] == lastGrp)
      files[i] = "_";
  	else 
      lastGrp = files[i];
  }

  // Filter out _ strings
  files = Array.deleteValue(files, "_"); 

  // Find last file
  return files;  
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Return the list of captured files in the given groupName
// "_ANY_" & "_NONE_" are special groups...
// RPI-CODE
function getCaptureFileNamesRPI(groupName) {
  piFilesDir = String.join(newArray(getDirectory("home"), "Pictures", "pi-cam"), File.separator);

  // Make sure the pi-cam directory exists
  files = newArray(0);
  if ( !(File.exists(piFilesDir)))
    return files;

  // List of files in pi-cam directory
  files = getFileList(piFilesDir);
  if (files.length == 0)
    return files;

  // Filter out non-image files
  files = Array.filter(files, "(\\.(png|jpg)$)");
  if (files.length == 0)
    return files;

  // Filter out files not in requested group
  if (groupName == "_ANY_") {
    // Do nothing. ;)
  } else if (groupName == "_NONE_") {
    files = Array.filter(files, "(^..............[.-].*)");
    if (files.length == 0)
      return files;
  } else if (lengthOf(groupName)>0) {
    files = Array.filter(files, "(^.............._" + groupName + ".*)");
    if (files.length == 0)
      return files;
  }

  // Sort file list
  files = Array.sort(files);

  // Find last file
  return files;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Return the filename for the most recient pi-cam capture.  See piSnap.sh filename conventions.
// RPI-CODE
function getCaptureRPI() {
  allGroups = getCaptureGroupsRPI();
  tmp = newArray(1);
  tmp[0] = "_ANY_";
  allGroups = Array.concat(tmp, allGroups);
  if (gbl_lil_group == "") {
    if (gbl_pic_group != "") {
      gbl_lil_group = gbl_pic_group;
    } else {
      gbl_lil_group = "_ALL_";
    }
  }
  Dialog.create("Load Previous RPI Capture(s)");
  Dialog.addChoice("Capture Group:", allGroups, gbl_lil_group);
  Dialog.addChoice("Which images:", newArray("First", "First 10", "All", "Last 10", "Last"), gbl_lil_which);
  Dialog.show();

  gbl_lil_group = Dialog.getChoice();
  gbl_lil_which = Dialog.getChoice();

  files = getCaptureFileNamesRPI(gbl_lil_group);
  len  = files.length;
  if (indexOf(gbl_lil_which, " ") > 0)
    num = parseInt(substring(gbl_lil_which, indexOf(gbl_lil_which, " ")+1));
  else
    num = 1;
  num = minOf(num, len);
  if (num > 0) {
    piPath = String.join(newArray(getDirectory("home"), "Pictures", "pi-cam"), File.separator);
    if      (startsWith(gbl_lil_which, "First"))
      files = Array.slice(files, 0, num);
    else if (startsWith(gbl_lil_which, "Last"))
      files = Array.slice(files, len-num, len);
    for(i=0; i<files.length; i++) {
      open(String.join(newArray(piPath, files[i]), File.separator));
      if (gbl_ALL_doScl)
        if ( !(isImageScaled()))
          setScaleForMicrograph(false);
    }
  } else {
    exit("ERROR(getCaptureRPI): No images found!");
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Set image scale for RPI Microscope Camera
// RPI-CODE
function setScaleForMicrograph(freshFromCamera) {

  if (nImages == 0)
    exit("ERROR(setScaleForMicrograph): No open images found!");

  Dialog.create("Set Scale for Stereo Microscope Photograph");
  Dialog.addChoice("Microscope:", newArray("Leica S8API"),   "Leica S8API");
  Dialog.addChoice("Zoom Stop:",  newArray("1.00", "8.00"),  "1.00");
  Dialog.addChoice("Auxiliary:",  newArray("0.63", "1.00"),  "0.63");
  Dialog.addChoice("Video Obj:",  newArray("0.32", "0.50"),  "0.32");
  Dialog.addChoice("Camera:",     newArray("RPI", "OLY"),    "RPI");
  if (freshFromCamera)
    Dialog.addMessage("Adjust for Resolution: YES");
  else
    Dialog.addCheckbox("Adjust for Resolution", gbl_ssm_res);
  Dialog.addCheckbox("Global Scale", gbl_ssm_gbl);
  Dialog.show();

  gbl_ssm_scope = Dialog.getChoice();
  gbl_ssm_zoom  = Dialog.getChoice();
  gbl_ssm_aux   = Dialog.getChoice();
  gbl_ssm_vobj  = Dialog.getChoice();
  gbl_ssm_cam   = Dialog.getChoice();
  if ( !(freshFromCamera))
    gbl_ssm_res   = Dialog.getCheckbox();
  gbl_ssm_gbl   = Dialog.getCheckbox();

  List.clear();
  List.set("Leica S8API", d2s(0.994507340589, 15));
  scopeCalFactor = parseFloat(List.get(gbl_ssm_scope));

  List.clear();
  List.set("OLY", d2s(5184.0 / 17.4,   10));
  List.set("RPI", d2s(4056.0 / 6.2868, 10));
  ijPixHorzScale = parseFloat(List.get(gbl_ssm_cam)) * parseFloat(gbl_ssm_aux) * parseFloat(gbl_ssm_zoom) * parseFloat(gbl_ssm_vobj) * scopeCalFactor;

  if (freshFromCamera || gbl_ssm_res) {
    List.clear();
    List.set("OLY", 5184);
    List.set("RPI", 4056);
    sensorRes = parseInt(List.get(gbl_ssm_cam));
    imgWidth  = getWidth();
    if (sensorRes != imgWidth)
      ijPixHorzScale = ijPixHorzScale * imgWidth / sensorRes;
  }

  ijPixHorzScale = d2s(ijPixHorzScale, 10);

  List.clear();
  List.set("OLY", d2s(5184.0 * 13.0 / 17.4 / 3888.0, 10));
  List.set("RPI", d2s(1.0,                           10));
  ijPixAspectRatio = List.get(gbl_ssm_cam);

  setScaleOptions = " known=1 unit=mm distance=" + ijPixHorzScale + " pixel=" + ijPixAspectRatio;
  if (gbl_ssm_gbl) {
    setScaleOptions = setScaleOptions + " global";
  }

  run("Set Scale...", setScaleOptions);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Takes an integer and returns a zero padded string
// RPI-CODE
function intToZeroPadString(anInt, width) {
  result = d2s(anInt, 0);
  while (lengthOf(result) < width) {
    result = "0" + result;
  }
  return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Returns a string for the current date/time YYYYMMDDhhmmss
// RPI-CODE
function makeDateString() {
  getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
  dateBitVal = newArray(year, month+1, dayOfMonth, hour, minute, second);
  dateBitWid = newArray(4, 2, 2, 2, 2, 2);
  dateString = "";
  for(i=0; i<6; i++) {
    dateString = dateString + intToZeroPadString(dateBitVal[i], dateBitWid[i]);
  }
  return dateString;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check if image has scale.  If not, try to set it or query if RPI iamge.
// RPI-CODE
function isImageScaled() {
  getPixelSize(pixelLengthUnit, pixelWidth, pixelHeight);
  return (is("global scale") || ( !(startsWith(pixelLengthUnit, "pixel"))) || (pixelHeight != 1));
}
