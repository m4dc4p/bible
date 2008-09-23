require 'rubygems'
require 'strscan'
require 'yaml'

# Contains classes to parse bible verses and
# an iterator to look them up given an appropriate bible lookup class.
module Bible

  class ChapterInfo
    attr_reader :book, :chapter

    # Takes a BookInfo and count of verses in the chapter
    def initialize(book, chapter, verse_count)
      @book = book
      @chapter = chapter
      @verse_count = verse_count
      @verse_range = Range.new(1, @verse_count)
    end

    # Returns range of verses in this chapter
    def verses
      @verse_range
    end

  end

  class BookInfo

    # Symbol naming book this information is about
    attr_accessor :book, :abbreviations, :chapters

    # Returns the BookInfo of the next book from this book
    def succ
      idx = BookInfo.all_books.index(@book)
      BookInfo.all_books[idx + 1] unless idx.nil?
    end

    def <=>(value)
      if value.respond_to?(:book)
        oidx = BookInfo.all_books.index(value.book)
      elsif value.is_a?(String)
        oidx = BookInfo.all_books.index(value.to_sym)
      elsif value.is_a?(Symbol)
        oidx = BookInfo.all_books.index(value.to_s)
      else
        raise "Don't know how to compare BookInfo to #{value.inspect}"
      end

      return BookInfo.all_books.index(@book) <=> oidx
    end

    # Yields the BookInfo of each book, including this one, up to the next book.
    def upto(b)
      idx = BookInfo.all_books.index(@book)
      endIdx = BookInfo.all_books.index(b)
      while idx <= endIdx
        yield BookInfo.all_books[idx]
        idx += 1
      end
    end

    # Get the nth chapter (0 based)
    def [](value)
      @chapter_info[value]
    end

  private
    def initialize(book, num_chapters, verse_counts, abbreviations)
      @book = book
      # Create hash associating chapters to verses
      @chapters = Range.new(1, num_chapters)
      @chapter_info = ([*(@chapters)].zip(verse_counts).collect { |chapter_def| ChapterInfo.new(self, chapter_def[0], chapter_def[1]) })
      @abbreviations = abbreviations.is_a?(Array) ? abbreviations : [abbreviations]
    end

  public

    def ==(value)
      if value.respond_to?(:book)
        return value.book == @book
      elsif value.respond_to?(:to_s)
        return @book.to_s == value.to_s || Books[value.to_s].book == @book
      else
        false
      end
    end

    # Array of all books defined
    def self.all_books
      @@all_books
    end

    # Get a specific book by passing a symbol representing its name
    def self.[](book)
      return all_books[all_books.index(book)]
    end

    YAML::load_file(File.dirname(__FILE__) + "/bible.yml").each { |b|
       n = b[0].to_sym
       abb = b[1]
       ch = b[2]
       v = b[3]

       # Add name of book to abbreviations, unless it's already there.
       if abb.nil?
         abb = [n.to_s]
       elsif abb.is_a?(Array)
         abb << n.to_s unless abb.include?(n.to_s)
       else
         ((abb = [abb]) << n.to_s) unless abb == n.to_s
       end

       (@@all_books ||= []) << BookInfo.new(n, ch, v, abb)
    }
  end # end BookInfo

  # Index all books by single 'canonical' symbol. Keys are symbols, values are BookInfo instances.
  CanonicalBooks = Hash[*(BookInfo::all_books.collect do |b|
                    if b.book.is_a?(Array)
                      b.book.collect { |bn| [bn, b] }
                    else
                      [b.book, b]
                    end
                  end).flatten]

  # Index all books by possible abbreviations. Keys are strings or symbols and values are BookInfo instances. 
  Books = Hash[*(BookInfo::all_books.collect { |b| b.abbreviations.collect { |a| [a.to_s.downcase, b] } }.flatten)]
  
  class << Books
    def[](value)
      if value.is_a?(Symbol)
        return CanonicalBooks[value]
      else
        super(value.to_s.downcase)
      end
    end
  end

  class BibleRefParser

    # Helper module which can is used by Verses and Chapters objects to compare themselves
    # against Arrays and Ranges.
    module RangeComparisons
      # Compares the given ranges to the given value. value can hold an Array or a Range. An array
      # can contain fixnums or ranges.
      def compare_ranges(ranges, value, which)
        return (value.empty? && ranges.empty?) if value.is_a?(Array) && (value.empty? || ranges.empty?)
        return (value.nil? && ranges.empty?) if value.nil? || ranges.empty?

        if value.is_a?(Range)
          # Continuous ranges mean there are no nil elements in the array, since those represent
          # discontinuous verses or chapters. Therefore, first step is to make sure ranges holds all non-nil items.
          raise "Can't compare to range because #{which} are not continuous." unless ranges.nitems == ranges.length
          return Range.new(ranges.first, ranges.last) == value
        elsif value.is_a?(Array)
          # compare all non-nil elements, since nils are just internal markers for our use
          c = ranges.compact
          offset = 0
          value.each_with_index do |val, idx|
            if val.is_a?(Range)
              val.each do |range_value|
                return false if range_value != c[idx + offset]
                offset += 1
              end
              offset -= 1
            else
              return false if val != c[idx + offset]
            end
          end
          return true
        elsif value.respond_to?(:to_i)
          raise "Can't compare single fixnum to multiple #{which}." unless ranges.length == 1
          return ranges[0].to_i == value.to_i
        else
          raise "Don't know how to compare #{which} to value #{value.inspect}"
        end
        
      end
    end
    
    class Book
      class SingleBook
        attr_accessor :book_symbol, :chapter

        # Argument should be a symbol from BookInfo class representing the book.
        def initialize(book_symbol)
          @book_symbol = book_symbol
        end

        def book
          self
        end

        # Fixes the book reference. If chapter is nil, assumed to refer to entire book. If
        # chapters ends in -1, assumed to refere to chapters to end of book. If any chapters
        # are contained in this book, they will all be fixed up.
        def fixup
          # No chapters at all means ALL chapters, so create the range for fixup.
          if ! has_chapter?
            book = Books[@book_symbol]
            # By reference self.chapters, a refernce to Chapter 1 is created.
            # More verbosely, we could assign self.chapter = Chapter 1 and then
            # reference self.chapters, but there isn't much point.
            self.chapters << Chapter.new(self, -1)
            @chapters.fixup
          elsif single_chapter?
            @chapter.fixup
            if @chapter.single_verse?
              self.verse = @chapter.verse
            end
          else
            @chapters.fixup
          end
          # Don't want reference to chapters method to create chapters after fixup
          @fixedUp = true
        end

        # Assumes value is a symbol and compares it to the book represented
        # here.
        def ==(value)
          return false if value.nil? || @book_symbol.nil?
          if value.is_a?(Symbol)
            return value == @book_symbol
          end
        end

        def has_chapter?
          (respond_to?(:chapter) && ! @chapter.nil?) || (respond_to?(:chapters) && ! @chapters.nil?)
        end

        def single_chapter?
          respond_to?(:chapter)
        end
        
        def single_verse?
          single_chapter? && @chapter.single_verse?
        end

        def method_missing(symbol, *args)
          if ! @fixedUp
            case symbol
            # when chapters is referenced, remove the chapter method
            # and add chapters method so this book has multiple chapters.
            when :chapters
              c = self.chapter
              class << self
                attr_reader :chapters
                undef_method :chapter, :chapter=
              end
              remove_instance_variable :@chapter if defined?(@chapter)

              @chapters = Chapters.new(self)
              # If no initial chapter has been set, set it to 1
              if c.nil?
                @chapters << Chapter.new(self, 1)
              else
                @chapters << c
              end

              @chapters
            when :verse, :verse= 
              class << self
                define_method :verse do
                  @chapter.verse  
                end
  
                define_method :verse= do |value|
                  @chapter.verse = value
                end
              end
              
              self.__send__(symbol, *args)
            else
              super(symbol, *args)
            end
          else
            super(symbol, *args)
          end
        end

        def inspect
          if single_chapter?
            "#{@book_symbol} " + @chapter.inspect
          else
            "#{@book_symbol} " + @chapters.inspect
          end
        end

      end

      class MultipleBooks
        def initialize(single)
          @books = [single]
        end

        def fixup
          if ! @fixedUp 
            @books.compact.each { |b| b.fixup }
            @fixedUp = true
          end
        end

        def <<(value)
          unless value.nil? || @books.last.nil?
            Books[@books.last.book_symbol].succ.upto(value) { |book_info|
              @books << SingleBook.new(book_info.book)
            }
          else
            if value.nil?
              @books << value
            else
              @books << SingleBook.new(value)
            end
          end
        end

        def books
          @books.compact
        end

        def ==(value)
          raise "Can't compare multipe books to single book" unless value.is_a?(Array)
          @books.compact.each_with_index { |b, idx|
            raise "Don't know how to compare to book #{value[idx]}" unless value[idx].is_a?(String) || value[idx].is_a?(Symbol)
          }
        end

        def method_missing(sym, *args)
          # This forwarding is used only until fixup because the parse
          # algorithm depends on it to query the "current reference" in a multiple
          # book situation
          if ! @fixedUp
            @books.last.__send__(sym, *args)
          else
            super(sym, *args)
          end
        end

        def inspect
          @books.compact.inject("") { |val, b|
            val << " " unless val.empty?
            val << b.inspect
            val
          }
        end

      end

      def has_book?
        ! @proxy.nil?
      end

      def single_book?
        self.has_book? && @proxy.is_a?(SingleBook)
      end

      def <<(value)
        if @proxy.nil?
          @proxy = SingleBook.new(value)
        else
          @proxy = MultipleBooks.new(@proxy) if @proxy.is_a?(SingleBook)
          @proxy << value
        end
      end

      def method_missing(symbol, *args)
        if @proxy.nil?
          super(symbol, *args)
        else
          @proxy.__send__(symbol, *args)
        end
      end

    end

    class Chapter
      include Comparable
      include Enumerable

      attr_reader :book, :chapter_number
      attr_accessor :verse

      def initialize(book, chapter)
        raise "Chapter must be an integer" unless chapter.is_a?(Fixnum)

        @book = book
        @chapter_number = chapter
      end

      def fixup
        if ! has_verse?
          self.verses << Verse.new(self, -1)
          self.verses.fixup
        elsif ! single_verse?
          @verses.fixup
        end
        # Don't want reference to verses method to create chapters after fixup
        @fixedUp = true
      end

      # Assumes value is a Fixnum and determines if it is equal
      # to this chapter.
      def ==(value)
        return false if value.nil? || @chapter_number.nil?
        raise "Don't know how to compare chapter to #{value.inspect}" unless value.is_a?(Fixnum)
        return value == @chapter_number
      end

      def to_i
        return @chapter_number.to_i
      end

      def to_s
        return @chapter_number.to_s
      end

      def <=>(value)
        return -1 if value.nil?
        raise "Don't know how to compare Chapter and #{value.inspect} becuase it does not implement to_i." unless value.respond_to?(:to_i)
        return @chapter_number.to_i <=> value.to_i
      end

      def succ
        return Chapter.new(@book, @chapter_number + 1)
      end

      def upto(i)
        raise "Cannot enumerate to value #{i.inspect} because it does not respond to to_i." unless i.respond_to?(:to_i)
        yield self
        (@chapter_number + 1).upto(i.to_i) { |x| yield(Chapter.new(@book, x)) }
      end

      def has_verse?
        (respond_to?(:verse) && ! @verse.nil?) || (respond_to?(:verses) && ! @verses.nil?)
      end

      def single_verse?
        respond_to?(:verse)
      end

      def method_missing(symbol, *args)
        unless @fixedUp
          case symbol
            # when chapters is referenced, remove the chapter method
            # and add chapters method so this book has multiple chapters.
            when :verses
              c = self.verse
              class << self
                attr_reader :verses
                undef_method :verse, :verse=
              end
              remove_instance_variable :@verse if defined?(@verse)

              @verses = Verses.new(self)
              # If no initial verse, set it to 1
              if c.nil?
                @verses << Verse.new(self, 1)
              else
                @verses << c
              end

              @verses
            else
              super(symbol, *args)
          end
        else
          super(symbol, *args)
        end
      end

      def inspect
        if single_verse?
          "#{@chapter_number}:" + @verse.inspect
        else
          "#{@chapter_number}:" + @verses.inspect
        end
      end
    end

    class Verse
      include Comparable
      include Enumerable

      attr_reader :chapter, :verse_number
      attr_accessor :verse

      def initialize(chapter, verse)
        raise "Verse must be an integer" unless verse.is_a?(Fixnum)

        @chapter = chapter
        @verse_number = verse
      end

      # Assumes value is a Fixnum and determines if it is equal
      # to this verse.
      def ==(value)
        return false if value.nil? || @verse_number.nil?
        raise "Don't know how to compare verse to #{value.inspect}" unless value.is_a?(Fixnum)
        return value == @verse_number
      end

      def to_i
        return @verse_number.to_i
      end

      def to_s
        return @verse_number.to_s
      end

      def <=>(value)
        return -1 if value.nil?
        raise "Don't know how to compare Verse and #{value.inspect} becuase it does not implement to_i." unless value.respond_to?(:to_i)
        return @verse_number.to_i <=> value.to_i
      end

      def succ
        return Verse.new(@chapter, @verse_number + 1)
      end

      def upto(i)
        raise "Cannot enumerate to value #{i.inspect} because it does not respond to to_i." unless i.respond_to?(:to_i)
        yield(self)
        (@verse_number + 1).upto(i.to_i) { |x| yield(Verse.new(@chapter, x)) }
      end

      def inspect
        self.to_s
      end
    end

    # Represents range or discontinuous series of chaptesr
    class Chapters
      include RangeComparisons
      
      def initialize(book)
        @chapters = []
        @book = book
      end

      def fixup
        if @chapters.last == -1
          book = Books[@book.book_symbol]
          @chapters.pop
          @chapters.last.succ.upto(book.chapters.last) do |c|
            @chapters << c
          end
        end

        @chapters.compact.each { |c| c.fixup }
      end

      def <<(value)
        unless value.nil? || @chapters.empty? || @chapters.last.nil? || value == -1
          raise "Cannot add a chapter reference in reverse order" if @chapters.last > value
          unless @chapters.last.chapter_number == value
            @chapters.last.succ.upto(value) { |c|
              @chapters << c
            }
          end
        else
          @chapters << value
        end
      end

      def length
        @chapters.length
      end

      def last
        @chapters.last
      end

      def [](index)
        return @chapters.compact[index]
      end

      def ==(value)
        compare_ranges(@chapters, value, "chapters")
      end

      def inspect
        @chapters.inject("") { |val, c|
          val << "," unless val.empty?
          val << c.inspect unless c.nil?
          val
        }
      end

      # Returns Chapter objects for each chapter, or -1 if "end of chapters" is indicated.
      # If chapters is empty, will be a no-op
      def each
        return if @chapters.empty?
        @chapters.each { |chapter|
          yield chapter unless chapter.nil?
        }
      end
    end

      # Represents range or discontinuous series of chaptesr
    class Verses
      include RangeComparisons
      
      def initialize(chapter)
        @verses = []
        @chapter = chapter
      end

      def fixup
        if @verses.last == -1
          @verses.pop
          chapter = Books[@chapter.book.book_symbol][@chapter.chapter_number - 1]
          @verses.last.succ.upto(chapter.verses.last) do |v|
            @verses << v
          end
        end
      end

      def <<(value)
        unless value.nil? || @verses.empty? || @verses.last.nil? || value == -1
          raise "Cannot add a verse reference in reverse order" if @verses.last > value
          unless @verses.last.verse_number == value
            @verses.last.succ.upto(value) { |v|
              @verses << v
            }
          end
        else
          @verses << value
        end
      end

      def length
        @verses.length
      end

      def last
        @verses.last
      end

      def [](index)
        return @verses.compact[index]
      end

      def ==(value)
        compare_ranges(@verses, value, "verses")
      end

      # All verses defined on the chapter. If none are defined, this is a no-op.
      # Will yield either Verse objects or -1 (indicating go to end of verses).
      def each
        return if @verses.empty?
        @verses.each { |verse|
          yield verse unless verse.nil?
        }
      end

      def inspect
        last_verse = nil
        s = @verses.inject("") { |val, v|
          if val.empty? || last_verse.nil?
            val << "," unless val.empty?
            val << v.inspect
          elsif v.nil?
            val << "-#{last_verse.inspect}"
          end

          last_verse = v
          val
        }

        s << "-#{last_verse.inspect}" unless last_verse.nil?
        s
      end
    end

    # determines if a book reference is coming up in the string. Does not
    # determine if its a valid book - jsut the form of one.
    def self.book_ahead?(str)
      return ! get_book(str).nil?
    end

    # Returns the upcoming book, if any. If modify is true, the string passed in has the book referenced removed
    def self.get_book(scanner, modify = false)
      # Look for numbered book references (a digit, followed by whitespace, following by some number of word characters.)
      if t = scanner.check(/\d\s+[A-Za-z]+(\.|)/)
        if modify
          return scanner.scan(/\d\s+[A-Za-z]+(\.|)/).gsub(/\./, "")
        else
          return t
        end
      # Look for one of the 'normal' books
      elsif t = scanner.check(/[A-Za-z]+(\.|)/)
        if modify
          return scanner.scan(/[A-Za-z]+(\.|)/).gsub(/\./, "")
        else
          return t
        end
      end

      return nil
    end

    def self.parse(reference)
      return nil if reference.nil? || (reference = reference.strip) == ""

      state = :book
      # will use curr_ref to build up each reference
      curr_ref = Book.new

      ref = StringScanner.new(reference)
      while ! ref.eos?
        ref.skip(/\s*/)
        if ! ref.eos?
          token = ""
          case state
          when :book, :end_book
            # Special case - one of the numbered books.
            token = get_book(ref, true)

            raise "Book #{token} not recognized in #{ref.rest}"  if Books[token].nil?

            if state == :end_book
              curr_ref << Books[token].book
              state = :end_chapter
            elsif curr_ref.has_book?
              # add discontinuity if there is a previous book defined.
              curr_ref << nil if curr_ref.has_book?
              curr_ref << Books[token].book
              state = :start_chapter
            else
              # look for tokens indicating another book is ahead, rather than a chapter
              curr_ref << Books[token].book
              if ref.skip(/\s+(-|,|;|$)/)
                state = :end_book
              else
                state = :start_chapter
              end
            end
          when :start_chapter, :end_chapter

            # Get all digits, assume they are a chapter
            token << ref.scan(/\d+/)
            chapter = token.to_i rescue (raise "Chapter not recognized as integer #{token}")

            case state
            when :start_chapter
              if ! curr_ref.has_chapter?
                curr_ref.chapter = Chapter.new(curr_ref.book, chapter)
              else
                curr_ref.chapters << Chapter.new(curr_ref.book, chapter)
              end
            when :end_chapter
              # Handles the case where this is a book-spanning reference.
              if ! curr_ref.has_chapter?
                if chapter > 1
                  curr_ref.chapters << Chapter.new(curr_ref.book, chapter)
                else
                  curr_ref.chapter = Chapter.new(curr_ref.book, chapter)
                end
              elsif (! curr_ref.single_chapter?) || curr_ref.chapter != chapter
                curr_ref.chapters << Chapter.new(curr_ref.book, chapter)
              end
            end
            token = ""

            # peek ahead to determine next place to go
            ref.skip(/\s*/)
            case state
            when :start_chapter
              case ref.peek(1)
              when ":", "."
                ref.getch
                state = :start_verse
              when "-"
                ref.getch
                ref.skip(/\s*/)
                if book_ahead?(ref)
                  # indicate we need to go to end of chapters for this book
                  curr_ref.book.chapters << Chapter.new(curr_ref.book, -1)
                  state = :end_book
                else
                  state = :end_chapter
                end
              when ",", ";"
                ref.getch
                ref.skip(/\s*/)
                curr_ref.chapters << nil
                # If a word character comes up next, we are looking at a book reference
                if book_ahead?(ref)
                  state = :book
                else
                  state = :start_chapter
                end
              when ""
                ref.getch
                break
              else
                raise "Unrecognized token after verse: #{ref.rest}"
              end
            when :end_chapter
              case ref.peek(1)
              when ",", ";"
                ref.getch
                ref.skip(/\s*/)
                # add nil to indicate discontinuity
                curr_ref.chapters << nil
                if book_ahead?(ref)
                  state = :book
                else
                  state = :start_chapter
                end
              when ":", "."
                ref.getch
                state = :end_verse
              when ""
                ref.getch
                break
              else
                raise "Unrecognized token after end chapter: #{ref.ref}"
              end
            end
          when :start_verse , :end_verse

            token << ref.scan(/\d+/) if ! ref.eos?
            verse = token.to_i rescue (raise "Verse not recognized as integer #{token}")

            case state
            when :start_verse
              cp = curr_ref.single_chapter? ? curr_ref.chapter : curr_ref.chapters.last
              if ! cp.has_verse?
                cp.verse = Verse.new(cp, verse)
              elsif (! cp.single_verse?) || cp.verse != verse
                cp.verses << nil
                cp.verses << Verse.new(cp, verse)
              end
            when :end_verse
              cp = curr_ref.single_chapter? ? curr_ref.chapter : curr_ref.chapters.last
              if ! cp.has_verse?
                if verse > 1
                  cp.verses << Verse.new(cp, verse)
                else
                  cp.verse = Verse.new(cp, verse)
                end
              elsif (! cp.single_verse?) || cp.verse != verse
                cp.verses << Verse.new(cp, verse)
              end
            end

            token = ""

            # Skip whitespace and single character references (for references such as "Acts 1:1a")
            ref.skip(/[a-zA-Z]?\s*/)
            case ref.peek(1)
            when "-"
              raise "Unrecognized token after #{ref}" if state == :end_verse
              ref.getch
              ref.skip(/\s*/)
              # Determine if we are actually looking at a chapter or book spanning reference.
              # We start by assuming we'll see a verse refernce next, and first look for a book.
              state = :end_verse
              if book_ahead?(ref)
                curr_ref.chapters.last.verses << Verse.new(curr_ref.chapters.last, -1)
                curr_ref.chapters << Chapter.new(curr_ref.book, -1)
                state = :end_book
              else
                # No book was found, so now look for a chapter spannign reference. We do this
                # by seeing if a colon follows the expected numeric reference.
                if ref.check(/\d+(:|\.)/)
                  # This is actually a chapter reference, not a verse reference. Indicate our current verse should
                  # go to the "end", and then go to chapter parsing
                  curr_ref.chapters.last.verses << Verse.new(curr_ref.chapters.last, -1)
                  state = :end_chapter
                end
              end
            when ",", ";"
              ref.getch
              ref.skip(/\s*/)

              # Need to cheat and determine if verse, chapter:verse, or book lie ahead
              # assume we are going to see another verse
              state = :start_verse

              if book_ahead?(ref)
                state = :book
              else
                if ref.check(/\d+(:|\.)/)
                  curr_ref.chapters << nil
                  state = :start_chapter
                elsif ! ref.check(/\d+(,|-|;|$)/)
                    raise "Unrecognized token after end of verse: '#{ref}'"
                end
              end
            when ""
              ref.getch
            else
              raise "Unrecognized token after verse: #{ref.rest}"
            end
          end
        end
      end

      curr_ref.fixup
      return curr_ref
    end
  end
end