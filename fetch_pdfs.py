
# coding: utf-8

# # Imports and command line arguments

# In[2]:


import argparse
import sys
import os
import requests
from bs4 import BeautifulSoup
import re
import urllib


# In[ ]:


parser=argparse.ArgumentParser()
parser._optionals.title = "Flag Arguments"
parser.add_argument('-pmids',help="Comma separated list of pmids to fetch. Must include -pmids or -pmf.", default='%#$')
parser.add_argument('-pmf',help="File with pmids to fetch inside, one pmid per line. Optionally, the file can be a tsv with a second column of names to save each pmid's article with (without '.pdf' at the end). Must include -pmids or -pmf", default='%#$')
parser.add_argument('-out',help="Output directory for fetched articles.  Default: fetched_pdfs", default="fetched_pdfs")
parser.add_argument('-maxRetries',help="Change max number of retries per article on an error 104.  Default: 3", default=3,type=int)
args = vars(parser.parse_args())


# In[54]:


# #debugging
# args={'pmids':'26655157',
#       'pmf':'%#$',
#       'out':'fetched_pdfs',
#       'maxRetries':3,
#       }


# In[5]:


if len(sys.argv)==1:
    parser.print_help(sys.stderr)
    exit(1)
if args['pmids']=='%#$' and args['pmf']=='%#$':
    print "Error: Either -pmids or -pmf must be used.  Exiting."
    exit(1)
if args['pmids']!='%#$' and args['pmf']!='%#$':
    print "Error: -pmids and -pmf cannot be used together.  Ignoring -pmf argument"
    args['pmf']='%#$'
if not os.path.exists(args['out']):
    print "Output directory of {0} did not exist.  Created the directory.".format(args['out'])
    os.mkdir(args['out'])


# # Functions

# In[4]:


def getMainUrl(url):
    return "/".join(url.split("/")[:3])


# In[5]:


def savePdfFromUrl(pdfUrl,directory,name):
    t=requests.get(pdfUrl)
    with open('{0}/{1}.pdf'.format(directory,name), 'wb') as f:
        f.write(t.content)


# In[6]:


def fetch(pmid,finders,name):
  
    uri = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id={0}&retmode=ref&cmd=prlinks".format(pmid)
    success = False
    dontTry=False
    if os.path.exists("{0}/{1}.pdf".format(args['out'],pmid)): # bypass finders if pdf reprint already stored locally
        print "** Reprint #{0} already downloaded and in folder; skipping.".format(pmid)
        return
    else:
        #first, download the html from the page that is on the otherside of the pubmed API
        req=requests.get(uri)
        if 'pubmed' in req.url:
            print " ** Reprint {0} cannot be fetched as pubmed does not have a link to its pdf.".format(pmid)
            dontTry=True
            success=True
        soup=BeautifulSoup(req.content,'lxml')
        
        # loop through all finders until it finds one that return the pdf reprint
        if not dontTry:
            for finder in finders:
                print "Trying {0}".format(finder)
                pdfUrl = eval(finder)(req,soup)
                if type(pdfUrl)!=type(None):
                    savePdfFromUrl(pdfUrl,args['out'],name)
                    success = True
                    print "** fetching of reprint {0} succeeded".format(pmid)
                    break
       
        if not success:
            print "** Reprint {0} could not be fetched with the current finders.".format(pmid)


# # Finders

# In[7]:


def genericCitationLabelled(req,soup): #if anyone has CSH access, I can check this.  Also, a PMID on CSH would help debugging
    
    possibleLinks=soup.find_all('meta',attrs={'name':'citation_pdf_url'})
    if len(possibleLinks)>0:
        print "** fetching reprint using the 'generic citation labelled' finder..."
        pdfUrl=possibleLinks[0].get('content')
        return pdfUrl
    return None
    


# In[8]:


def direct_pdf_link(req,soup): #if anyone has a PMID that direct links, I can debug this better
    
    if req.content[-4:]=='.pdf':
        print "** fetching reprint using the 'direct pdf link' finder..."
        pdfUrl=req.content
        return pdfUrl
    
    return None


# In[66]:


