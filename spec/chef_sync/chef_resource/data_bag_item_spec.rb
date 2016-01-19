require_relative '../../spec_helper'

describe 'ChefSync::DataBagItem' do

	let(:local_dbag_file) do
		{
			'id': 'fake_dbag',
			'data': {
				'stuff': 'fake data'
			}
		}
	end

	let(:local_knife) do
		local_knife = ChefSync::KnifeMock.new('data_bag', :local)
		local_knife.set_success(local_dbag_file)
		return local_knife
	end

	context 'when local and remote files are the same' do
		it 'has no required action' do
			remote_knife = ChefSync::KnifeMock.new('data_bag', :remote)
			remote_knife.set_success(local_dbag_file)

			dbag = ChefSync::DataBagItem.new('fake_dbag', 'fake_dbag_file', false, local_knife, remote_knife)

			action = dbag.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end
	end

	context 'when local and remote files are different' do
		it 'needs to be updated' do
			remote_dbag_file = local_dbag_file.merge({'data' => {'stuff' => 'different fake data'}})
			remote_knife = ChefSync::KnifeMock.new('data_bag', :remote)
			remote_knife.set_success(remote_dbag_file)

			dbag = ChefSync::DataBagItem.new('fake_dbag','fake_dbag_file', false, local_knife, remote_knife)

			action = dbag.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end
	end

	context 'when the remote does not exist' do
		it 'needs to be created' do
			error = "ERROR: The object you are looking for could not be found"

			remote_knife = ChefSync::KnifeMock.new('data_bag', :remote)
			remote_knife.set_error(error, 100)

			dbag = ChefSync::DataBagItem.new('fake_dbag', 'fake_dbag_file', false, local_knife, remote_knife)

			action = dbag.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end
	end

end