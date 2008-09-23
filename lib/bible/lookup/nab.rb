require 'open-uri'

module Bible
  class NABLookup

    @@books = {}

    def self.getURL(book, chapter = nil)
      raise "chapter cannot be nil" if chapter.nil?
      b = book.to_s.gsub(" ", "").downcase
      case Bible::Books[book]
      when Bible::Books["Song of Solomon".to_sym]
        "http://www.usccb.org/nab/bible/songs/song#{chapter.to_s}.htm"
      when Bible::Books[:Philemon], Bible::Books[:Obadiah], Bible::Books["2 John".to_sym], Bible::Books["3 John".to_sym], Bible::Books[:Jude]
        "http://www.usccb.org/nab/bible/#{b}/#{b}.htm"
      when Bible::Books[:Psalms]
        "http://www.usccb.org/nab/bible/#{b}/psalm#{chapter.to_s}.htm"
      else
        "http://www.usccb.org/nab/bible/#{b}/#{b}#{chapter.to_s}.htm"
      end
    end

    def self.get_ref(book, chapter = nil, verse = nil)
      # TODO: Handle nil chapter
      text = ((@@books[book] ||= {})[chapter] ||= open(getURL(book, chapter)).gets(nil))
      scanner = StringScanner.new(text)
      scanner.skip_until(/<DL>/)
      scanner = StringScanner.new(scanner.check_until(/<\/DL>/))
      unless verse.nil?
        if scanner.skip_until(/<A.*?NAME="v#{verse}".*?>.*?#{verse}.*?<\/A>/)
          scanner = StringScanner.new(scanner.check_until(/<\/DD>/))
        else
          return ""
        end
      end

      scanner.rest.strip.gsub(/<SUP>.*?<\/SUP>/im, "").gsub(/<.*?>/im, "")
    end
  end
end