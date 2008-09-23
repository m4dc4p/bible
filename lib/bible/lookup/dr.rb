require 'open-uri'

module Bible
  class DRLookup

    @@books = {}

    def self.getURL(book, chapter)
      raise "chapter cannot be nil" if chapter.nil?

      offset = Bible::BookInfo.all_books.index(book) + 1
      "http://www.biblegateway.com/passage/?book_id=#{offset}&chapter=#{chapter}&version=63"
    end

    def self.get_ref(book, chapter = nil, verse = nil)
      # TODO: Handle nil chapter
      text = ((@@books[book] ||= {})[chapter] ||= open(getURL(book, chapter)).gets(nil))
      scanner = StringScanner.new(text)
      if ! scanner.skip_until(/<span id="en-DRA-(.*?)".*?>.*?<\/span>/i)
        scanner = StringScanner.new("")
      else
        unless verse.nil?
          if verse > 1
            id = scanner[1].to_i + (verse - 1)
            if ! scanner.skip_until(/<span id="en-DRA-(#{id})".*?>.*?<\/span>/i)
              scanner = StringScanner.new("")
            end
          end
          
          # Extract verse and place in string
          scanner = StringScanner.new(scanner.check_until(/<p \/>/)) unless scanner.empty?
        end
      end
      
      if scanner.empty?
        ""
      else
        scanner.rest.strip.gsub(/(\d+)<\/span>/, '\1 ').gsub(/<.*?>/im, "")
      end
    end
  end
end