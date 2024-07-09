# frozen_string_literal: true

require_relative "../cycle"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/inclusion"
require "active_support/core_ext/hash/reverse_merge"
require "active_support/isolated_execution_state"

module SOF
  # This class is not intended to be referenced directly.
  # This is an internal implementation of Cycle behavior.
  class Cycle::Parser
    extend Forwardable
    PARTS_REGEX = /
      ^(?<vol>V(?<volume>\d*))? # optional volume
      (?<set>(?<kind>L|C|W) # kind
      (?<period_count>\d+) # period count
      (?<period_key>D|W|M|Q|Y)?)? # period_key
      (?<from>F(?<from_date>\d{4}-\d{2}-\d{2}))?$ # optional from
    /ix

    def self.dormant_capable_kinds = %w[W]

    def self.for(str_or_notation)
      return str_or_notation if str_or_notation.is_a? self

      new(str_or_notation)
    end

    def self.load(hash)
      hash.symbolize_keys!
      hash.reverse_merge!(volume: 1)
      keys = %i[volume kind period_count period_key]
      str = "V#{hash.values_at(*keys).join}"
      return new(str) unless hash[:from_date]

      new([str, "F#{hash[:from_date]}"].join)
    end

    def initialize(notation)
      @notation = notation&.upcase
      @match = @notation&.match(PARTS_REGEX)
    end

    attr_reader :match, :notation

    delegate [:dormant_capable_kinds] => "self.class"
    delegate [:period, :humanized_period] => :time_span

    # Return a TimeSpan object for the period and period_count
    def time_span
      @time_span ||= Cycle::TimeSpan.for(period_count, period_key)
    end

    def valid? = match.present?

    def inspect = notation
    alias_method :to_s, :inspect

    def activated_notation(date)
      return notation unless dormant_capable?

      self.class.load(to_h.merge(from_date: date.to_date)).notation
    end

    def ==(other) = other.to_h == to_h

    def to_h
      {
        volume:,
        kind:,
        period_count:,
        period_key:,
        from_date:
      }
    end

    def parses?(notation_id) = kind == notation_id

    def active? = !dormant?

    def dormant? = dormant_capable? && from_date.nil?

    def dormant_capable? = kind.in?(dormant_capable_kinds)

    def period_count = match[:period_count]

    def period_key = match[:period_key]

    def vol = match[:vol] || "V1"

    def volume = (match[:volume] || 1).to_i

    def from_data
      return {} unless from

      {from: from}
    end

    def from_date = match[:from_date]

    def from = match[:from]

    def kind = match[:kind]
  end
end