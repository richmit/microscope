////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var gbl_ALL_piDebug   = false;                    // RPI-CODE
var gbl_pic_wPreview  = true;                     // RPI-CODE
var gbl_ssm_scope     = "Leica S8API";            // RPI-CODE
var gbl_ssm_zoom      = "1.00";                   // RPI-CODE
var gbl_ssm_aux       = "0.63";                   // RPI-CODE
var gbl_ssm_vobj      = "0.32";                   // RPI-CODE
var gbl_ssm_cam       = "RPI";                    // RPI-CODE
var gbl_ssm_gbl       = false;                    // RPI-CODE

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
  setScaleForMicrograph();
}

macro "Open Last RPI Capture(s) Action Tool - Cc11 L000f L0fff Lfff3 Lf363 L6340 L4000 T3c07R T8c07P Tdc07I" {
  getImageLastRPI();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Capture an image.  See piSnap.sh filename conventions.
// RPI-CODE
function configureRPI() {
  Dialog.create("Configure RPI Settings");
  Dialog.addCheckbox("Preview before capture", gbl_pic_wPreview);
  Dialog.addCheckbox("Debuging",               gbl_ALL_piDebug);
  Dialog.show();
  
  gbl_pic_wPreview = Dialog.getCheckbox();
  gbl_ALL_piDebug  = Dialog.getCheckbox();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Capture an image.  See piSnap.sh filename conventions.
// RPI-CODE
function captureImageFromRPI() {
  // Make sure we have libcamera-still installed -- if we don't, then we are probably
  // not running on a RPI..
  if (!(File.exists("/usr/bin/libcamera-still"))) {
    exit("Could not find /usr/bin/libcamera-still!");
  }

  // Make sure we can find the user home directory
  piImagePath = getDirectory("home");
  if (!(File.exists(piImagePath))) {
    exit("Could not find home directory!");
  }

  // Look for ~/Pictures.  Try to create it if it is missing.
  piImagePath = String.join(newArray(piImagePath, "Pictures"), File.separator);
  if (!(File.exists(piImagePath))) {
    print("Attempting to create directory: " + piImagePath);
    File.makeDirectory(piImagePath);
    if (!(File.exists(piImagePath))) {
      exit("Directory creation failed: " + piImagePath);
    }
  }

  // Look for ~/Pictures/pi-cam.  Try to create it if it is missing.
  piImagePath = String.join(newArray(piImagePath, "pi-cam"), File.separator);
  if (!(File.exists(piImagePath))) {
    print("Attempting to create directory: " + piImagePath);
    File.makeDirectory(piImagePath);
    if (!(File.exists(piImagePath))) {
      exit("Directory creation failed: " + piImagePath);
    }
  }

  // Check again that piImagePath really exists...
  if (!(File.exists(piImagePath))) {
    exit("Could not find/create image directory: " + piImagePath);
  }

  // We have to break this up on two lines for some reason...
  piImageFileName = makeDateString();
  piImageFileName = piImageFileName + ".jpg";

  // Construct full file name path
  piImageFullFileName = String.join(newArray(piImagePath, piImageFileName), File.separator);
  if (gbl_ALL_piDebug) {
    print("Image file: " + piImageFullFileName);
  }

  // Run libcamera-still
  if (gbl_pic_wPreview) {
    procList = exec("/bin/bash", "-c", "ps -eo cmd | grep '^ *libcamera-still'");
    if (lengthOf(procList) > 10) 
      exit("ERROR: libcamera-still is already running.  Close it first");

    pid = exec("/bin/bash", "-c", "libcamera-still -t 0 -s -o '" + piImageFullFileName + "' >/dev/null 2>&1 & echo $!", "&");
    pid = String.trim(pid);

    if ( !(matches(pid, "(^[0-9][0-9]*$)"))) 
      exit("ERROR: Can't get PID of libcamera-still process -- it may not have started!");

    waitForUser("RPI Capture", "Click OK to Capture Image");

    procList = exec("/bin/bash", "-c", "ps -eo pid,cmd | grep '^ *" + pid + "  *libcamera-still'");
    if (lengthOf(procList) < 10) 
      exit("ERROR: Unable to trigger capture (Can't find libcamera-still process)!");

    exec("/bin/bash", "-c", "kill -SIGUSR1 " + pid);
    c=0;
    do {
      wait(100);
      procList = exec("/bin/bash", "-c", "ps -eo pid,cmd | grep '^ *" + pid + "  *libcamera-still'");
      c++;
    } while ( (c<20) && (lengthOf(procList) > 10));
    wait(100);
  } else {
    exec("libcamera-still -t 1 -n -q 100 -o " + piImageFullFileName);
  }
    
  // If we got an image, then we load it
  if (File.exists(piImageFullFileName)) {
    open(piImageFullFileName);
    checkImageScale();
  } else {
    exit("Image file not found!: " + piImageFullFileName);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Open most recient pi-cam capture(s).  See piSnap.sh filename conventions.
// RPI-CODE
function getImageLastRPI() {
  piFilesDir = String.join(newArray(getDirectory("home"), "Pictures", "pi-cam"), File.separator);
  if ( piFilesDir == "-") {
    exit("Unable to locate pi-cam images directory: " + piFilesDir);
  }

  // List of captured files
  files = getFileList(piFilesDir);

  if ( files.length == 0) {
    exit("No files found in pi-cam images directory: " + piFilesDir);
  }

  // Figure out last file captured
  files = Array.sort(files);
  // TODO: Should filter the array at this point -- i.e. only use files that match RE
  lastFile = files[lengthOf(files)-1];

  // Open the file(s)
  if (14 == indexOf(lastFile, "_")) {
    // Have Multiple Captures To Load
    prefix = substring(lastFile, 0, 15);
    for (i=0; i<files.length; i++) {
      if (startsWith(files[i], prefix)) {
        open(String.join(newArray(piFilesDir, files[i]), File.separator));
        checkImageScale();
      }
    }
  } else {
    //Have single capture to load
    open(String.join(newArray(piFilesDir, lastFile), File.separator));
    checkImageScale();
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Set image scale for RPI Microscope Camera
// RPI-CODE
function setScaleForMicrograph() {

  Dialog.create("Set Scale for Stereo Microscope Photograph");
  Dialog.addChoice("Microscope:", newArray("Leica S8API"),   "Leica S8API");
  Dialog.addChoice("Zoom Stop:",  newArray("1.00", "8.00"),  "1.00");
  Dialog.addChoice("Auxiliary:",  newArray("0.63", "1.00"),  "0.63");
  Dialog.addChoice("Video Obj:",  newArray("0.32", "0.50"),  "0.32");
  Dialog.addChoice("Camera:",     newArray("RPI", "OLY"),    "RPI");
  Dialog.addCheckbox("Global Scale", false);
  Dialog.show();

  equipScope = Dialog.getChoice();
  equipZoom  = parseFloat(Dialog.getChoice());
  equipAux   = parseFloat(Dialog.getChoice());
  equipVObj  = parseFloat(Dialog.getChoice());
  equipCam   = Dialog.getChoice();
  global     = Dialog.getCheckbox();

  List.clear();
  List.set("Leica S8API", d2s(1.0, 10));
  scopeCalFactor = parseFloat(List.get(equipScope));

  List.clear();
  List.set("OLY", d2s(5184.0 / 17.4,   10));
  List.set("RPI", d2s(4056.0 / 6.2868, 10));
  ijPixHorzScale = d2s(parseFloat(List.get(equipCam)) * equipAux * equipZoom * equipVObj * scopeCalFactor, 10);

  List.clear();
  List.set("OLY", d2s(5184.0 * 13.0 / 17.4 / 3888.0, 10));
  List.set("RPI", d2s(1.0,                           10));
  ijPixAspectRatio = List.get(equipCam);

  setScaleOptions = " known=1 unit=mm distance=" + ijPixHorzScale + " pixel=" + ijPixAspectRatio;
  if (global) {
    setScaleOptions = setScaleOptions + " global";
  }

  run("Set Scale...", setScaleOptions);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Set Scale based on filename.  Return true if we set the DPI.
// RPI-CODE
function setScaleFromFileName() {
  fileName = getInfo("image.filename");
  dirPath  = getInfo("image.directory");
  fileNameParts = split(toUpperCase(fileName), "_");
  dpiAll = "";
  dpiH   = "";
  dpiV   = "";
  for(i=0;i<fileNameParts.length;i++) {
    dpiIdx = indexOf(fileNameParts[i], "DPI");
    if (dpiIdx>0) {
      dpiStr = substring(fileNameParts[i], 0, dpiIdx);
      if (endsWith(dpiStr, "H")) {
        if (lengthOf(dpiH)>0)
          showMessage("Warning", "Multiple HDPI values encoded in filename!");
        dpiH = substring(dpiStr, 0, lengthOf(dpiStr)-1);
      } else if (endsWith(fileNameParts[i], "v")) {
        if (lengthOf(dpiV)>0)
          showMessage("Warning", "Multiple VDPI values encoded in filename!");
        dpiV = substring(dpiStr, 0, lengthOf(dpiStr)-1);
      } else {
        if (lengthOf(dpiAll)>0)
          showMessage("Warning", "Multiple DPI values encoded in filename!");
        dpiAll = dpiStr;
      }
    }
  }

  if ((lengthOf(dpiAll)>0) && (maxOf(lengthOf(dpiH), lengthOf(dpiH))==0)) {
    tmp = parseFloat(dpiAll);
    if (tmp > 0) {
      run("Set Scale...", " known=25.4 unit=mm distance=" + dpiAll + " pixel=1");
      return true;
    } else {
      showMessage("Warning", "Malformed DPI encoded in filename!");
    }
  } else if ((lengthOf(dpiAll)==0) && (lengthOf(dpiH)>0) && (lengthOf(dpiH)>0)) {
    tmpH = parseFloat(dpiH);
    tmpV = parseFloat(dpiV);
    if ((tmpH > 0) && (tmpV > 0)) {
      run("Set Scale...", " known=25.4 unit=mm distance=" + dpiH + " pixel=" + d2s(tmpH/tmpV, 10));
      return true;
    } else {
      showMessage("Warning", "Malformed HDPI/VDPI encoded in filename!");
    }
  } else if ((lengthOf(dpiAll)>0) || (lengthOf(dpiH)>0) || (lengthOf(dpiH)>0)) {
    showMessage("Warning", "Malformed DPI/HDPI/VDPI encoded in filename!");
  }
  return false;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Check if image has scale.  If not, try to set it or query if RPI iamge.
// RPI-CODE
function checkImageScale() {
  getPixelSize(pixelLengthUnit, pixelWidth, pixelHeight);
  if (pixelLengthUnit != "mm") {
    if (setScaleFromFileName()) {
      showMessage("Warning", "Image scale has been set from DPI information embedded in image name!");
    } else if (matches(getInfo("image.directory"), ".*Pictures.pi-cam.*$")) {
      setScaleForMicrograph();
    }
    getPixelSize(pixelLengthUnit, pixelWidth, pixelHeight);
    if (pixelLengthUnit != "mm")
      exit("Image scale units must be millimeters (mm)");
  }
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










