# Includes for bible functionality
$:.unshift File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__))
require 'bible/parser'
require 'bible/iterator'

module Bible
    # Returns an iterator for the given verses, with the given lookup.
  def self.[](ref, lookup = nil)
    require 'iterator' unless defined? BibleIterator
    if lookup.is_a?(Symbol) || lookup.is_a?(String) 
      case lookup.to_s.downcase.strip
      when "nab"
        require 'bible/lookup/nab' unless defined?(NABLookup)
        lookup = NABLookup
      when "dr"
        require 'bible/lookup/dr' unless defined?(DRLookup)
        lookup = DRLookup 
      when "rsv"
        require 'bible/lookup/rsv' unless defined?(RSVLookup)
        lookup = RSVLookup 
      else
        raise "Unknown lookup specified: #{lookup}"
      end
    elsif lookup.nil?
      if BibleIterator.default_lookup.nil?
        require 'bible/lookup/rsv' unless defined?(RSVLookup)
        BibleIterator.default_lookup = RSVLookup
      end
    end

    return BibleIterator.new(BibleRefParser::parse(ref), lookup)
  end
end
