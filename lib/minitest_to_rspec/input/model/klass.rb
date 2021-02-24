# frozen_string_literal: true

require 'minitest_to_rspec/input/model/base'

module MinitestToRspec
  module Input
    module Model
      # Data object.  Represents a `:class` S-expression.
      class Klass < Base
        def initialize(exp)
          assert_sexp_type(:class, exp)
          @exp = exp.dup
          assert_valid_name
        end

        def action_controller_test_case?
          lineage?(parent, %i[ActionController TestCase])
        end

        def action_mailer_test_case?
          lineage?(parent, %i[ActionMailer TestCase])
        end

        def active_support_test_case?
          lineage?(parent, %i[ActiveSupport TestCase])
        end

        def active_view_case?
          lineage?(parent, %i[ActionView TestCase])
        end

        def active_job_case?
          lineage?(parent, %i[ActiveJob TestCase])
        end

        def integration_case?
          lineage?(parent, %i[ActionDispatch IntegrationTest])
        end

        # Raise an error if we don't know now to process the name
        # of this class.  Specifically, classes with module-shorthand.
        def assert_valid_name
          return true
          if name.is_a?(Symbol)
            # Valid
          elsif name.respond_to?(:sexp_type) && name.sexp_type == :colon2
            raise ModuleShorthandError
          else
            raise ProcessingError, "Unexpected class expression: #{name}"
          end
        end

        def block?
          !block.empty?
        end

        def block
          @_block ||= @exp[3..-1] || []
        end

        def test_unit_test_case?
          lineage?(parent, %i[Test Unit TestCase])
        end

        def draper_test_case?
          lineage?(parent, %i[Draper TestCase])
        end

        # Returns the name of the class.  Examples:
        #
        # - Banana #=> :Banana
        # - Fruit::Banana #=> s(:colon2, s(:const, :Fruit), :Banana)
        #
        # Note that the latter (module shorthand) is not supported
        # by MinitestToRspec.  See `#assert_valid_name`.
        #
        def name
          # FIX：Module shorthand (A::B::C) is not supported
          if @exp[1].respond_to?(:sexp_type) && @exp[1].sexp_type == :colon2
            ancestor_names(@exp[1]).join("::").to_sym
          else
            @exp[1]
          end
        end

        # Returns the "inheritance".  Examples:
        #
        # - Inherit nothing #=> nil
        # - Inherit Foo #=> s(:const, :Foo)
        # - Inherit Bar::Foo #=> s(:colon2, s(:const, :Bar), :Foo)
        #
        def parent
          @_parent ||= @exp[2]
        end

        # Returns true if `@exp` inherits from, e.g. ActiveSupport::TestCase.
        # TODO: Other test case parent classes.
        def test_case?
          return false unless sexp_type?(:colon2, parent)
          active_support_test_case? ||
            action_controller_test_case? ||
            action_mailer_test_case? ||
            test_unit_test_case? ||
            draper_test_case? ||
            active_view_case? ||
            active_job_case? ||
            integration_case?
        end

        private

        def ancestor_names(exp)
          return [exp] if exp.is_a?(Symbol)

          # Support colon3 type
          sexp_type?(:colon2, exp) || sexp_type?(:const, exp) || sexp_type?(:colon3, exp) ||
            raise(TypeError, "Expected :const or :colon2, got #{exp.inspect}")

          exp.sexp_body.flat_map { |entry| ancestor_names(entry) }
        end

        def lineage?(exp, names)
          assert_sexp_type(:colon2, exp)
          ancestor_names(exp) == names
        end
      end
    end
  end
end
