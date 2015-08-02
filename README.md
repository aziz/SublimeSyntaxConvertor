# Sublime Syntax Convertor
Converts `tmLanguage` to `sublime-syntax`

## Install
Add this line to your application's Gemfile:

```ruby
gem 'sublime_syntax_convertor'
```

And then execute:

    bundle

Or install it yourself as:

    gem install sublime_syntax_convertor

## USAGE

### Command line 
```bash
sublime_syntax_convertor files
sublime_syntax_convertor folder
```

### In your code
```ruby
require 'sublime_syntax_convertor'
file = File.read(tmLanguage_file)
convertor = SublimeSyntaxConvertor::Convertor.new(file)
sublime_syntax = convertor.to_yaml
```


---
&copy; Copyright 2015 Allen Bargi. See LICENSE for details.
