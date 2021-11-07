
macro "Capture From RPI Camera Action Tool - Cc11 F06fa F16fa F4472 F6333 Ld2e3 Le0e3 Lf2e3 Cfff V5866" {
// Capture an image.  See piSnap.sh filename conventions.

  piDebug = false;
    
  // Takes an integer and returns a zero padded string
  function int2str(anInt, width) {
    result = d2s(anInt, 0);
    while (lengthOf(result) < width) {
      result = "0" + result;
    }
    return result;
  }
    
  // Returns a string for the current date/time YYYYMMDDhhmmss
  function makeDateString() {
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
    dateBitVal = newArray(year, month+1, dayOfMonth, hour, minute, second);
    dateBitWid = newArray(4, 2, 2, 2, 2, 2);
    dateString = "";
    for(i=0; i<6; i++) {
      dateString = dateString + int2str(dateBitVal[i], dateBitWid[i]);
    }
    return dateString;
  }
    
  // Make sure we have raspistill installed -- if we don't, then we are probably
  // not running on a RPI..
  if (!(File.exists("/usr/bin/raspistill"))) {
    exit("Could not find /usr/bin/raspistill!");
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
  if (piDebug) {
    print("Image file: " + piImageFullFileName);
  }
    
  // Run raspistill now
  exec("raspistill -t 1 -n -q 100 -o " + piImageFullFileName);
    
  // If we got an image, then we load it
  if (File.exists(piImageFullFileName)) {
    open(piImageFullFileName);	
  } else {
    exit("Image file not found (raspistill failed): " + piImageFullFileName);
  }
}

macro "Set Scale Action Tool - Cc11 L1cfc L1a1e Lfafe L8b8d L5b5d Lbbbd T4707R T9707P Te707I" {
// Set image scale

  Dialog.create("Quick Set Scale");
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
  List.set("OLY", d2s(5184.0 / 17.4,   10));
  List.set("RPI", d2s(4056.0 / 6.2868, 10));
  ijPixHorzScale = d2s(parseFloat(List.get(equipCam)) * equipAux * equipZoom * equipVObj, 10);

  List.clear();
  List.set("OLY", d2s(5184.0 * 13.0 / 17.4 / 3888.0, 10));
  List.set("RPI", d2s(1.0,                           10));
  ijPixAspectRatio = List.get(equipCam);

  setScaleOptions = " known=1 unit=mm distance=" + ijPixHorzScale + " pixel=" + ijPixAspectRatio;
  if (global) {
    setScaleOptions = setScaleOptions + " global=1";
  }  
  //print("Set Scale Options: " + setScaleOptions);

  run("Set Scale...", setScaleOptions);
}

macro "Open Last RPI Capture(s) Action Tool - Cc11 L000f L0fff Lfff3 Lf363 L6340 L4000 T3c07R T8c07P Tdc07I" {
// Open most recient pi-cam capture(s).  See piSnap.sh filename conventions.
   
  piFilesDir = String.join(newArray(getDirectory("home"), "Pictures", "pi-cam"), File.separator);
  if ( piFilesDir == "-") {
   	exit("Unable to locate pi-cam images directory: " + piFilesDir);
  }
   
  // Figure out last file captured
  files = getFileList(piFilesDir);
  files = Array.sort(files);
  lastFile = files[lengthOf(files)-1];
   
  // Open the file(s)
  if (14 == indexOf(lastFile, "_")) {
   	// Have Multiple Captures To Load
   	prefix = substring(lastFile, 0, 15);
   	for (i=0; i<files.length; i++) {
      if (startsWith(files[i], prefix)) {
        open(String.join(newArray(piFilesDir, files[i]), File.separator));
      }
   	}
  } else { 
   	//Have single capture to load
    open(String.join(newArray(piFilesDir, lastFile), File.separator));
  }
}
