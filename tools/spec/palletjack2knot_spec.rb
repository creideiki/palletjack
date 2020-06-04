# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'rspec/collection_matchers'

load 'palletjack2knot'

describe 'palletjack2knot' do
  it 'requires an output directory' do
    @tool = PalletJack2Knot.instance
    allow(@tool).to receive(:argv).and_return([
      '-w', $EXAMPLE_WAREHOUSE,
      '-s', 'example-com'
    ])
    allow($stderr).to receive(:write)
    expect{@tool.setup}.to raise_error SystemExit
  end

  it 'requires a service name' do
    @tool = PalletJack2Knot.instance
    allow(@tool).to receive(:argv).and_return([
      '-w', $EXAMPLE_WAREHOUSE,
      '-o', Dir.tmpdir
    ])
    allow($stderr).to receive(:write)
    expect{@tool.setup}.to raise_error SystemExit
  end

  context 'generates' do
    before :example do
      @tool = PalletJack2Knot.instance
      allow(@tool).to receive(:argv).and_return([
        '-w', $EXAMPLE_WAREHOUSE,
        '-o', Dir.tmpdir,
        '-s', 'example-com'
      ])
      @tool.setup
      @tool.process
    end

    it 'global server configuration' do
      @tool = PalletJack2Knot.instance
      expect(@tool.knot_config).to have_structure(
        {
          'database' => { 'storage' => '/var/lib/knot' },
          'log'      => [{ 'any'    => 'info',
                           'target' => 'syslog' }],
          'server'   => { 'listen' => ['127.0.0.1@53', '::1@53'],
                          'rundir' => '/run/knot',
                          'user'   => 'knot:knot' },
          'template' => [{ 'file' => '%s.zone',
                           'id'   => 'default',
          'storage'  => '/var/lib/knot' }]
        }
      )
    end

    it 'a forward zone' do
      expect(@tool.forward_zones).to have_at_least(1).item
    end

    it 'a reverse zone' do
      expect(@tool.reverse_zones).to have_at_least(1).item
    end
  end

  context 'forward zone for example.com' do
    before :example do
      @tool = PalletJack2Knot.instance
      allow(@tool).to receive(:argv).and_return([
        '-w', $EXAMPLE_WAREHOUSE,
        '-o', Dir.tmpdir,
        '-s', 'example-com'
      ])
      @tool.setup
      @tool.process
      @zone = @tool.forward_zones['example.com']
    end

    it 'has a reasonable timestamp' do
      now = Time.now.utc.to_i
      expect(now - 10..now + 10).to cover(@zone.soa.serial)
    end

    it 'has the correct origin' do
      expect(@zone.origin).to eq('example.com.')
    end

    it 'has some records' do
      expect(@zone.records).to have_at_least(2).items
    end
  end

  context 'reverse zone for 192.168.0.0/24' do
    before :example do
      @tool = PalletJack2Knot.instance
      allow(@tool).to receive(:argv).and_return([
        '-w', $EXAMPLE_WAREHOUSE,
        '-o', Dir.tmpdir,
        '-s', 'example-com'
      ])
      @tool.setup
      @tool.process
      @zone = @tool.reverse_zones['0.168.192.in-addr.arpa']
    end

    it 'has a reasonable timestamp' do
      now = Time.now.utc.to_i
      expect(now - 10..now + 10).to cover(@zone.soa.serial)
    end

    it 'has the correct origin' do
      expect(@zone.origin).to eq('0.168.192.in-addr.arpa.')
    end

    it 'has some records' do
      expect(@zone.records).to have_at_least(2).items
    end
  end
end
