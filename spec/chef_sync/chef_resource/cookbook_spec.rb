require_relative '../../spec_helper'

describe 'ChefSync::Cookbook' do

	let(:local_knife) do
		ChefSync::KnifeMock.new(ChefSync::Cookbook.resource_type, :local)
	end

	let(:remote_knife) do
		ChefSync::KnifeMock.new(ChefSync::Cookbook.resource_type, :remote)
	end

	let(:default_args) do
		{
			name: 'boyardee',
			local_knife: local_knife,
			remote_knife: remote_knife,
			dryrun: false
		}
	end

	context 'when the local and remote are the same version number' do

		let(:version_args) { {local_version_number: '0.1.0', remote_version_number: '0.1.0'} }

		it 'has no required actions when all files are the same' do
			cb = ChefSync::Cookbook.new(default_args.merge(version_args))
			allow(cb).to receive(:compare_cookbook_files).and_return([])

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end

		it 'needs to be updated when a file is different' do
			cb = ChefSync::Cookbook.new(default_args.merge(version_args))
			allow(cb).to receive(:compare_cookbook_files).and_return([{'spaghetti' => :file_changed}])

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_changed)
		end

		it 'needs to be updated when a file does not exist locally' do
			cb = ChefSync::Cookbook.new(default_args.merge(version_args))
			allow(cb).to receive(:compare_cookbook_files).and_return([{'meatballs' => :file_missing}])

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_changed)
		end
	end

	context 'when the local version is newer' do
		it 'needs to be updated' do
			version_args = {local_version_number: '0.1.2', remote_version_number: '0.1.0'}
			cb = ChefSync::Cookbook.new(default_args.merge(version_args))

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end
	end

	context 'when the local version is older' do
		it 'returns an error message' do
			version_args = {local_version_number: '0.1.0', remote_version_number: '0.1.2'}
			cb = ChefSync::Cookbook.new(default_args.merge(version_args))

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_regressed)
		end
	end

	context 'when the remote does not exist' do
		it 'needs to be created' do
			version_args = {local_version_number: '0.1.0', remote_version_number: nil}
			cb = ChefSync::Cookbook.new(default_args.merge(version_args))

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end
	end

end