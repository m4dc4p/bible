
module Bible

  # Will iterate over verses in a given reference, using the lookup given.  
  class BibleIterator
    include Enumerable
    attr_reader :reference
    
    # default lookup, if none selected
    def self.default_lookup
      @@default_lookup ||= nil
    end
    
    def self.default_lookup=(value)
      @@default_lookup = value
    end

    def initialize(ref, lookup = nil)
      raise "A lookup class must be provided if no default is set" if lookup.nil? && @@default_lookup.nil?
      raise "A reference to look up must be provided" if ref.nil?
      @reference = ref
      @lookup = lookup || @@default_lookup
    end

    def method_missing(sym, *args)
      @reference.__send__(sym, *args)
    end

    def iterate_chapter(chapter, &blk)
      if chapter.single_verse?
        blk.call(@lookup.get_ref(chapter.book.book_symbol, chapter.chapter_number, chapter.verse.verse_number), chapter.book.book_symbol, chapter.chapter_number, chapter.verse.verse_number)
      else
        chapter.verses.each { |v| blk.call(@lookup.get_ref(chapter.book.book_symbol, chapter.chapter_number, v.verse_number), chapter.book.book_symbol, chapter.chapter_number, v.verse_number) }
      end
    end

    def iterate_book(book, &blk)
      if book.single_chapter?
        iterate_chapter(book.chapter, &blk)
      else
        book.chapters.each { |c|
          iterate_chapter(c, &blk)
        }
      end
    end

    def each(&blk)
      if @reference.single_book?
        iterate_book(@reference.book, &blk) 
      else
        @reference.books.each { |b| iterate_book(b, &blk) }
      end
    end

    def to_s
      s = ""
      v, b, c = nil, nil, nil

      self.each do |text, book_symbol, chapter_number, verse_number|
        if book_symbol != b && chapter_number != c
          s << "\n\n" unless s.nil? || s.strip == ""
          s << book_symbol.to_s << ", Chapter " << chapter_number.to_s << "\n\n"
        elsif chapter_number != c
          s << "\n\n" unless s.nil? || s.strip == ""
          s << "Chapter " << chapter_number.to_s << "\n\n"
        elsif (! v.nil?) && v != verse_number - 1
          s << "\n\n"
        end
        b, c, v = book_symbol, chapter_number, verse_number
        s << text
      end
      s
    end

    def inspect
      self.to_s
    end
  end

end