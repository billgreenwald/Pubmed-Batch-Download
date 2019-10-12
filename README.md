# Pubmed-Batch-Download

Batch download articles based on PMID (Pubmed ID)

Version 3.0.0  Last update: 11/19/2018.

## Required Packages

As of version 3.0.0, the program is written for python 3.7.  It uses the following non-default packages:
```
requests
requests3
beautifulsoup4
lxml
```

Optionally, instead of installing these yourself, the included "pubmed-batch-downloader-py3.yml" file can be used with anaconda to install an environment that has versions of packages and python known to work with this program.  It can be installed via
```
conda env create -f pubmed-batch-downloader-py3.yml
```

Then, activate the environment with

```
conda activate pubmed-batch-downloader-py3
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
-errors: File path to write all un-downloaded PMIDs during program run.  By default, this is ./unfetched_pmids.tsv.  This file is overwritten each run.
-maxRetries: Maximum number of times to try to redownload a pdf on an Connection Error (specifically, an ECONNRESET code 104).
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

When the program cannot download files, the non-downloaded PMIDs are stored in a PMF format file.  This can then be directly used at a later date with the program.  PMIDs and names are both stored within this file.

**Example script usage:**

```
python fetch_pdfs.py -pmids 123,124,125,23923,111
```
will place the files 123.pdf, 124.pdf, 125.pdf, 23923.pdf, and 111.pdf inside of the PDF folder, assuming all were found

## Known download issues

The requests package cannot execute JavaScript, and thus pages that require javascript to load the link to the pdf or to the journal cannot be obtained with this program.  As of now, this covers the Wolters Kluwer's journals.
