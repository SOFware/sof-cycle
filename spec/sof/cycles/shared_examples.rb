# frozen_string_literal: true

shared_examples_for "#kind returns" do |expected|
  it "returns the correct kind" do
    expect(subject.kind).to eq(expected)
    expect(subject.public_send(:"#{expected}?")).to be true
  end
end

shared_examples_for "#valid_periods are" do |expected|
  it "returns the correct periods" do
    expect(subject.valid_periods).to match_array(expected)
  end
end

shared_examples_for "#to_s returns" do |expected|
  it "returns the correct string" do
    expect(subject.to_s).to eq(expected)
  end
end

shared_examples_for "#volume returns the volume" do
  it "returns the volume from the notation" do
    volume = notation.match(/V(\d+)/)[1].to_i
    expect(subject.volume).to eq(volume)
  end
end

shared_examples_for "#notation returns the notation" do
  it "returns the notation" do
    expect(subject.notation).to eq(notation)
  end
end

shared_examples_for "#as_json returns the notation" do
  it "returns the notation" do
    expect(subject.as_json).to eq(notation)
  end
end

shared_examples_for "it computes #final_date(given)" do |given:, returns:|
  it "returns the correct date" do
    expect(subject.final_date(given)).to eq(returns)
  end
end

shared_examples_for "last_completed is" do |symbol|
  it "returns the correct date" do
    expected = send(symbol)
    dates = completed_dates + [nil, "1999-01-01"]
    expect(subject.last_completed(dates)).to eq(expected)
  end
end

shared_examples_for "it cannot be extended" do
  it "returns itself" do
    expect(subject.extend_period(999)).to eq(subject)
  end
end
