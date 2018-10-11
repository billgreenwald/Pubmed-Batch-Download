# Pubmed-Batch-Download

Batch download articles based on PMID (Pubmed ID)

Version 2.1.  Last update: 10/11/2018.

## Required Packages

The program is written for python 2.7.  It uses the following non-default packages:
```
requests
BeautifulSoup
```

Optionally, instead of installing these yourself, the included "pubmed-batch-download.yml" file an be used with anaconda to install an environment that has versions of packages and python known to work with this program.  It can be installed via
```
conda env create -f pubmed-batch-download.yml
```

## Program Usage

Each run will download the enumerated files to folder by default titled "fetched_pdfs" inside the application directory, with each pdf named the PMID correpsonding to the article.  Articles already within the PDF folder will not be downloaded again.

Use the program via 
```
python fetch_pdfs.py [-pmids or -pmf] [optional arguments]
```

**Arguments**:
The program has the following arguments.  It must be run with *either* -pmids or -pmf, *not both*.  The help page can be displayed by running the program with -h, or with no arguments.
```
-pmids: A comma separated list of pmids to download
-pmf: A file with 1 or 2 columns of pmids and file names to download.  See below for example
-out: The output folder to store the downloaded pdfs.  By default, this is ./fetched_pdfs
-matRetries: Maximum number of times to try to redownload a pdf on an Connection Error (specifically, an ECONNRESET code 104).
```

**PMF File Format**:
The -pmf file allows the user to input a file with a list of pmids, one per line, to download, instead of listing them in the command line with a comma separated list.  This structure would be as follows
```
PMID1
PMID2
PMID3
...
```

Optionally, this file can have a second column, which is what to name the files when you download them.  For example, if I wanted to download the article with pmid 123 and name it "Article_1.pdf" and pmid 4456 with name "Some_Other_Article.pdf", I would use the following pmf file (note, the columns are tab separated)
```
123 Article_1
4456  Some_Other_Article
```

**Example script usage:**

```
python fetch_pdfs.py -pmids 123,124,125,23923,111
```
will place the files 123.pdf, 124.pdf, 125.pdf, 23923.pdf, and 111.pdf inside of the PDF folder, assuming all were found
