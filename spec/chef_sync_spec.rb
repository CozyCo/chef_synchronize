require 'chef_sync'

describe 'chef_sync' do

	describe 'ChefSync::Environment' do
		context 'when the local and remote are the same' do
			it 'has no required action' do
				env = ChefSync::Environment.new('fancypants')
				allow(env).to receive(:get_local_resource).and_return('badger')
				allow(env).to receive(:get_remote_resource).and_return('badger')

				action = env.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:none)
			end
		end

		context 'when the local and remote are different' do
			it 'needs to be updated' do
				env = ChefSync::Environment.new('fancypants')
				allow(env).to receive(:get_local_resource).and_return('badger')
				allow(env).to receive(:get_remote_resource).and_return('mushroom')

				action = env.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:update)
			end
		end

		context 'when the remote does not exist' do
			it 'needs to be created' do
				env = ChefSync::Environment.new('fancypants')
				allow(env).to receive(:get_local_resource).and_return('badger')
				allow(env).to receive(:get_remote_resource).and_return(nil)

				action = env.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:create)
			end
		end
	end

	describe 'ChefSync::Role' do
		context 'when the local and remote are the same' do
			it 'has no required action' do
				role = ChefSync::Role.new('potato')
				allow(role).to receive(:get_local_resource).and_return('mushroom')
				allow(role).to receive(:get_remote_resource).and_return('mushroom')

				action = role.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:none)
			end
		end

		context 'when the local and remote are different' do
			it 'needs to be updated' do
				role = ChefSync::Role.new('potato')
				allow(role).to receive(:get_local_resource).and_return('mushroom')
				allow(role).to receive(:get_remote_resource).and_return('snake')

				action = role.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:update)
			end
		end

		context 'when the remote does not exist' do
			it 'needs to be created' do
				role = ChefSync::Role.new('potato')
				allow(role).to receive(:get_local_resource).and_return('mushroom')
				allow(role).to receive(:get_remote_resource).and_return(nil)

				action = role.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:create)
			end
		end
	end

	describe 'ChefSync::DataBag' do
		let(:dbag_list) {['rainbows']}

		context 'when local and remote files are the same' do
			it 'has no required action' do
				dbag = ChefSync::DataBag.new('potahto')
				allow(dbag).to receive(:get_local_resource).and_return(dbag_list)
				allow(dbag).to receive(:get_remote_resource).and_return(dbag_list)
				allow(dbag).to receive(:get_local_dbag_file).and_return('unicorns')
				allow(dbag).to receive(:get_remote_dbag_file).and_return('unicorns')

				action = dbag.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:none)
			end
		end

		context 'when local and remote files are different' do
			it 'needs to be updated' do
				dbag = ChefSync::DataBag.new('potahto')
				allow(dbag).to receive(:get_local_resource).and_return(dbag_list)
				allow(dbag).to receive(:get_remote_resource).and_return(dbag_list)
				allow(dbag).to receive(:get_local_dbag_file).and_return('unicorns')
				allow(dbag).to receive(:get_remote_dbag_file).and_return('butterflies')

				action = dbag.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:update)
			end
		end

		context 'when the remote does not exist' do
			it 'needs to be created' do
				dbag = ChefSync::DataBag.new('potahto')
				allow(dbag).to receive(:get_local_resource).and_return(dbag_list)
				allow(dbag).to receive(:get_remote_resource).and_return(dbag_list)
				allow(dbag).to receive(:get_local_dbag_file).and_return('unicorns')
				allow(dbag).to receive(:get_remote_dbag_file).and_return(nil)

				action = dbag.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:update)
			end
		end
	end

	describe 'ChefSync::Cookbook' do
		context 'when the local and remote are the same version number' do
			it 'has no required actions when all files are the same' do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.0')
				allow(cb).to receive(:compare_cookbook_files).and_return([])

				action = cb.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:none)
			end

			it 'needs to be updated when a file is different' do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.0')
				allow(cb).to receive(:compare_cookbook_files).and_return(['spaghetti'])

				action = cb.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:update)
			end

			it 'needs to be created when a file does not exist locally' do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.0')
				allow(cb).to receive(:compare_cookbook_files).and_return('meatballs')

				action = cb.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:update)
			end
		end

		context 'when the local version is newer' do
			it 'needs to be updated' do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.2', '0.1.0')

				action = cb.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:update)
			end
		end

		context 'when the local version is older' do
			it 'returns an error message' do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.2')

				action = cb.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:error)
			end
		end

		context 'when the remote does not exist' do
			it 'needs to be created' do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', nil)

				action = cb.compare_local_and_remote_versions
				expect(action).to be_a(Symbol)
				expect(action).to eq(:create)
			end
		end
	end

end