# frozen_string_literal: true

RSpec.describe Keepasshttp do
  it 'has a version number' do
    expect(Keepasshttp::VERSION).not_to be nil
  end

  context 'Keepasshttp::KeyStore' do
    it 'has a Plain format' do
      expect(Keepasshttp::KeyStore::Plain.available?).to be(true)
      Keepasshttp::KeyStore::Plain.save(id: 'Foo', key: '1234567890')

      expect(File.read(Keepasshttp::KeyStore::Plain::PATH)).to eq(<<~YAML)
        ---
        :id: Foo
        :key: '1234567890'
      YAML
    end

    it 'can load from Plain' do
      expect(Keepasshttp::KeyStore::Plain.load).to eq(
        id: 'Foo', key: '1234567890'
      )
    end
  end
end
