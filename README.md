# Keepasshttp

This is a simple client for https://github.com/pfn/keepasshttp to fetch credentials from your Keepass container from a ruby script.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'keepasshttp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install keepasshttp

## Usage

```ruby
require 'keepasshttp'

keep = Keepasshttp.connect

keep.credentials_for('http://example.com')
```

### KeyStores

With the above code you'll be prompted by your Keepass to enter a label for the new key (because the tool generates a new key every time)
which is shorter that typing your password but still annoying. So I added a (session) key_store. At the moment you can choose between:

  * :Plain - save your key in plaintext - maximum convienience, minimal security
    ```ruby
      Keepasshttp.connect(key_store: :Plain)
    ```
  * :SshAgent - (re)use your running ssh-agent session to encrypt your session key (and then save it to a file)
    ```ruby
      Keepasshttp.connect(key_store: :SshAgent)
    ```
  * { key:, id: } - Do the keymanagement yourself and just input the necessary keys as Hash.
    ```ruby
      Keepasshttp.connect(key_store: { key: 'SECRET', id: 'Foo' })
    ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To see if it works run

```bash
$ keepasshttp URL_THAT_IS_IN_YOUR_KEEPASSDB [OPTS]
```

If it works Keypass will prompt you for a label (which name you pick is irrelevant) and it should print you an json to the shell containing your data.

Example:

```bash
$ keepasshttps http://example.com
[{"Login":"foo","Password":"secret","Uuid":"A3BE9660BC4BDC45B69806D212D933B4","Name":"example.com"}]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Kjarrigan/keepasshttp.
