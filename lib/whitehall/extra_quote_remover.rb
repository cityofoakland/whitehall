module Whitehall
  class ExtraQuoteRemover
    QUOTE = '"\u201C\u201D\u201E\u201F\u2033\u2036'
    LINE_BREAK = '\r\n?|\n'

    def remove(source)
      source.gsub(/^>\s*[#{QUOTE}]+(.+?)[#{QUOTE}]*[ \t]*(#{LINE_BREAK}?)$/, '> \1\2')
    end
  end
end