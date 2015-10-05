##Original code from Edoardo as described below

## pdfetch
## v0.4
## 2007-06-29
##
## Copyright (c) 2006, Edoardo "Dado" Marcora, Ph.D.
## <http://marcora.caltech.edu/>
##
## Released under the MIT license
## <http://www.opensource.org/licenses/mit-license.php>
##
## --------------------------------------------------------------------
##
## This is a Camping web app that automagically fetches a PDF reprint
## of a PubMed article given its PMID.
##
## --------------------------------------------------------------------

## Modified and updated by Bio-geeks 
## <http://bio-geeks.com>

## Further modified and updated to work with Ruby 2.0 by Bill Greenwald
## Also modified and updated to work with websites using iFrames
##

require 'camping'
require 'mechanize'

Camping.goes :Pdfetch

class Reprint < Mechanize::File
  # empty class to use as Mechanize pluggable parser for pdf files
end

class Fetch
  
  def useSocks(server,port)
    require 'socksify'
    TCPSocket::socks_server = server
    TCPSocket::socks_port = port
  end
  
  def get(id)
    @pmid = id.to_s
    @uri = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=#{id}&retmode=ref&cmd=prlinks"
    success = false
    begin
      if File.exist?("pdf/#{id}.pdf") # bypass finders if pdf reprint already stored locally
        success = true
      else
        m = Mechanize.new { |a| a.keep_alive = 1 }
        # set the mechanize pluggable parser for pdf files to the empty class Reprint, as a way to check for it later
        m.pluggable_parser.pdf = Reprint
        begin
          p = m.get(@uri)
          @uri = p.uri
        rescue Timeout::Error
          warn "Timed out trying to connect to #{@uri}"
        end
        finders = Pdfetch::Finders.new
        # loop through all finders until it finds one that return the pdf reprint
        for finder in finders.public_methods(false).sort
          warn "Trying #{finder.to_sym}"
           break if page = finders.send(finder.to_sym, m,p)
        end
       
        if page.kind_of? Reprint
          page.save_as("pdf/#{id}.pdf")
          success = true
        end
      end
      raise unless success
      warn "** fetching of reprint #{id} succeeded"
    rescue
      warn "** fetching of reprint #{id} failed"
    end
  end
end

class Pdfetch::Finders
  # Finders are functions used to find the pdf reprint off a publisher's website.
  # Pass a finder the mechanize agent (m) and the pubmed linkout page (p), and
  # it will return either the pdf reprint or nil.

  def zeneric(m,p) # this finder has been renamed 'zeneric' instead of 'generic' to have it called last (as last resort)
    begin
      page = m.click p.links_with(:text  => /pdf|full[\s-]?text|reprint/i, :href => /.pdf$/i)[0]
      #page = m.click p.links_with(:text  => /pdf|full[\s-]?text|reprint/i).and.href(/.pdf$/i)
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'generic' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def zframe(m,p) # this finder has been renamed 'zframe' instead of 'frame' to have it called last (as last resort)
    begin
      page = m.click p.frame_with(:src => /.pdf#/i)
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'Frame' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def springer_link(m,p)
    begin
      page = m.click p.links_with(:href  => /fulltext.pdf$/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'springer link' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def humana_press(m,p)
    begin
      page = m.click p.links_with(:href => /task=readnow/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'humana press' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def blackwell_synergy(m,p)
    begin
      return nil unless p.uri.to_s =~ /\/doi\/abs\//i
      page = m.get(p.uri.to_s.sub('abs', 'pdf'))
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'blackwell synergy' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def wiley(m,p)
    begin
      page = m.click p.links_with(:text => /pdf/i, :href => /pdfstart/i)[0]
      page = m.click page.frames_with(:name => /main/i, :src => /mode=pdf/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'wiley' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def science_direct(m,p)
    begin
      return nil unless p.uri.to_s =~ /sciencedirect/i
      page = m.get(p.at('body').inner_html.scan(/http:\/\/.*sdarticle.pdf/).first)
#      page = m.click p.links.with.text(/sciencedirect/i).and.href(/sciencedirect/i)
#      page = m.click page.links.with.href(/sdarticle\.pdf$/i)
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'science direct' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  #Sometimes there is an initial choice where one is sciencdirect
  def choose_science_direct(m,p)
    begin
      page = p.search('body').inner_html.scan(/value=\"(http:\/\/.*sciencedirect.com\/science.*)\"/)
      page = m.get(page)
      page = m.click page.links_with(:href => /.pdf$/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'choose science direct' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def ingenta_connect(m,p)
    begin
      page = m.click p.links_with(:href => /mimetype=.*pdf$/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'ingenta connect' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def cell_press(m,p)
    begin
      page = m.click p.links_with(:text => /cell|cancer cell|developmental cell|molecular cell|neuron|structure|immunity|chemistry.+biology|cell metabolism|current biology/i).and.href(/cancercell|cell|developmentalcell|immunity|molecule|structure|current-biology|cellmetabolism|neuron|chembiol/i)[0]
      uid = /uid=(.+)/i.match(page.uri.to_s)
      if uid
        re = Regexp.new(uid[1])
        page = m.click page.links_with(:text => /pdf/i, :href => re)[0]
      else
        page = m.click page.links_with(:text => /pdf \(\d+K\)/i, :href => /\.pdf$/i)[0]
      end
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'cell press' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def jbc(m,p)
    begin
      page = m.click p.links_with(:text => /pdf/i, :href => /reprint/i)[0]
      page = m.click page.frames_with(:name => /reprint/i)[0]
      page = m.click page.links_with(:href => /.pdf$/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'jbc' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def nature(m,p)
    begin
      return nil if p.uri.to_s =~ /sciencedirect/i # think of a better way to skip this finder for sciencedirect reprints!
      page = m.click p.links_with(:text => /full text/i, :href => /full/i)[0]
      page = m.click page.links_with(:href => /.pdf$/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'nature' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def nature_reviews(m,p)
    begin
      page = m.click p.frames_with(:name => /navbar/i)[0]
      page = m.click page.links_with(:href => /.pdf$/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'nature reviews' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def pubmed_central(m,p)
    begin
      # raise unless p.uri =~ /pubmedcentral/i
      page = m.click p.links_with(:text => /pdf/i, :href => /pdf/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'pubmed central' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

 def pnas(m,p)
    begin
      page = p.search('head').inner_html.scan(/meta content=\"(http:\/\/www.pnas.org.*.pdf)\"/)
      page = m.get(page)
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'pnas' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end
  
  def coldspringharbour(m,p)
    begin
      page = p.search('head').inner_html.scan(/meta content=\"(http:\/\/.*cshlp.org.*full.pdf)\"/)
      page = m.get(page)
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'cold spring harbour' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end

  def unknown(m,p)
    begin
      page = m.click p.links_with(:href => /.pdf$/i)[0]
      if page.kind_of? Reprint
        warn "** fetching reprint using the 'unknown' finder..."
        return page
      else
        return nil
      end
    rescue
      return nil
    end
  end
  
   def direct_pdf_link(m,p)
    begin
      if p.kind_of? Reprint
        warn "** fetching reprint using the 'direct pdf link' finder..."
        return p
      else
        return nil
      end
    rescue
      return nil
    end
  end
  
end
