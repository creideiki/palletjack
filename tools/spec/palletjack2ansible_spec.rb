# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

load 'palletjack2ansible'

describe 'palletjack2ansible' do
  context 'generated host inventory' do
    before :each do
      @tool = PalletJack2Ansible.instance
      allow(@tool).to receive(:argv).and_return(
        ['-w', $EXAMPLE_WAREHOUSE,
         '-d', Dir.tmpdir]) # Won't actually be written to, but needs
                            # to exist to make the command line option
                            # parser happy
      @tool.setup
      @tool.process
      @inventory = @tool.ansible_config[:inventory]
    end

    it 'contains the global group' do
      all_hosts = { 'all' => { 'hosts' => Hash } }
      expect(@inventory).to have_structure all_hosts
    end

    it 'contains all hosts in the warehouse' do
      @tool.jack.each(kind: 'system') do |system|
        expect(@inventory['all']['hosts']).to include system['net.dns.fqdn']
      end
    end

    it 'has no configuration embedded in the inventory' do
      expect(@inventory['all']['hosts'].values).to all(be_nil)
    end
  end

  context 'generated global configuration' do
    before :each do
      @tool = PalletJack2Ansible.instance
      allow(@tool).to receive(:argv).and_return(
        ['-w', $EXAMPLE_WAREHOUSE,
         '-d', Dir.tmpdir]) # Won't actually be written to, but needs
                            # to exist to make the command line option
                            # parser happy
      @tool.setup
      @tool.process
      @global = @tool.ansible_config[:global]
    end

    it 'contains configuration for os images' do
      os_vars = { 'host' => { 'netinstall' => Hash,
                              'pxelinux' => Hash },
                  'system' => Hash }
      @tool.jack.each(kind: 'os') do |os|
        expect(@global['os'][os.full_name]).to have_structure(os_vars)
      end
    end

    it 'contains configuration for netinstall configurations' do
      ni_vars = { 'host' => { 'netinstall' => Hash,
                              'pxelinux' => Hash },
                  'system' => Hash }
      @tool.jack.each(kind: 'netinstall') do |ni|
        next unless ni.children(kind: 'netinstall').empty?

        expect(@global['netinstall'][ni.full_name]).to have_structure(ni_vars)
      end
    end
  end

  context 'generated host variables' do
    before :each do
      @tool = PalletJack2Ansible.instance
      allow(@tool).to receive(:argv).and_return(
        ['-w', $EXAMPLE_WAREHOUSE,
         '-d', Dir.tmpdir]) # Won't actually be written to, but needs
                            # to exist to make the command line option
                            # parser happy
      @tool.setup
      @tool.process
      @hosts = @tool.ansible_config[:hosts]
    end

    it 'contains configuration for some known clients' do
      basic_structure = { 'palletjack' => Hash }
      expect(@hosts['vmhost1.example.com']).to have_structure(basic_structure)
      expect(@hosts['testvm.example.com']).to have_structure(basic_structure)
    end

    it 'contains configuration for all clients in the warehouse' do
      hosts = {}
      @tool.jack.each(kind: 'system') do |system|
        hosts[system['net.dns.fqdn']] = { 'palletjack' => Hash }
      end
      expect(@hosts).to have_structure(hosts)
    end

    it 'contains network configuration' do
      interfaces =
      {
        'em1' =>
        {
          '192.168.0.1' =>
          {
            'net' =>
            {
              'ipv4' =>
              {
                'gateway' => '192.168.0.1',
                'prefixlen' => '24',
                'cidr' => '192.168.0.0/24',
                'address' => '192.168.0.1'
              },
              'layer2' =>
              {
                'address' => '14:18:77:ab:cd:ef',
                'name' => 'em1'
              }
            }
          }
        }
      }
      expect(@hosts['vmhost1.example.com']['palletjack']['ipv4_interfaces']).to have_structure(interfaces)
    end

    it 'contains system configuration' do
      system =
      {
        'os' => 'CentOS-7.4.1708-x86_64',
        'architecture' => 'x86_64',
        'role' => ['kvm-server', 'ssh-server'],
        'name' => 'vmhost1'
      }
      expect(@hosts['vmhost1.example.com']['palletjack']['system']).to have_structure(system)
    end

    context 'contains service configuration' do
      it 'for syslog' do
        syslog_config =
        [
          {
            'address' => 'syslog-archive.example.com',
            'port' => '514',
            'protocol' => 'udp'
          },
          {
            'address' => 'logstash.example.com',
            'port' => '5514',
            'protocol' => 'tcp'
          }
        ]
        0.upto(syslog_config.length) do |i|
          expect(@hosts['vmhost1.example.com']['palletjack']['service']['syslog'][i]).to have_structure(syslog_config[i])
        end
      end

      it 'for zabbix' do
        zabbix_config =
        [
          { 'address' => 'zabbix.example.com' },
          {
            'address' => 'zabbix2',
            'port' => '10051'
          }
        ]
        0.upto(zabbix_config.length) do |i|
          expect(@hosts['vmhost1.example.com']['palletjack']['service']['zabbix'][i]).to have_structure(zabbix_config[i])
        end
      end
    end
  end
end
