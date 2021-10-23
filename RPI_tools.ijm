
macro "Capture From RPI Camera Action Tool - Cc11 F06fa F16fa F4472 F6333 Ld2e3 Le0e3 Lf2e3 Cfff V5866" {
// Capture an image

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
    
  // Look for ~/tmp.  Try to create it if it is missing.
  piImagePath = String.join(newArray(piImagePath, "tmp"), File.separator);
  if (!(File.exists(piImagePath))) {
    print("Attempting to create directory: " + piImagePath);
    File.makeDirectory(piImagePath);
    if (!(File.exists(piImagePath))) {  
      exit("Directory creation failed: " + piImagePath);
    }
  }
    
  // Look for ~/tmp/pi-images.  Try to create it if it is missing.
  piImagePath = String.join(newArray(piImagePath, "pi-images"), File.separator);
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

  equipmentNames = newArray("Leica S8API Z1 A0.63x C0.50x RPIHQ",
                            "Leica S8API Z8 A0.63x C0.50x RPIHQ",
                            "Leica S8API Z1 A1.00x C0.50x RPIHQ",
                            "Leica S8API Z8 A1.00x C0.50x RPIHQ"
                           );

  equipmentScale = newArray("203.611111111", // 3665/18
                            "1646.00000000", // 3292/2
                            "320.583333333", // 3847/12
                            "2588.57142857"  // 3624/1.4
                           );                             

  Dialog.create("Quick Set Scale");
  // Write the name of the equipments you want to quickly set scale in the array below
  Dialog.addChoice("Equipment:", equipmentNames);
  Dialog.addCheckbox("Global Scale", false);
  Dialog.show();
  equip  = Dialog.getChoice();
  global = Dialog.getCheckbox();
  
  options = " known=1 pixel=1 unit=mm distance=";
  for (i=0; i<equipmentNames.length; i++) {
    if (equip == equipmentNames[i]) {
      options = options + equipmentScale[i];
    }
  }
  if (global) {
    options = options + " global=1";
  }  
  run("Set Scale...", options);
}

macro "Open Last RPI Capture(s) Action Tool - Cc11 L000f L0fff Lfff3 Lf363 L6340 L4000 T3c07R T8c07P Tdc07I" {
// Open most recient pi-cam capture(s)
   
  pp = newArray(String.join(newArray(getDirectory("home"), "Pictures", "pi-cam"), File.separator),
                String.join(newArray(getDirectory("home"), "tmp", "pi-images"), File.separator));
   
  piFilesDir="-";
  for (i=0; i<pp.length; i++) {
    if (File.exists(pp[i])) {
      piFilesDir = pp[i];
      break;
   	}
  }
  if ( piFilesDir == "-") {
   	exit("Unable to locate pi-cam images directory!");
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
