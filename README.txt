= Introduction

This library provides tools to parse Bible references, look them up on the web (in a variety of translations) and to display them in an interactive console session.

= Interactive Use

To use the library as-is, run the included "bible" command. Enter a verse at the prompt and its corresponding text will be displayed. By default, the Revised Standard Version translation is used. The Douay-Rheims and New American Bible translations are also available.

If a reference is instead provided to the script, the interactive console will not be shown. Instead, the corresponding text will be looked up and printed.
 
== Windows Only Features

If the 'win32console' gem is available, the interactive console will print verses with bolded book and chapter headings. If the gem is not available, or the console is not being run on a Win32 system, those features will not be used.

= Library Design

The easiest way to use the library is through the Bible module. If 'bible' is required:

  require 'bible'
  
Then the Bible module gets an index method ('[]') added which can take a reference string and a lookup. It will return an iterator that can produce the text of the reference.

The reference returned also allows access to the individual books, chapters, and/or verses that might be contained. The methods available on the object are dependent on the type of reference parsed. For example, if multiple books were inlclude, the a "books" method is available. Otherwise, only a "book" method is available. This design was inspired by Martin Fowler's post "Humane Interfaces" (http://www.martinfowler.com/bliki/HumaneInterface.html). The "test_bible.rb" file in the "test" directory contains a wide variety of reference forms and corresponding tests of the methods available.

= Limitations

The library is not able to handle the different book and numbering schemes in widely differing bibles very well. Instead, it uses a very broad definition of the Bible to internally parse references given.

= Acknowledgements

Of course, my thanks to Matz for creating Ruby. What a joy it is to program in. I'm also indebted to the fine coders of the "commandline" and "highline" libraries. Finally, my thanks to the King of Kings, Jesus Christ, for the gift of this life. Amen.


