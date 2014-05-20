

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

