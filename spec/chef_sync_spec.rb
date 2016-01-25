require 'spec_helper'

describe 'ChefSync' do

	before(:all) do
		ChefSync::RESOURCE_TYPES.each {|r| r.total_resources = 3}
	end

	it 'has no log when there are are no actionable changes or warnings' do
		ChefSync::RESOURCE_TYPES.each {|r| allow(r).to receive(:changes).and_return([])}

		summ = ChefSync::DRYRUN_MESSAGE.dup
		ChefSync::RESOURCE_TYPES.each do |r|
			summ << "#{r.changes.count}/#{r.total_resources} #{r.resource_type}s have changed. "
		end

		expect(ChefSync.new.run).to eq([summ, []])
	end

	it 'has log entries when there is a change' do
		non_cookbooks = [ChefSync::Role, ChefSync::Environment, ChefSync::DataBagItem]
		non_cookbooks.each {|r| allow(r).to receive(:changes).and_return([])}
		cookbook_warning = 'cookbooks/fake_cookbook is newer than the local version.'
		allow(ChefSync::Cookbook).to receive(:changes).and_return([cookbook_warning])

		summ = ChefSync::DRYRUN_MESSAGE.dup
		ChefSync::RESOURCE_TYPES.each do |r|
			summ << "#{r.changes.count}/#{r.total_resources} #{r.resource_type}s have changed. "
		end

		expect(ChefSync.new.run).to eq([summ, [cookbook_warning]])
	end

end
