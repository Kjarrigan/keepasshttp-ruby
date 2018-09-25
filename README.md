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

```
require 'keepass'

keep = Keepass.connect

keep.password_for('http://example.com')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To see if it works run

```bash
$ keepasshttp URL_THAT_IS_IN_YOUR_KEEPASSDB
```

If it works Keypass will prompt you for a label (which name you pick is irrelevant) and it should print you an json to the shell containing your data.

Example:

```bash
$ keepasshttps http://example.com
[{"Login":"foo","Password":"secret","Uuid":"A3BE9660BC4BDC45B69806D212D933B4","Name":"example.com"}]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Kjarrigan/keepasshttp.
