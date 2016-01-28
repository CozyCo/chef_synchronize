require_relative '../spec_helper'

describe 'ChefSync::ChefResource' do

	let(:local_knife_list) {['badger', 'mushroom', 'snake']}

	let(:local_knife) do
		local_knife = ChefSync::KnifeMock.new(ChefSync::ChefResourceMock.resource_type, :local)
		local_knife.set_success(local_knife_list)
		local_knife
	end

	it 'creates an array of formatted summary strings for its resources' do
		expect(ChefSync::ChefResourceMock).to receive(:make_local_knife).and_return(local_knife)
		expect(ChefSync::ChefResourceMock).to receive(:make_remote_knife).and_return(local_knife)

		result = ChefSync::ChefResourceMock.changes(true)

		expect(result.count).to eq(3)
		expect(result.first).to include(local_knife_list.first)
		expect(result.last).to include(local_knife_list.last)
		expect(result).to all(include('was updated.'))
	end

	it 'creates an instance for each local resource and syncs them' do
		expect(ChefSync::ChefResourceMock).to receive(:make_local_knife).and_return(local_knife)
		expect(ChefSync::ChefResourceMock).to receive(:make_remote_knife).and_return(local_knife)

		enum = ChefSync::ChefResourceMock.each(true)
		resources = [enum.next, enum.next, enum.next]

		expect(resources.count).to eq(3)
		expect(resources.map(&:name)).to eq(local_knife_list)
		expect(resources.map(&:sync_called?)).to all(be_truthy)
	end

end
