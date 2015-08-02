require_relative "./syntax_formatter"

module Sublime
  class MatchPattern
    include SyntaxFormatter
    attr_reader :match, :scope, :captures, :comment

    def initialize(pat)
      @match = format_regex(pat['match'])
      @scope = pat['name'] if pat.key?('name')
      @captures = format_captures(pat['captures']) if pat.key?('captures')
      @comment = format_comment(pat['comment']) if pat.key?('comment') && !format_comment(pat['comment']).empty?
    end

    def to_h
      hash = {}
      hash['match'] = @match if @match
      hash['scope'] = @scope if @scope
      hash['captures'] = @captures if @captures
      hash['comment'] = @comment if @comment
      hash
    end
  end

  class BeginEndPattern
    include SyntaxFormatter
    attr_reader :match, :pop, :captures

    def initialize(type, pattern)
      @pattern = pattern
      @type = type
      @match = format_regex(pattern[type])
      @pop = true if type == 'end'
      handle_captures
    end

    def to_h
      hash = {}
      hash['match'] = @match if @match
      hash['pop'] = @pop if @pop
      hash['captures'] = @captures if @captures
      hash
    end

    private

    def handle_captures
      pattern_captures = @pattern["#{@type}Captures"] || @pattern["captures"]
      return unless pattern_captures
      captures = format_captures(pattern_captures)
      if captures.key?('0')
        entry['scope'] = captures['0']
        captures.delete('0')
      end
      @captures = captures if captures.size > 0
    end
  end
end
