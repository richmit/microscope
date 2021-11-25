////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var gbl_ALL_doScl     = true;                     // RPI-CODE
var gbl_ALL_piDebug   = false;                    // RPI-CODE
var gbl_pic_doSet     = false;                    // RPI-CODE
var gbl_pic_ifmt      = "jpg";                    // RPI-CODE
var gbl_pic_pviewDo   = true;                     // RPI-CODE
var gbl_pic_pviewScl  = 4;                        // RPI-CODE
var gbl_pic_res       = "100%";                   // RPI-CODE
var gbl_ssm_aux       = "0.63";                   // RPI-CODE
var gbl_ssm_cam       = "RPI";                    // RPI-CODE
var gbl_ssm_gbl       = false;                    // RPI-CODE
var gbl_ssm_res       = true;                     // RPI-CODE
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
  Dialog.addChoice("Image Format:", newArray("jpg", "png"),              gbl_pic_ifmt);
  Dialog.addChoice("Image Size:", newArray("100%", "50%"),               gbl_pic_res);
  Dialog.addChoice("Preview Scale (1/n):", newArray("1", "2", "4", "8"), gbl_pic_pviewScl);
  Dialog.addCheckbox("Change settings before capture",                   gbl_pic_doSet);
  Dialog.addCheckbox("Set scale after capture/load",                     gbl_ALL_doScl);
  Dialog.addCheckbox("Video preview before capture",                     gbl_pic_pviewDo);
  Dialog.addCheckbox("Debuging",                            gbl_ALL_piDebug);
  Dialog.show();

  gbl_pic_ifmt     = Dialog.getChoice();
  gbl_pic_res      = Dialog.getChoice();
  gbl_pic_pviewScl = Dialog.getChoice();
  gbl_pic_doSet    = Dialog.getCheckbox();
  gbl_ALL_doScl    = Dialog.getCheckbox();
  gbl_pic_pviewDo  = Dialog.getCheckbox();
  gbl_ALL_piDebug  = Dialog.getCheckbox();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Capture an image.  See piSnap.sh filename conventions.
// RPI-CODE
function captureImageFromRPI() {
  // Make sure we have libcamera-still installed -- if we don't, then we are probably
  // not running on a RPI..
  if (!(File.exists("/usr/bin/libcamera-still"))) {
    exit("ERROR(captureImageFromRPI): Could not find /usr/bin/libcamera-still!");
  }

  // Make sure we can find the user home directory
  piImagePath = getDirectory("home");
  if (!(File.exists(piImagePath))) {
    exit("ERROR(captureImageFromRPI): Could not find home directory!");
  }

  // Look for ~/Pictures.  Try to create it if it is missing.
  piImagePath = String.join(newArray(piImagePath, "Pictures"), File.separator);
  if (!(File.exists(piImagePath))) {
    print("Attempting to create directory: " + piImagePath);
    File.makeDirectory(piImagePath);
    if (!(File.exists(piImagePath))) {
      exit("ERROR(captureImageFromRPI): Directory creation failed: " + piImagePath);
    }
  }

  // Look for ~/Pictures/pi-cam.  Try to create it if it is missing.
  piImagePath = String.join(newArray(piImagePath, "pi-cam"), File.separator);
  if (!(File.exists(piImagePath))) {
    print("Attempting to create directory: " + piImagePath);
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

  // We have to break this up on two lines for some reason...
  piImageFileName = makeDateString();
  piImageFileName = piImageFileName + "." + gbl_pic_ifmt;

  // Construct full file name path
  piImageFullFileName = String.join(newArray(piImagePath, piImageFileName), File.separator);
  if (gbl_ALL_piDebug) {
    print("Image file: " + piImageFullFileName);
  }

  resOpt = "";
  if (gbl_pic_res == "50%")
    resOpt = "--width 2028 --height 1520";

  // Run libcamera-still
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

    waitForUser("RPI Capture", "Click OK to Capture Image");

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

  // If we got an image, then we load it
  if (File.exists(piImageFullFileName)) {
    open(piImageFullFileName);
    if (gbl_ALL_doScl)
      if ( !(isImageScaled()))
        setScaleForMicrograph();
  } else {
    exit("ERROR(captureImageFromRPI): Image file not found!: " + piImageFullFileName);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Open most recient pi-cam capture(s).  See piSnap.sh filename conventions.
// RPI-CODE
function getImageLastRPI() {
  piFilesDir = String.join(newArray(getDirectory("home"), "Pictures", "pi-cam"), File.separator);
  if ( piFilesDir == "-") {
    exit("ERROR(getImageLastRPI): Unable to locate pi-cam images directory: " + piFilesDir);
  }

  // List of files in pi-cam directory
  files = getFileList(piFilesDir);
  if ( files.length == 0)
    exit("ERROR(getImageLastRPI): No files found in pi-cam images directory: " + piFilesDir);

  // Filter out non-image files
  files = Array.filter(files, "(\\.(png|jpg)$)");
  if ( files.length == 0)
    exit("ERROR(getImageLastRPI): No image files found in pi-cam images directory: " + piFilesDir);

  // Sort file list
  files = Array.sort(files);

  // Find last file
  lastFile = files[lengthOf(files)-1];

  open(String.join(newArray(piFilesDir, lastFile), File.separator));
  if (gbl_ALL_doScl)
    if ( !(isImageScaled()))
      setScaleForMicrograph();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Set image scale for RPI Microscope Camera
// RPI-CODE
function setScaleForMicrograph() {

  if (nImages == 0)
    exit("ERROR(setScaleForMicrograph): No open images found!");

  Dialog.create("Set Scale for Stereo Microscope Photograph");
  Dialog.addChoice("Microscope:", newArray("Leica S8API"),   "Leica S8API");
  Dialog.addChoice("Zoom Stop:",  newArray("1.00", "8.00"),  "1.00");
  Dialog.addChoice("Auxiliary:",  newArray("0.63", "1.00"),  "0.63");
  Dialog.addChoice("Video Obj:",  newArray("0.32", "0.50"),  "0.32");
  Dialog.addChoice("Camera:",     newArray("RPI", "OLY"),    "RPI");
  Dialog.addCheckbox("Adjust for Resolution", gbl_ssm_res);
  Dialog.addCheckbox("Global Scale", gbl_ssm_gbl);
  Dialog.show();

  gbl_ssm_scope = Dialog.getChoice();
  gbl_ssm_zoom  = Dialog.getChoice();
  gbl_ssm_aux   = Dialog.getChoice();
  gbl_ssm_vobj  = Dialog.getChoice();
  gbl_ssm_cam   = Dialog.getChoice();
  gbl_ssm_res   = Dialog.getCheckbox();
  gbl_ssm_gbl   = Dialog.getCheckbox();

  List.clear();
  List.set("Leica S8API", d2s(1.0, 10));
  scopeCalFactor = parseFloat(List.get(gbl_ssm_scope));

  List.clear();
  List.set("OLY", d2s(5184.0 / 17.4,   10));
  List.set("RPI", d2s(4056.0 / 6.2868, 10));
  ijPixHorzScale = parseFloat(List.get(gbl_ssm_cam)) * parseFloat(gbl_ssm_aux) * parseFloat(gbl_ssm_zoom) * parseFloat(gbl_ssm_vobj) * scopeCalFactor;

  if (gbl_ssm_res) {
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
