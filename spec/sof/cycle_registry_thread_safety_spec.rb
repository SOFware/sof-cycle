# frozen_string_literal: true

require "spec_helper"

RSpec.describe SOF::CycleRegistry do
  describe "thread safety" do
    let(:registry) { described_class.instance }
    let(:original_classes) { [] }

    before do
      # Save the original classes
      @original_classes = registry.cycle_classes.to_a
      # Clear the registry before each test
      registry.cycle_classes.clear
    end

    after do
      # Restore the original classes
      registry.cycle_classes.clear
      @original_classes.each { |klass| registry.register(klass) }
    end

    it "safely registers multiple cycle classes concurrently" do
      # Create some test cycle classes
      test_classes = 10.times.map do |i|
        Class.new do
          define_singleton_method(:handles?) { |kind| kind == "test#{i}" }
          define_singleton_method(:name) { "TestCycle#{i}" }
        end
      end

      threads = test_classes.map do |klass|
        Thread.new { registry.register(klass) }
      end

      threads.each(&:join)

      expect(registry.cycle_classes.size).to eq(10)
      test_classes.each do |klass|
        expect(registry.cycle_classes).to include(klass)
      end
    end

    it "safely handles concurrent reads while registering" do
      # Pre-register some classes
      5.times do |i|
        klass = Class.new do
          define_singleton_method(:handles?) { |kind| kind == "existing#{i}" }
        end
        registry.register(klass)
      end

      read_errors = []
      write_errors = []

      # Create threads that read
      read_threads = 20.times.map do
        Thread.new do
          100.times do
            registry.cycle_classes.to_a
            registry.cycle_classes.size
          rescue => e
            read_errors << e
          end
        end
      end

      # Create threads that write
      write_threads = 5.times.map do |i|
        Thread.new do
          klass = Class.new do
            define_singleton_method(:handles?) { |kind| kind == "new#{i}" }
          end
          begin
            registry.register(klass)
          rescue => e
            write_errors << e
          end
        end
      end

      (read_threads + write_threads).each(&:join)

      expect(read_errors).to be_empty
      expect(write_errors).to be_empty
      expect(registry.cycle_classes.size).to eq(10) # 5 existing + 5 new
    end

    it "safely finds handlers concurrently" do
      # Register test classes
      10.times do |i|
        klass = Class.new do
          define_singleton_method(:handles?) { |kind| kind == "kind#{i}" }
          define_singleton_method(:name) { "Handler#{i}" }
        end
        registry.register(klass)
      end

      errors = []
      results = Concurrent::Array.new

      threads = 100.times.map do |i|
        Thread.new do
          kind_index = i % 10
          begin
            handler = registry.handling("kind#{kind_index}")
            results << handler
          rescue => e
            errors << e
          end
        end
      end

      threads.each(&:join)

      expect(errors).to be_empty
      expect(results.size).to eq(100)

      # Verify all lookups found the correct handler
      results.each_with_index do |handler, i|
        expected_kind = "kind#{i % 10}"
        expect(handler.handles?(expected_kind)).to be true
      end
    end

    it "raises error for unknown kind even under concurrent access" do
      # Register a known handler
      known_class = Class.new do
        define_singleton_method(:handles?) { |kind| kind == "known" }
      end
      registry.register(known_class)

      errors = Concurrent::Array.new

      threads = 10.times.map do
        Thread.new do
          registry.handling("unknown")
        rescue SOF::Cycle::InvalidKind => e
          errors << e
        end
      end

      threads.each(&:join)

      expect(errors.size).to eq(10)
      errors.each do |error|
        expect(error.message).to include("':unknown' is not a valid kind of Cycle")
      end
    end

    it "maintains singleton behavior across threads" do
      instances = Concurrent::Array.new

      threads = 20.times.map do
        Thread.new do
          instances << described_class.instance
        end
      end

      threads.each(&:join)

      expect(instances.uniq.size).to eq(1)
      expect(instances.first).to be(described_class.instance)
    end
  end
end
