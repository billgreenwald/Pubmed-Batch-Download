#!/usr/bin/env ruby 

# == Synopsis 
#   This program tries to download a PDF file for the given comma-separated pubmed IDs
#
# == Required GEMS
#     mechanize (0.9.3)
#     socksify (1.1.0) (if you plan on using SOCKS)
#
# == Examples
#     pubmedid2pdf.rb 19508715,18677110,19450510,19450585
#
#   Other examples:
#    This example downloads through SOCKS, here we are using a localhost connection through port 9999
#    Meaning that you can ssh to your some server you have access to that can access some PDFs that you cannot, f.ex. your University
#    This is done with this command: ssh -D 9999 username@server in another terminal
#    To use SOCKS call the program with the server and the port, in this case 127.0.0.1 and 9999
#     pubmedid2pdf.rb 19508715 127.0.0.1 9999
#
# == Usage 
#    pubmedid2pdf.rb pubmedid/s [server] [port]
#
# == Author
#   Bio-geeks (adapted a script by Edoardo "Dado" Marcora, Ph.D.)
#   <http://bio-geeks.com>
#
# == Copyright
#   Copyright (c) 2009 Bio-geeks. Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php
#
# == Copyright
#   Copyright (c) 2015 Bill Greenwald. Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php

require 'optparse'
require 'rubygems'
require_relative './pdfetch.rb'

#pmid = 19508715
pubmeds = ARGV[0]

if (pubmeds.nil?)
  RDoc::usage() #exits app
end

pubmeds_array = pubmeds.split(",")
server = ARGV[1]
port = ARGV[2]

fetcher = Fetch.new()

if (!server.nil? && !port.nil?)
  fetcher.useSocks(server,port)
end

pubmeds_array.each do |p|
  warn "Trying to fetch #{p}"   
  fetcher.get(p)
end
