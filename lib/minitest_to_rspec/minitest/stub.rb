# frozen_string_literal: true

require 'minitest_to_rspec/errors'
require 'minitest_to_rspec/type'
require 'minitest_to_rspec/input/model/call'

module MinitestToRspec
  module Minitest
    # Represents an `expects` or a `stubs` from mocha.
    # Conceptually the same as `Rspec::Stub`.
    class Stub
      def initialize(call)
        Type.assert(Input::Model::Call, call)
        @call = call
      end

      # Given e.g. `X.any_instance.expects(:y)`, returns `X`.
      def receiver
        chain = @call.receiver_chain

        if %i(expects stubs).include?(@call.method_name)
          chain.unshift @call.sexp
        end

        chain.each do |receiver_exp|
          if %i(expects stubs).include?(receiver_exp[2])
            if receiver_exp[1] && receiver_exp[1][0] == :call && receiver_exp[1][2] == :any_instance
              return receiver_exp[1][1]
            else
              return receiver_exp[1] ? receiver_exp[1] : s(:self)
            end
          end
        end

        raise "Failed to find receiver"
      end

      # Returns true if we are stubbing any instance of `receiver`.
      def any_instance?
        @call.calls_in_receiver_chain.any? { |i|
          i.method_name.to_s.include?('any_instance')
        }
      end

      # Given e.g. `expects(:y)`, returns `:y`.
      def message
        case @call.method_name
        when :expects, :stubs
          @call.arguments.first
        else
          call = the_call_to_stubs_or_expects
          if call.nil?
            raise UnknownVariant, 'not a mocha stub, no stubs/expects'
          else
            call.arguments.first
          end
        end
      end

      def with
        case @call.method_name
        when :with
          @call.arguments
        else
          @call.find_call_in_receiver_chain(:with)&.arguments
        end
      end

      def raises
        case @call.method_name
        when :raises
          @call.arguments
        else
          @call.find_call_in_receiver_chain(:raises)&.arguments
        end
      end

      def returns
        case @call.method_name
        when :returns
          @call.arguments
        else
          @call.find_call_in_receiver_chain(:returns)&.arguments
        end
      end

      # TODO: add support for
      # - at_least
      # - at_least_once
      # - at_most
      # - at_most_once
      # - never
      def count
        case @call.method_name
        when :expects
          -1
        when :once
          1
        when :never
          0
        when :returns
          the_call_to_stubs_or_expects.method_name == :expects ? -1 : nil
        when :twice
          2
        end
      end

      private

      # Given an `exp` representing a chain of calls, like
      # `stubs(x).returns(y).once`, finds the call to `stubs` or `expects`.
      def the_call_to_stubs_or_expects
        @call.find_call_in_receiver_chain(%i[stubs expects])
      end
    end
  end
end
