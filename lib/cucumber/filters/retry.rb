require 'cucumber/core/filter'
require 'cucumber/running_test_case'
require 'cucumber/events/bus'
require 'cucumber/events/after_test_case'

module Cucumber
  module Filters
    class Retry < Core::Filter.new(:configuration)

      def test_case(test_case)
        CaseFilter.new(test_case, configuration).test_case.describe_to receiver

        configuration.on_event(:after_test_case) do |event|
          case_filter = CaseFilter.new(test_case, configuration)

          next unless retry_required?(case_filter.test_case, event)

          test_case_counts[case_filter.test_case] += 1
          case_filter.test_case.describe_to(receiver)
        end

        super
      end

      class CaseFilter
        def initialize(test_case, configuration)
          @original_test_case = test_case
          @configuration      = configuration
        end

        def test_case
          @original_test_case.with_steps(test_steps)
        end

        private

        def test_steps
          @original_test_case.test_steps
        end
      end

      private

      attr_reader :original_test_case

      def retry_required?(test_case, event)
        event.test_case == test_case && event.result.failed? && test_case_counts[test_case] < configuration.retry_attempts
      end

      def test_case_counts
        @test_case_counts ||= Hash.new {|h,k| h[k] = 0 }
      end
    end
  end
end
