require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
	s.name = "bible"
	s.summary = "A library for parsing bible references and looking them up on the web."
	s.version = "1.0.3"
	s.author = "Justin Bailey"
	s.email = "jgbailey@gmail.com"
	
	s.description = <<EOS

This package implements a failry sophisticated Bible verse parser and iterator which will
look up the given verse on the web. Three classes are provided for looking up different translations.

EOS

	s.platform = Gem::Platform::RUBY
	s.files = FileList["lib/**/*", "test/*", "*.txt", "Rakefile"].to_a

	s.bindir = "bin"
	s.executables = ["bible"]

	s.require_path = "lib"
	s.autorequire = "bible"

	s.has_rdoc = true
	s.extra_rdoc_files = ["README.txt"]
	s.rdoc_options << '--title' << 'Bible -- Verse Parser and Lookup Tool' <<
                       '--main' << 'README.txt' <<
                       '--line-numbers'

	s.add_dependency("highline", ">= 1.2.1")
	s.add_dependency("commandline", ">= 0.7.10")

end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
