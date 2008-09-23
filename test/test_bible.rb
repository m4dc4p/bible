require 'test/unit'

$:.unshift File.dirname(__FILE__) + "/../lib" unless $:.include?(File.dirname(__FILE__) + "../lib")
require 'bible'

class DRTests < Test::Unit::TestCase
  require 'bible/lookup/dr'
  
  def test_get_verse
    assert((result = Bible::DRLookup.get_ref(:Genesis, 1, 1).to_s.strip) == "In the beginning God created heaven, and earth.", "Did not get verse for Genesis 1:1 as expected: #{result}")
  end
  
  def test_get_joel
    # errors
    assert((result = Bible["joel 4", :dr]))
  end
end

class NABTests < Test::Unit::TestCase
  require 'bible/lookup/nab'
  
  def test_get_verses
    assert((result = Bible::NABLookup.get_ref(:Luke, 1, 1).to_s.strip) == "Since many have undertaken to compile a narrative of the events that have been fulfilled among us,", "Did not get verse for Luke 1:1 as expected: #{result}")
    assert((result = Bible::NABLookup.get_ref(:Genesis, 1, 1).to_s.strip) == "In the beginning, when God created the heavens and the earth,", "Did not get verse for Genesis 1:1 as expected: #{result}")
    assert((result = Bible::NABLookup.get_ref(:Revelation, 22, 21).to_s.strip) == "The grace of the Lord Jesus be with all.", "Did not get verse for Rev 22:21 as expected: #{result}")
  end

  def test_get_single_pages
    assert((result = Bible::NABLookup.getURL("1 Samuel".to_sym, 1)) =~ /1samuel1.htm/, "Did not get URL for 1 Samuel as expected: #{result}")
    assert((result = Bible::NABLookup.getURL("Philemon".to_sym, 1)) =~ /philemon.htm/, "Did not get URL for Philemon as expected: #{result}")
    assert((result = Bible::NABLookup.getURL("Obadiah".to_sym, 1)) =~ /obadiah.htm/, "Did not get URL for Obadiah as expected: #{result}")
    assert((result = Bible::NABLookup.getURL("2 John".to_sym, 1)) =~ /2john\/2john.htm/, "Did not get URL for 2 John as expected: #{result}")
    assert((result = Bible::NABLookup.getURL("3 John".to_sym, 1)) =~ /3john\/3john.htm/, "Did not get URL for 3 John as expected: #{result}")
    assert((result = Bible::NABLookup.getURL("Jude".to_sym, 1)) =~ /jude\/jude.htm/, "Did not get URL for Jude as expected: #{result}")
    assert((result = Bible::NABLookup.getURL("Song of Solomon".to_sym, 1)) =~ /songs\/song1.htm/, "Did not get URL for Song of Solomon as expected: #{result}")
    assert((result = Bible::NABLookup.getURL("Luke".to_sym, 1)) =~ /luke1.htm/, "Did not get URL for Luke as expected: #{result}")
  end

  def test_get_psalm2
    assert((result = Bible::NABLookup.getURL("Psalms".to_sym, 1)) =~ /psalms\/psalm1.htm/, "Did not get URL for Pslam 1 as expected: #{result}")
    assert((result = Bible::NABLookup.get_ref("Song of Solomon".to_sym, 1)).to_s =~ /delightful/, "Did not get text for Song of Solomon 1 as expected: #{result}")
    assert((result = Bible["Song 1", :nab].to_s) =~ /delightful/, "Did not get text for Song of Solomon 1 as expected: #{result}")
    result = Bible["Psalm 2", :nab].to_s
    text = <<-EOS.split("\n").each { |line| assert(result.index(line.strip), "Line not found in text of Ps 2: #{line}") }
Why do the nations protest and the peoples grumble in vain?
Kings on earth rise up and princes plot together against the LORD and his anointed:
"Let us break their shackles and cast off their chains!"
The one enthroned in heaven laughs; the Lord derides them,
Then speaks to them in anger, terrifies them in wrath:
"I myself have installed my king on Zion, my holy mountain."
I will proclaim the decree of the LORD, who said to me, "You are my son; today I am your father.
Only ask it of me, and I will make your inheritance the nations, your possession the ends of the earth.
With an iron rod you shall shepherd them, like a clay pot you will shatter them."
And now, kings, give heed; take warning, rulers on earth.
Serve the LORD with fear; with trembling bow down in homage, Lest God be angry and you perish from the way in a sudden blaze of anger. Happy are all who take refuge in God!
EOS
  end
  
  def test_get_joel
    # error
    assert((result = Bible["joel 4", :nab]))
  end

