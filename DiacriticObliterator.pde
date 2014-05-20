
/*
 DiacriticObliterator
 ====================
 
 DiacriticObliterator by Golan Levin, May 2014
 A processing project which clobbers text files to 7-bit ASCII.
 Built with Processing 2.2 for OSX 10.9
 
 The DiacriticObliterator loads a text document in .txt, .csv (comma-separated) or .tsv (tab-separated) formats. 
 It saves out a copy of the document in which all 'unusual' characters have been converted into their 
 closest 7-bit ASCII equivalents. 
 
 Example: StÃ©phane or Stéphane are converted to Stephane
 
 When you launch the DiacriticObliterator, it will open a file dialogue asking for the document to load. 
 For an input file called myInput.csv, the DiacriticObliterator will produce three output files in the same directory:
 
 myInput-CORRECTED.csv  -- the cleaned-up output file.
 myInput-CHANGES.csv  -- list of changes that were made.
 myInput-UNFIXABLE.csv  -- a list of rows that could not be fixed. 
 */


import javax.swing.*; 
import javax.swing.filechooser.*;

// Character mappings taken from here: 
// http://www.i18nqa.com/debug/utf8-debug.html

String inputFilename = "";
String outputFilename;
Table ordersCsvTable;

Table correctionsTable; 
StringDict correctionsDict; 
boolean bDidIt; 


//=========================================
void setup() {
  size(150, 100); 
  noLoop();

  // Load the dictionary of replacement characters. 
  createReplacementDictionary();

  // Pop up an "Open File" dialog window. 
  // The user should select the spreadsheet they wish to process. 
  openFileDialogToGetInputFilename(); 
  if (inputFilename.length() > 0) {
    int indexOfLastDot = inputFilename.lastIndexOf('.');

    // Create a PrintWriter to capture and save the list of unfixable rows.  
    PrintWriter unfixableRows;
    String unfixableFilename = inputFilename.substring(0, inputFilename.lastIndexOf('.'));
    unfixableFilename += "-UNFIXABLE";
    unfixableFilename += inputFilename.substring(indexOfLastDot, inputFilename.length());

    unfixableRows = createWriter(unfixableFilename); 
    int nUnfixableRows = 0; 

    // Create a PrintWriter to capture and save the list of corrected strings. 
    PrintWriter correctionsMade; 
    String correctionsMadeFilename = inputFilename.substring(0, inputFilename.lastIndexOf('.'));
    correctionsMadeFilename += "-CHANGES"; 
    correctionsMadeFilename += inputFilename.substring(indexOfLastDot, inputFilename.length());
    correctionsMade = createWriter(correctionsMadeFilename); 

    // Load the input file, a spreadsheet of "orders" 
    // (from e.g. Kickstarter, TryCelery), as a Table. 
    // ordersCsvTable = loadTable (inputFilename, "header"); 
    // int nColumns = ordersCsvTable.getColumnCount();

    String inputStrings[] = loadStrings (inputFilename);  
    int nInputStrings = inputStrings.length; 
    for (int i=0; i<nInputStrings; i++) {

      // For each row (order) in the input spreadsheet file,
      boolean bFlagThisRowForFurtherExamination = false;

      // For every column in that row of the Table
      String aString = inputStrings[i]; 
      if (aString != null) {

        // Replace any 'exotic' characters (outside of UTF-7) with simplified versions. 
        String correctedString = replaceProblematicCharactersInString (aString); 
        inputStrings[i] = correctedString; 

        // Add the correction to the list of corrected strings. 
        if (!(correctedString.equals(aString))) {
          correctionsMade.println(aString + "\t" + correctedString);
        }

        // If the row still contains unusual characters, flag it for further inspection. 
        // It may be in a different language. 
        if (containsUnusualChar(correctedString)) {
          bFlagThisRowForFurtherExamination = true;
        }
      }


      if (bFlagThisRowForFurtherExamination) {
        // Save out a row that needs further examination. 
        if (nUnfixableRows == 0) {
          unfixableRows.println("The following rows were not fixable. They may be in another language. Consult the ordering system. \n");
        }
        unfixableRows.println(aString); 
        nUnfixableRows++;
      }
    }

    // Save out the corrected spreadsheet.
    if (indexOfLastDot > 0) {
      outputFilename = inputFilename.substring(0, inputFilename.lastIndexOf('.'));
      outputFilename += "-CORRECTED";
      outputFilename += inputFilename.substring(inputFilename.lastIndexOf('.'), inputFilename.length());
    } else {
      outputFilename = inputFilename + "-CORRECTED";
    }
    saveStrings(outputFilename, inputStrings);

    // Save out the list of unfixable rows. 
    if (nUnfixableRows > 0) { 
      unfixableRows.flush(); // Writes the remaining data to the file
      unfixableRows.close(); // Finishes the file
    }

    // Save out the list of corrections. 
    correctionsMade.flush(); 
    correctionsMade.close();
  } 

  bDidIt = true;
  exit();
}