def science_direct(req,soup):
    newUri=urllib.unquote(soup.find_all('input')[0].get('value'))
    req=requests.get(newUri,allow_redirects=True)
    soup=BeautifulSoup(req.content,'lxml')

    possibleLinks=soup.find_all('meta',attrs={'name':'citation_pdf_url'})
    
    if len(possibleLinks)>0:
        print "** fetching reprint using the 'science_direct' finder..."
        pdfUrl=possibleLinks[0].get('content')
        return pdfUrl
    return None


# In[10]:


def pubmed_central(req,soup):

    possibleLinks=soup.find_all('a',re.compile('pdf'))
    
    possibleLinks=[x for x in possibleLinks if 'epdf' not in x.get('title').lower()] #this allows the pubmed_central finder to also work for wiley
    
    if len(possibleLinks)>0:
        print "** fetching reprint using the 'pubmed central' finder..."
        pdfUrl=getMainUrl(req.url)+possibleLinks[0].get('href')
        return pdfUrl
    
    return None


# In[11]:


def acsPublications(req,soup):
    possibleLinks=[x for x in soup.find_all('a') if type(x.get('title'))==str and ('high-res pdf' in x.get('title').lower() or 'low-res pdf' in x.get('title').lower())]
    
    if len(possibleLinks)>0:
        print "** fetching reprint using the 'acsPublications' finder..."
        pdfUrl=getMainUrl(req.url)+possibleLinks[0].get('href')
        return pdfUrl
    
    return None


# In[80]:


def uchicagoPress(req,soup):
    [x for x in soup.find_all('a') if type(x.get('href'))==str and 'pdf' in x.get('href') and '.edu/doi/' in x.get('href')][0]    
    if len(possibleLinks)>0:
        print "** fetching reprint using the 'uchicagoPress' finder..."
        pdfUrl=getMainUrl(req.url)+possibleLinks[0].get('href')
        return pdfUrl
    
    return None


# In[12]:


def zeneric(req,soup): # this finder has been renamed 'zeneric' instead of 'generic' to have it called last (as last resort)
#     page = m.click p.links_with(:text  => /pdf|full[\s-]?text|reprint/i, :href => /.pdf$/i)[0]
    #page = m.click p.links_with(:text  => /pdf|full[\s-]?text|reprint/i).and.href(/.pdf$/i)
#     if len(possibleLinks)>0:
#         print "** fetching reprint using the 'pubmed central' finder..."
#         pdfUrl=getMainUrl(req.url)+possibleLinks[0].get('href')
#         return pdfUrl
    return None


# In[13]:


def zframe(req,soup): # this finder has been renamed 'zframe' instead of 'frame' to have it called last (as last resort)
#   page = m.click p.frame_with(:src => /.pdf/i)
#     if len(possibleLinks)>0:
#         print "** fetching reprint using the 'pubmed central' finder..."
#         pdfUrl=getMainUrl(req.url)+possibleLinks[0].get('href')
#         return pdfUrl
    return None


# # Main

# In[81]:


finders=[
         'genericCitationLabelled',
         'pubmed_central',
         'acsPublications',
         'uchicagoPress',
#          'zeneric', #removed until someone on github reports needing it, and then I will adapt it to python
#          'zframe', #as above  
        'science_direct',
        'direct_pdf_link',
]


# In[82]:


if args['pmids']!='%#$':
    pmids=args['pmids'].split(",")
    names=pmids
else:
    pmids=[line.strip().split() for line in open(args['pmf'])]
    if len(pmids[0])==1:
        pmids=[x[0] for x in pmids]
        names=pmids
    else:
        names=[x[1] for x in pmids]
        pmids=[x[0] for x in pmids]

for pmid,name in zip(pmids,names):
    print ("Trying to fetch pmid {0}".format(pmid))
    retriesSoFar=0
    while retriesSoFar<args['maxRetries']:
        try:
            fetch(pmid,finders,name)
            retriesSoFar=args['maxRetries']
        except requests.ConnectionError as e:
            if '104' in str(e):
                retriesSoFar+=1
                if retriesSoFar<args['maxRetries']:
                    print "** fetching of reprint {0} failed from error {1}, retrying".format(pmid,e)
                else:
                    print "** fetching of reprint {0} failed from error {1}".format(pmid,e)
            else:
                print "** fetching of reprint {0} failed from error {1}".format(pmid,e)
                retriesSoFar=args['maxRetries']
        except Exception as e:
            print "** fetching of reprint {0} failed from error {1}".format(pmid,e)
            retriesSoFar=args['maxRetries']


