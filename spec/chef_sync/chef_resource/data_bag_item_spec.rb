require_relative '../../spec_helper'

describe 'ChefSync::DataBagItem' do

	before(:all) do
		@local_dbag_file = {
			'id': 'fake_dbag',
			'data': {
				'stuff': 'fake data'
			}
		}

		ChefSync::DataBagItem.local_knife = ChefSync::KnifeMock.new('data_bag', :local)
		ChefSync::DataBagItem.local_knife.set_success(@local_dbag_file)
		ChefSync::DataBagItem.remote_knife = ChefSync::KnifeMock.new('data_bag', :remote)
		ChefSync::DataBagItem.dryrun = false
	end

	let(:local_knife) do
		local_knife = ChefSync::KnifeMock.new('data_bag', :local)
		local_knife.set_success(local_dbag_file)
		return local_knife
	end

	context 'when local and remote files are the same' do
		it 'has no required action' do
			ChefSync::DataBagItem.remote_knife.set_success(@local_dbag_file)

			dbag = ChefSync::DataBagItem.new(data_bag: 'fake_dbag', name: 'fake_dbag_file')

			action = dbag.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end
	end

	context 'when local and remote files are different' do
		it 'needs to be updated' do
			remote_dbag_file = @local_dbag_file.merge({'data' => {'stuff' => 'different fake data'}})
			ChefSync::DataBagItem.remote_knife.set_success(remote_dbag_file)

			dbag = ChefSync::DataBagItem.new(data_bag: 'fake_dbag', name: 'fake_dbag_file')

			action = dbag.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end
	end

	context 'when the remote does not exist' do
		it 'needs to be created' do
			error = "ERROR: The object you are looking for could not be found"
			ChefSync::DataBagItem.remote_knife.set_error(error, 100)

			dbag = ChefSync::DataBagItem.new(data_bag: 'fake_dbag', name: 'fake_dbag_file')

			action = dbag.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end
	end

end