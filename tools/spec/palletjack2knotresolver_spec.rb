# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'rspec/collection_matchers'

load 'palletjack2knotresolver'

describe 'palletjack2knotresolver' do
  before :example do
    @tool = PalletJack2KnotResolver.instance
    allow(@tool).to receive(:argv).and_return([
      '-w', $EXAMPLE_WAREHOUSE
    ])
    @tool.setup
    @tool.process
  end

  it 'points to the correct authoritative server' do
    @tool = PalletJack2KnotResolver.instance
    expect(@tool.domains).to eq(
      { 'example.com' => '192.168.0.3' }
    )
  end
end
