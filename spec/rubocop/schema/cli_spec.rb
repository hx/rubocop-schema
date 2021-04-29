require 'tmpdir'

describe RuboCop::Schema::CLI do
  subject { described_class.new RuboCop::Schema::ROOT, {}, [], home, out_file: stdout, log_file: stderr }

  around do |ex|
    Dir.mktmpdir do |dir|
      home << dir
      ex.run
    end
  end

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  let(:home) { '' }

  let(:logs) { stderr.string }
  let(:result) { stdout.string }

  it 'makes us something resembling a schema', vcr: { cassette_name: 'cli' } do
    subject.run

    expect(logs).to match /\.{10}/
    expect(logs).to match /Complete in \d+(?:\.\d+)?s/

    schema = JSON.parse(result)
    expect(schema).to be_a Hash
  end
end
