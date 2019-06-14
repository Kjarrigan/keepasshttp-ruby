# frozen_string_literal: true

Keepasshttp::KeyStore::Plain::PATH = "/tmp/keepasshttp.test.#{rand(1_000_000)}"

RSpec.describe Keepasshttp do
  it 'has a version number' do
    expect(Keepasshttp::VERSION).not_to be nil
  end

  context 'Keepasshttp::KeyStore' do
    let :credentials do
      { id: 'Foo', key: '1234567890' }
    end

    let :changed_credentials do
      { id: 'Bar', key: '0987654321' }
    end

    it 'has a External store' do
      store = Keepasshttp::KeyStore::External
      expect(store.available?).to be(false)

      store = store.new(credentials)

      expect(store.save(changed_credentials)).to be(false)
      expect(store.load).to eq(credentials)
    end

    it 'has a Plain store' do
      store = Keepasshttp::KeyStore::Plain
      expect(store.available?).to be(false)
      store.save(credentials)
      expect(store.available?).to be(true)

      expect(File.read(Keepasshttp::KeyStore::Plain::PATH)).to eq(<<~YAML)
        ---
        :id: Foo
        :key: '1234567890'
      YAML
      expect(store.load).to eq(credentials)
    end

    it 'has an SshAgent store (encrypted Plain)' do
      store = Keepasshttp::KeyStore::SshAgent
      expect(store.available?).to be(false)
      store.save(credentials)
      expect(store.available?).to be(true)

      cfg_file = File.read(Keepasshttp::KeyStore::Plain::PATH)
      expect(cfg_file).to match(/id: Foo/)
      expect(cfg_file).to match(/key:/)
      expect(cfg_file).to_not match(/1234567890/)
      expect(cfg_file).to match(/iv:/)

      expect(store.load).to eq(credentials)
    end

    it 'has an Environment store' do
      store = Keepasshttp::KeyStore::Environment

      expect(store.available?).to be(false)
      ENV['KEEPASSHTTP_TOKEN'] = 'Foo:MTIzNDU2Nzg5MA=='
      expect(store.available?).to be(true)

      expect(store.load).to eq(credentials)

      store.save(changed_credentials)
      expect(store.load).to eq(changed_credentials)
    end
  end

  context 'Client' do
    it 'can login to an opened Keepass' do
      kee = Keepasshttp.connect(key_store: false)
      expect(kee.id).to eq('Test')
    end

    it 'can login to can store the credentials in a key_store' do
      File.delete(Keepasshttp::KeyStore::Plain::PATH)

      kee = Keepasshttp.connect(key_store: :Plain)
      expect(kee.id).to eq('Test')

      kee = Keepasshttp.connect(key_store: :Plain)
      expect(kee.id).to eq('Test')
    end

    it 'can request credentials' do
      kee = Keepasshttp.connect(key_store: :Plain)

      expect(kee.credentials_for('example.com')).to eq(
        [{
          'Login' => 'foo',
          'Name' => 'example.com',
          'Password' => 'secret',
          'Uuid' => 'A3BE9660BC4BDC45B69806D212D933B4'
        }]
      )
    end
  end
end
