# frozen_string_literal: true

RSpec.describe Keepasshttp do
  it 'has a version number' do
    expect(Keepasshttp::VERSION).not_to be nil
  end

  context 'Keepasshttp::KeyStore' do
    it 'has a External format' do
      ext = Keepasshttp::KeyStore::External.new(id: 'Foo', key: '1234567890')

      expect(ext.available?).to be(true)
      expect(ext.save(id: 'Bar', key: '0987654321')).to be(false)
      expect(ext.load).to eq(
        id: 'Foo', key: '1234567890'
      )
    end

    it 'has a Plain format' do
      expect(Keepasshttp::KeyStore::Plain.available?).to be(true)
      Keepasshttp::KeyStore::Plain.save(id: 'Foo', key: '1234567890')

      expect(File.read(Keepasshttp::KeyStore::Plain::PATH)).to eq(<<~YAML)
        ---
        :id: Foo
        :key: '1234567890'
      YAML

      expect(Keepasshttp::KeyStore::Plain.load).to eq(
        id: 'Foo', key: '1234567890'
      )
    end

    it 'has an SshAgent format (encrypted Plain)' do
      expect(Keepasshttp::KeyStore::SshAgent.available?).to be(true)

      Keepasshttp::KeyStore::SshAgent.save(id: 'Foo', key: '1234567890')

      cfg_file = File.read(Keepasshttp::KeyStore::Plain::PATH)
      expect(cfg_file).to match(/id: Foo/)
      expect(cfg_file).to match(/key:/)
      expect(cfg_file).to_not match(/1234567890/)
      expect(cfg_file).to match(/iv:/)

      expect(Keepasshttp::KeyStore::SshAgent.load).to eq(
        id: 'Foo', key: '1234567890'
      )
    end
  end

  context 'Client' do
    it 'can login to an opened Keepass' do
      kee = Keepasshttp.connect
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
