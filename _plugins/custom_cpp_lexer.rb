require 'rouge'

module Rouge
  module Lexers
    class CppCustomLexer < Rouge::Lexers::Cpp
      tag 'cpp' # Extend the cpp lexer

      # https://github.com/rouge-ruby/rouge/blob/master/lib/rouge/lexers/c.rb
      # https://github.com/rouge-ruby/rouge/blob/master/lib/rouge/lexers/cpp.rb
      #def self.keywords_type
      #  @keywords_type ||= super + Set.new(%w(
      #    S8 S16 S32 S64
      #    U8 U16 U32 U64
      #    Float Double
      #    float2 float3 float4
      #    vec2 vec3 vec4
      #  ))
      #end

      prepend :root do
        rule %r/\b(S8|S16|S32|S64)\b/, Keyword::Type
        rule %r/\b(U8|U16|U32|U64)\b/, Keyword::Type
        rule %r/\b(Float|Double)\b/, Keyword::Type
        rule %r/\b(float2|float3|float4)\b/, Keyword::Type
        rule %r/\b(vec2|vec3|vec4)\b/, Keyword::Type
        rule %r/[A-Z][a-zA-Z0-9_]*/, Name::Class # Starts with majuscule and then contains alpha numeric values
        rule %r/\b(printf|push_back|pop_back)\b/, Name::Function
      end

      prepend :statements do
        rule %r/\b(S8|S16|S32|S64)\b/, Keyword::Type
        rule %r/\b(U8|U16|U32|U64)\b/, Keyword::Type
        rule %r/\b(Float|Double)\b/, Keyword::Type
        rule %r/\b(float2|float3|float4)\b/, Keyword::Type
        rule %r/\b(vec2|vec3|vec4)\b/, Keyword::Type
        rule %r/[A-Z][a-zA-Z0-9_]*/, Name::Class # Starts with majuscule and then contains alpha numeric values
        rule %r/\b(printf|push_back|pop_back)\b/, Name::Function
      end
    end
  end
end
