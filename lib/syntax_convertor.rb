require 'plist'
require_relative "./syntax_formatter"
require_relative "./syntax_yaml"

module Sublime
  class SyntaxConvertor
    attr_reader :syntax

    include SyntaxFormatter

    def initialize(lang)
      @lang       = Plist.parse_xml(lang)
      @repository = @lang.fetch('repository', {})
      @patterns   = @lang.fetch('patterns', [])
      @syntax     = {}
      normalize_repository
      convert
    end

    def to_yaml
      Sublime::SyntaxYaml.new(@syntax).yaml
    end

    private

    # normalize the repository values into being a list of patterns
    def normalize_repository
      @repository.each do |key, value|
        if value.key?('begin') || value.key?('match')
          @repository[key] = [value]
        else
          @repository[key] = value['patterns']
        end
      end
    end

    def create_contexts
      contexts   = {}
      contexts['main'] = make_context(@lang['patterns'])
      @repository.each do |key, value|
        fail 'Double definition of main context' if key == 'main'
        contexts[key] = make_context(value)
      end
      contexts
    end

    def convert
      syntax = {}
      syntax['comment']          = format_comment(@lang['comment']) if @lang.key?('comment')
      syntax['first_line_match'] = format_regex(@lang['firstLineMatch']) if @lang.key?('firstLineMatch')
      syntax['name']             = @lang['name']           if @lang.key?('name')
      syntax['scope']            = @lang['scopeName']      if @lang.key?('scopeName')
      syntax['file_extensions']  = @lang['fileTypes']      if @lang.key?('fileTypes')
      syntax['hidden']           = @lang['hideFromUser']   if @lang.key?('hideFromUser')
      syntax['hidden']           = @lang['hidden']         if @lang.key?('hidden')
      syntax['contexts']         = create_contexts
      @syntax = syntax
    end

    def create_rule(type, pattern)
      entry = {}
      entry['match'] = format_regex(pattern[type])
      entry['pop'] = true if type == 'end'
      pattern_key = pattern["#{type}Captures"] || pattern["captures"]
      if pattern_key
        captures = format_captures(pattern_key)
        if captures.key?('0')
          entry['scope'] = captures['0']
          captures.delete('0')
        end
        entry['captures'] = captures if captures.size > 0
      end
      entry
    end

    def handle_begin_pattern(pattern)
      entry = create_rule('begin', pattern)
      end_entry = create_rule('end', pattern)

      if end_entry['match'].include? "\\G"
        puts """WARNING:
        pop pattern contains \\G, this will not work as expected
        if it's intended to refer to the begin regex: #{end_entry['match']}"""
      end

      apply_last = pattern.key?('applyEndPatternLast') && pattern['applyEndPatternLast'] == 1
      child_patterns =  pattern.key?('patterns') ? pattern["patterns"] : []
      child = make_context(child_patterns)
      apply_last ? child.push(end_entry) : child.unshift(end_entry)
      child.unshift('meta_content_scope' => pattern['contentName']) if pattern.key?('contentName')
      child.unshift('meta_scope' => pattern['name']) if pattern.key?('name')
      entry['comment'] = format_comment(pattern['comment']) if pattern.key?('comment') && !format_comment(pattern['comment']).empty?
      entry['push'] = child
      entry
    end

    def handle_match_pattern(pattern)
      entry = {}
      entry['match'] = format_regex(pattern['match'])
      entry['scope'] = pattern['name'] if pattern.key?('name')
      entry['captures'] = format_captures(pattern['captures']) if pattern.key?('captures')
      entry['comment'] = format_comment(pattern['comment']) if pattern.key?('comment') && !format_comment(pattern['comment']).empty?
      entry
    end

    def handle_include_pattern(pattern)
      key = pattern['include']
      if key[0] == '#'
        key = key[1..-1]
        fail Exception("no entry in repository for #{key}") unless @repository.key?(key)
        return { 'include' => key }
      elsif key == '$self'
        return { 'include' => 'main' }
      elsif key == '$base'
        return { 'include' => '$top_level_main' }
      elsif key[0] == '$'
        fail Exception "unknown include: #{key}"
      else
        return { 'include' => format_external_syntax(key) }
      end
    end

    def make_context(patterns)
      ctx = []
      patterns.each do |pattern|
        if pattern.key?('begin')
          entry = handle_begin_pattern(pattern)
        elsif pattern.key?('match')
          entry = handle_match_pattern(pattern)
        elsif pattern.key?('include')
          entry = handle_include_pattern(pattern)
        else
          fail Exception("unknown pattern type: #{pattern.keys}")
        end
        ctx.push(entry) if entry
      end
      ctx
    end
  end
end
