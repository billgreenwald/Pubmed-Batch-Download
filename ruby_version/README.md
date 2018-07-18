# Pubmed Batch Download
Batch download articles based on PMID (Pubmed ID)

## Installation and Set Up

Clone the directory to the desired location, then run
```
./setup.sh
```

## Program Usage

Use the program via 
```
ruby pubmedid2pdf.rb [comma separated list of pubmed IDs]
```
Each run will download the enumerated files to folder titled "PDF" inside the application directory, with each pdf named the PMID correpsonding to the article.  Articles already within the PDF folder will not be downloaded again.

**Example:**

```
ruby pubmedid2pdf.rb 123,124,125,23923,111
```
will place the files 123.pdf, 124.pdf, 125.pdf, 23923.pdf, and 111.pdf inside of the PDF folder, assuming all were found


## Description of included files:

**pdfetch.rb**:  Ruby script that crawls the web using mechanize and downloads the pdf from the appropriate source

**pubmedid2pdf**:  Ruby script that acts as a wrapper for pdfetch.rb, calling it for each pubmed ID passed into the program from the terminal

**PDF**:  Folder that the PDF's will be downloaded to

#### Notes:

This program is an updated version of the script written by Edoardo "Dado" Marcora, Ph.D.
This program uses an updated version of the wrapper written by bio-geeks.

Updates were made by Bill Greenwald to allow the program to run under Ruby version 2.0 and onward (currently runs on version 2.1.2) and to support the introduction of iFrames into the webstandard.


