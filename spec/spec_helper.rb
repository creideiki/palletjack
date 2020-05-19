# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'palletjack'
require 'rspec/collection_matchers'
$EXAMPLE_WAREHOUSE = File.expand_path('../examples/warehouse', __dir__)
