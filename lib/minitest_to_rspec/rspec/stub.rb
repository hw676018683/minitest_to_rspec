# frozen_string_literal: true

require 'minitest_to_rspec/type'

module MinitestToRspec
  module Rspec
    # Represents a `receive` matcher from RSpec.
    # Conceptually the same as `Minitest::Stub`.
    class Stub
      def initialize(receiver, any_instance, message, with, returns, count, raises = nil)
        Type.assert(Sexp, receiver)
        Type.bool(any_instance)
        Type.assert(Sexp, message)
        Type.assert([NilClass, Sexp], with)
        Type.assert([NilClass, Sexp], returns)
        Type.assert([NilClass, Integer], count)
        @receiver = receiver
        @any_instance = any_instance
        @message = message
        @with = with
        @returns = returns
        @count = count
        @raises = raises
      end

      # Returns a Sexp representing an RSpec stub (allow) or message
      # expectation (expect)
      def to_rspec_exp
        stub_chain =
          if @message[0] == :hash
            s(:call, nil, :receive_messages, @message)
          else
            s(:call, nil, :receive, @message)
          end

        unless @with.nil?
          stub_chain = s(:call, stub_chain, :with, *@with)
        end

        if rspec_mocks_method == :expect_any_instance_of
          unless @count.nil? || @count == -1
            stub_chain = s(:call, stub_chain, receive_count_method)
          end
        end

        unless @returns.nil?
          stub_chain = s(:call, stub_chain, :and_return, *@returns)
        end
        unless @raises.nil?
          stub_chain = s(:call, stub_chain, :and_raise, *@raises)
        end

        if rspec_mocks_method != :expect_any_instance_of
          unless @count.nil? || @count == -1
            stub_chain = s(:call, stub_chain, receive_count_method)
          end
        end

        expect_allow = s(:call, nil, rspec_mocks_method, @receiver.dup)
        s(:call, expect_allow, :to, stub_chain)
      end

      private

      def receive_count_method
        case @count
        when 1
          :once
        when 2
          :twice
        when 0
          :never
        else
          raise "Unsupported message receive count: #{@count}"
        end
      end

      # Returns :expect or :allow
      def rspec_mocks_method
        prefix = @count.nil? ? 'allow' : 'expect'
        suffix = @any_instance ? '_any_instance_of' : ''
        (prefix + suffix).to_sym
      end
    end
  end
end