end

class BibleTests < Test::Unit::TestCase

  def setup
    # Ensure that the default used is NAB
    @old_lookup = Bible::BibleIterator.default_lookup
    Bible::BibleIterator.default_lookup = Bible::NABLookup
  end
  
  def teardown
    Bible::BibleIterator.default_lookup = @old_lookup
  end
  
  def test_successors
    successors = Bible::BookInfo.all_books.collect { |b| b.book }
    start = Bible::Books[:Genesis]
    successors.each { |b|
      assert(start.book == b, "Books did not match: #{start.book} != #{b}")
      start = start.succ
    }
  end

  def test_genesis_easy
    ref = Bible["Gen 1:1"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapter == 1)
    assert(ref.chapter.verse == 1)
  end

  def test_genesis_chapters
    ref = Bible["Gen 1-2"]
    assert(ref.book == :Genesis, "Book not as expected:  #{ref.book.inspect}")
    assert(ref.book.chapters == (1..2))
    assert(ref.book.chapters[0] == 1)
    assert(ref.book.chapters[1] == 2)
    assert_raises(NoMethodError) { ref.book.chapter }
  end

  def test_genesis_chapters_indexed
    ref = Bible["Gen 1-3"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapters == (1..3))
    assert(ref.book.chapters[0] == 1)
    assert(ref.book.chapters[1] == 2, "Second book not as expected: #{ref.book.chapters[1].inspect}")
    assert(ref.book.chapters[2] == 3)
    assert_raises(NoMethodError) { ref.book.chapter }
  end

  def test_genesis_chapters_indexed_discontinuous
    ref = Bible["Gen 1-3, 5"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapters == [1, 2, 3, 5])
    assert(ref.book.chapters[0] == 1)
    assert(ref.book.chapters[1] == 2)
    assert(ref.book.chapters[2] == 3)
    assert(ref.book.chapters[3] == 5)
    assert_raises(NoMethodError) { ref.book.chapter }
  end

  def test_genesis_discontinuous_chapters
    ref = Bible["Gen 1, 5"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapters == [1, 5])
  end

  def test_genesis_verses
    ref = Bible["Gen 1:1-10"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapter == 1)
    assert(ref.book.chapter.verses == (1..10))
  end

  def test_genesis_verses_and_chapters
    ref = Bible["Gen 1:1-2:2"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapters == (1..2), "Chapters not as expected. Instead got #{ref.book.chapters.inspect}")
    assert(ref.book.chapters[0] == 1)
    assert(ref.book.chapters[0].verses == (1..31), "Verses not as expected: #{ref.book.chapters[0].verses.inspect}")
    assert(ref.book.chapters[1] == 2)
    assert(ref.book.chapters[1].verses == (1..2), "Verses not as expected: #{ref.book.chapters[1].verses.inspect}")
  end

  def test_genesis_discontinuous_verses
    ref = Bible["Gen 10:1, 3, 5"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapter == 10)
    assert(ref.book.chapter.verses == [1, 3, 5], "Verses not as expected: #{ref.book.chapter.verses.inspect}" )
  end

  def test_genesis_discontinuous_verses_and_chapters
    ref = Bible["Gen 1:1, 3:5"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapters == [1, 3])
    assert(ref.book.chapters[0] == 1)
    assert(ref.book.chapters[0].verse == 1)
    assert(ref.book.chapters[1] == 3)
    assert(ref.book.chapters[1].verse == 5)
  end

  def test_genesis_discontinuous_verses_and_chapters_ranged
    ref = Bible["Gen 1:1-10, 3:5,8"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapters == [1, 3])
    assert(ref.book.chapters[0] == 1)
    assert(ref.book.chapters[0].verses == (1..10))
    assert(ref.book.chapters[1] == 3)
    assert(ref.book.chapters[1].verses == [5, 8])
  end

  def test_two_books
    ref = Bible["Gen 1:1, Lev 1:1"]
    assert(ref.books == [:Genesis, :Leviticus])
    assert(ref.books[0] == :Genesis)
    assert(ref.books[0].chapter == 1)
    assert(ref.books[0].chapter.verse == 1)
    assert(ref.books[1] == :Leviticus)
    assert(ref.books[1].chapter == 1)
    assert(ref.books[1].chapter.verse == 1)
  end

  def test_two_books_with_multiple_verses
    ref = Bible["Gen 1:1-5, Lev 1:10-12"]
    assert(ref.books == [:Genesis, :Leviticus])
    assert(ref.books[0] == :Genesis)
    assert(ref.books[0].chapter == 1)
    assert(ref.books[0].chapter.verses == (1..5))
    assert(ref.books[1] == :Leviticus)
    assert(ref.books[1].chapter == 1)
    assert(ref.books[1].chapter.verses == (10..12))
  end

  def test_multiple_books
    ["Gen 1 - Lev 1", "Gen 1-Lev 1", "Gen 1 -Lev 1"].each { |r|
      ref = Bible[r]
      assert(ref.books == [:Genesis, :Exodus, :Leviticus], "Books not returned as expected: #{ref.books.inspect}")
      assert(ref.books[0] == :Genesis)
      assert(ref.books[0].chapters == (1..50))
      assert(ref.books[1] == :Exodus)
      assert(ref.books[1].chapters == (1..40), "ref #{r} did not parse chapters: #{ref.books[1].chapters.inspect}")
      assert(ref.books[2] == :Leviticus)
      assert(ref.books[2].respond_to?(:chapter), "Chapters not as expected: #{ref.books[2].inspect}")
      assert(ref.books[2].chapter == 1)
    }
  end

  def test_multiple_books_with_verses
    ref = Bible["Gen 1:3-Lev 5:10"]
    assert(ref.books == [:Genesis, :Exodus, :Leviticus])
    assert(ref.books[0] == :Genesis)
    assert(ref.books[0].chapters == (1..50))
    assert(ref.books[0].chapters[0].verses == (3..31))
    assert(ref.books[2] == :Leviticus)
    assert(ref.books[2].chapters == (1..5), "Chapters not as expected: #{ref.books[1].chapters.inspect}" )
    assert(ref.books[2].chapters[0].verses == (1..17), "Verses for chapter 1 not as expected: #{ref.books[2].chapters[0].inspect}")
    assert(ref.books[2].chapters[1].verses == (1..16))
    assert(ref.books[2].chapters[2].verses == (1..17))
    assert(ref.books[2].chapters[3].verses == (1..35))
    assert(ref.books[2].chapters[4].verses == (1..10))
  end

  def test_multiple_books_funny
    ref = Bible["Gen  1:3-Lev 1:10"]
    assert(ref.books == [:Genesis, :Exodus, :Leviticus])
    assert(ref.books[0] == :Genesis)
    assert(ref.books[0].chapters == (1..50))
    assert(ref.books[0].chapters[0].verses == (3..31))
    assert(ref.books[2] == :Leviticus)
    assert(ref.books[2].respond_to?(:chapter), "Chapter not foudn as expected: #{ref.books[2].inspect}")
    assert(ref.books[2].chapter == 1)
    assert(ref.books[2].chapter.verses == (1..10), "Verses not as expected: #{ref.books[2].chapter.verses.inspect}")
  end

  def test_two_books
    ref = Bible["Gen 3:1, Lev 12:1"]
    assert(ref.books == [:Genesis, :Leviticus])
    assert(ref.books[0].book == :Genesis)
    assert(ref.books[0].book.chapter == 3)
    assert(ref.books[0].book.chapter.verse == 1)
    assert(ref.books[1].book == :Leviticus)
    assert(ref.books[1].book.chapter == 12)
    assert(ref.books[1].book.chapter.verse == 1)
  end

  def test_succ
    b = Bible::Books[:Genesis]
    assert(b.succ.book == :Exodus, "Book not as expected: #{b.succ.book}")
  end

  def test_genesis_def
    assert(Bible::Books[:Genesis].chapters == (1..50))
    assert(Bible::Books[:Genesis][0].verses == (1..31))
    assert(Bible::Books[:Genesis][1].verses == (1..25))
    assert(Bible::Books[:Genesis][2].verses == (1..24))
    assert(Bible::Books[:Genesis][3].verses == (1..26))
    assert(Bible::Books[:Genesis][4].verses == (1..32))
    assert(Bible::Books[:Genesis][5].verses == (1..22))
    assert(Bible::Books[:Genesis][6].verses == (1..24))
  end

  def test_1_john
    ref = Bible["1 John 1:1"]
    assert(ref.book == "1 John".to_sym, "ref.book not 1 John: #{ref.book}")
    ref = Bible["1 John 1:1-10"]
    assert(ref.book == "1 John".to_sym)
    assert(ref.book.chapter.verses == (1..10))
    ref = Bible["1 John 1 - 2"]
    assert(ref.book == "1 John".to_sym)
    assert(ref.book.chapters == (1..2))
  end

  def test_1_john_multi_books
    ref = Bible["1 John 1 - 2 John 1"]
    assert(ref.books == ["1 John".to_sym, "2 John".to_sym])
    ref = Bible["1 John 1, 2 John 1"]
    assert(ref.books == ["1 John".to_sym, "2 John".to_sym])
  end

  # Unable to parse multiple verse-spanning references.
  def test_multi_discontinuous_verse
    ref = Bible["2 Sam 11:1-10, 13-17"]
    assert(ref.book == "2 Samuel".to_sym);
    assert(ref.book.chapter == 11);
    assert(ref.book.chapter.verses == [(1..10), (13..17)], "Verses not as expected: #{ref.book.chapter.verses.inspect}");
  end

  # Unable to parse multiple verse-spanning references.
  def test_multi_books
    ref = Bible["1 Kgs - 2 Kgs"]
    assert(ref.books == ["1 Kings".to_sym, "2 Kings".to_sym]);
  end
  
  def test_alternate_format_multi
    ["James 2:14-24, 26, Mark 8:34-9:1", "James 2.14-24, 26; Mark 8.34-9.1"].each { |s|
      ref = Bible[s]
      assert(ref.books == [:James, :Mark], "books not as expected on #{s}: #{ref.books}")
      assert(ref.books[0].chapter == 2, "chapters in james not as expected on #{s}: #{ref.books[0].chapter}")
      assert(ref.books[0].chapter.verses == [14..24, 26], "verses in james not as expected on #{s}: #{ref.books[0].chapter.verses}")
    }
  end
  
  def test_period_after_book_name
    ref = Bible["Gen. 1"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapter == 1)
    ref = Bible["Gen. 1.1-10"]
    assert(ref.book == :Genesis)
    assert(ref.book.chapter == 1)
    assert(ref.book.chapter.verses == (1..10))
    ref = Bible["1 Pt. 1.1-10"]
    assert(ref.book == "1 Peter".to_sym)
    ref = Bible["1 Pet. 1.1-10"]
    assert(ref.book == "1 Peter".to_sym)
    assert(ref.book.chapter == 1)
    assert(ref.book.chapter.verses == (1..10))
    ref = Bible["1 Peter 1.1-10"]
    assert(ref.book == "1 Peter".to_sym)
    assert(ref.book.chapter == 1)
    assert(ref.book.chapter.verses == (1..10))
  end
  
  def test_odd_range
    # '20-14' should cause exception
    assert_raises RuntimeError, "Did not get exception for bad verse reference" do
      ref = Bible["Gen 1:1-2, 3, 20-14, 30"]
    end

    # Notice '20-4' which should be interpreted as 20 - 24
    assert_nothing_raised "Exception should be caused by reference" do
      ref = Bible["Gen 1:1-2, 3, 20-4, 30"]
    end
  end
  
  def test_sentence_references
    ref = Bible["Acts 1:10a"]
    assert(ref.book == :Acts, "Book is not Acts: #{ref.book}")
    assert(ref.book.chapter == 1, "Chapter is not 1: #{ref.book.chapter}")
    assert(ref.book.chapter.verse == 10, "Verse is not 10: #{ref.book.chapter.verse}")
    ref = Bible["Acts 1:1a-10e"]
    assert(ref.book == :Acts, "Book is not acts: #{ref.book}")
    assert(ref.book.chapter == 1, "Chapter is not 1: #{ref.chapter}")
    assert(ref.book.chapter.verses == (1 .. 10), "Verses are not 1 - 10: #{ref.book.chapter.verses}")

    ref = Bible["Acts 1:2a-10:1"]
    assert(ref.book == :Acts, "Book is not acts: #{ref.book}")
    assert(ref.book.chapters == (1 .. 10), "Chapters are not 1 - 10: #{ref.book.chapters}")
    assert(ref.book.chapters[0].verses == (2 .. 26), "Chapter 1 did not contain verses 2 - 26: #{ref.book.chapters[0].verses}")
  end
  
  def test_open_ended_range
    ref = Bible["Acts 1:2-"]
    assert(ref.book == :Acts, "Book is not Acts: #{ref.book}")
    assert(ref.chapter == 1, "Chapter is not 1: #{ref.chapter}")
    assert_nothing_raised "Open ended range should not cause failure" do
      assert(ref.chapter.verses)
    end
  end
  
  def test_accessors
    # Test permutations of books, chapters, verses accessors on reference
    
    # Single book,chapter and verse
    ref = Bible["Acts 1:1"]
    assert_nothing_raised("Single accessors failed") {
      ref.book
      ref.chapter
      ref.verse
    }
    
    assert_raises(NoMethodError, "Multiple accessor should not be allowed") { ref.books }
    assert_raises(NoMethodError, "Multiple accessor should not be allowed") { ref.book.chapters }
    assert_raises(NoMethodError, "Multiple accessor should not be allowed") { ref.chapter.verses }

    # Multiple verses, implicit
    ref = Bible["Acts 1"]
    assert_raises(NoMethodError, "Single verse access should not be allowed: #{ref.reference}") { ref.verse }
    assert_raises(NoMethodError, "Multiple book access should not be allowed: #{ref.reference}") { ref.books }
    assert_raises(NoMethodError, "Multiple chapter access should not be allowed: #{ref.reference}") { ref.book.chapters }

    assert_nothing_raised("Expected accessors failed for ref: #{ref.reference}") do
      ref.book
      ref.chapter
      ref.chapter.verses
    end
    
    # Multiple verses, explicit
    ref = Bible["Acts 1:1-10"]
    assert_raises(NoMethodError, "Single verse access should not be allowed.") { ref.verse }
    assert_raises(NoMethodError, "Multiple book access should not be allowed.") { ref.books }
    assert_raises(NoMethodError, "Multiple chapter access should not be allowed.") { ref.book.chapters }

    assert_nothing_raised("Expected accessors failed for ref: #{ref.reference}") do
      ref.book
      ref.chapter
      ref.chapter.verses
    end
    
    # Multiple chapters, implicit
    ref = Bible["Titus"]
    assert_raises(NoMethodError, "Single chapter access should not be allowed.") { ref.chapter }
    assert_raises(NoMethodError, "Single verse access should not be allowed.") { ref.verse }
    assert_raises(NoMethodError, "Single chapter access should not be allowed.") { ref.book.chapter }
    assert_raises(NoMethodError, "Multiple book access should not be allowed.") { ref.books }

    assert_nothing_raised("Expected accessors failed: #{ref.reference}") do
      ref.book
      ref.book.chapters
      ref.book.chapters[0].verses
    end

    # Multiple chapters, explicit
    ref = Bible["Acts 1-2"]
    assert_raises(NoMethodError, "Single chapter access should not be allowed.") { ref.chapter }
    assert_raises(NoMethodError, "Single verse access should not be allowed.") { ref.verse }
    assert_raises(NoMethodError, "Single chapter access should not be allowed.") { ref.book.chapter }
    assert_raises(NoMethodError, "Multiple book access should not be allowed.") { ref.books }

    assert_nothing_raised("Expected accessors failed: #{ref.reference}") do
      ref.book
      ref.book.chapters
      ref.book.chapters[0].verses
    end
    
    # Multiple books
    ref = Bible["Acts - Rom"]
    assert_raises(NoMethodError, "Single chapter access should not be allowed.") { ref.chapter }
    assert_raises(NoMethodError, "Single verse access should not be allowed.") { ref.verse }
    assert_raises(NoMethodError, "Single book access should not be allowed: #{ref.reference}") { ref.book }

    assert_nothing_raised("Expected accessors failed: #{ref.reference}") do
      ref.books
      ref.books[0].chapters
      ref.books[0].chapters[0].verses
    end
    
  end
  
  def test_philemon
    # error
    assert_nothing_raised "Unable to refence book of Philemon alone" do
      ref = Bible["Phil"]
    end
  end

end