//=========================================
void createReplacementDictionary() {
  correctionsTable = loadTable("mappings.tsv", "header");
  correctionsDict = new StringDict();
  for (TableRow row : correctionsTable.rows()) {
    String inStr  = row.getString("IN");
    String outStr = row.getString("OUT");
    correctionsDict.set(inStr, outStr);
  }
}

//=========================================
String replaceProblematicCharactersInString (String aString) {

  boolean bMadeReplacement = false;
  if (aString.length() > 0) {
    for (int j=0; j<(aString.length()); j++) {
      char aChar = aString.charAt(j); 
      String charStr = "" + aChar; 

      if (correctionsDict.hasKey(charStr)) {
        String replaceString = correctionsDict.get(charStr); 
        aString = aString.replace(charStr, replaceString);
        bMadeReplacement = true;
      }
    }
  }
  return aString;
}

//=========================================
void openFileDialogToGetInputFilename() {
  try { 
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
  } 
  catch (Exception e) { 
    e.printStackTrace();
  } 

  // Create a file chooser.
  final JFileChooser fc = new JFileChooser();
  final FileFilter myFileFilter = new FileNameExtensionFilter("Text document (.txt, .csv or .tsv)", "txt", "tsv", "csv");
  fc.setDialogTitle("Select a document (.txt, .csv or .tsv) for character cleanup:"); 
  fc.setFileSelectionMode(JFileChooser.FILES_ONLY);
  fc.setFileFilter(myFileFilter); 

  // In response to a button click: 
  int returnVal = fc.showOpenDialog(this); 
  if (returnVal == JFileChooser.APPROVE_OPTION) { 
    File file = fc.getSelectedFile(); 
    if (file.exists()) {
      if ((file.getName().endsWith(".txt")) || (file.getName().endsWith(".csv")) || (file.getName().endsWith(".tsv"))) {

        inputFilename = file.getPath();
        // println (file.getParent());
        println ("Opening: " + inputFilename);
      }
    }
  }
}


//=========================================
String replaceProblematicCharacterPairInString (String aString) {

  boolean bMadeReplacement = false;
  if (aString.length() > 1) {
    for (int j=0; j<(aString.length()-1); j++) {
      char charj0 = aString.charAt(j  ); 
      char charj1 = aString.charAt(j+1);
      String charPairStr = "" + charj0 + charj1; 
      if (correctionsDict.hasKey(charPairStr)) {
        String replaceString = correctionsDict.get(charPairStr); 
        aString = aString.replace(charPairStr, replaceString);
        bMadeReplacement = true;
      }
    }
  }
  if (bMadeReplacement) {
    println (aString);
  }
  return aString;
}

//=========================================
boolean containsUnusualChar (String aString) {

  boolean bOut = false; 
  for (int i=0; i< aString.length(); i++) {
    char aChar = aString.charAt(i); 
    if (((int)aChar) > 127) {
      bOut = true;
    }
  }
  return bOut;
}

//=========================================
void mousePressed() {
  if (bDidIt) {
    exit();
  }
}

void draw() {
  background (144);
}

