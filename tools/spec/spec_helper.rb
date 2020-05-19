# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../exe', __dir__)

require 'rspec_structure_matcher'

$EXAMPLE_WAREHOUSE = File.expand_path('../../examples/warehouse', __dir__)
