# RuboCop Config Schema Generator

This gem generates a JSON schema for your RuboCop configuration files, which you can use in your IDE (e.g. RubyMine) for autocompletion and validation.

## Installation

    $ gem install rubocop-schema-gem

## Usage

Change to a directory containing a `Gemfile.lock`, which the generator will use to target your version of `rubocop`, and any extensions you may be using (e.g. `rubocop-rails`).

```
$ cd ./my_project
$ rubocop-schema-gen
Generating rubocop-1.13.1-config-schema.json … complete in 5.2s
```

The name of the generated file is based on your gem version(s). You can override it with an argument.

```
$ rubocop-schema-gen rubocop-schema.json
Generating rubocop-schema.json … complete in 0.7s
```

Pass `-` to write to standard output.

The generator caches pages from https://raw.githubusercontent.com/rubocop in `~/.rubocop-schema-cache`.

Please refer to your IDE's documentation regarding applying the schema to your `.rubocop.yml` file.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hx/rubocop-schema. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hx/rubocop-schema/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
