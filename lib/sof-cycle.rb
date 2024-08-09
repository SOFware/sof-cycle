require "forwardable"
require "active_support/deprecator"
require "active_support/deprecation"
require "active_support/core_ext/numeric/time"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/string/conversions"
require "active_support/core_ext/date/conversions"
require "active_support/core_ext/string/filters"
require "active_support/inflector"
require "active_support/string_inquirer"

require_relative "sof/cycle/version"
require_relative "sof/cycle"

Dir[File.join(__dir__, "sof", "cycles", "*.rb")].each { |file| require file }

require_relative "sof/time_span"
