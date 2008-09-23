require 'open-uri'

module Bible
  class RSVLookup
    @@books = {}

    def self.getURL(book, chapter)
      raise "chapter cannot be nil" if chapter.nil?
      
      case book
      when %s(1 Kings)
        b = "1Kgs"
      when %s(2 Kings)
        b = "2Kgs"
      when :Job
        b = "BJob"
      when %s(Song of Solomon)
        b = "Cant"
      when :Philemon
        b = "Phlm"
      else
        b = book.to_s.split(" ").join("")[0 ... 4]
      end
      "http://etext.lib.virginia.edu/etcbin/toccer-new2?id=Rsv#{b}.sgm&images=images/modeng&data=/texts/english/modeng/parsed&tag=public&part=#{chapter}&division=div1"
    end

    def self.get_ref(book, chapter , verse )
      raise "Verse cannot be nil for RSV lookup." if verse.nil?
      raise "Chapter cannot be nil for RSV lookup." if chapter.nil?
      
      text = ((@@books[book] ||= {})[chapter] ||= open(getURL(book, chapter)).gets(nil))
      scanner = StringScanner.new(text)
      if ! verse.nil?
        if ! scanner.skip_until(/<i>#{verse}:<\/i>/)
          scanner = StringScanner.new("")
        else
          scanner = StringScanner.new(scanner.scan_until(/(<br>|<\/p>)/)[0 ... scanner[1].length * -1])
        end
      end
      
      if scanner.empty?
        ""
      else
        scanner.rest
      end
    end
  end
end