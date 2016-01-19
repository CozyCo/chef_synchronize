require_relative '../../spec_helper'

describe 'ChefSync::Cookbook' do

	let(:local_knife) {ChefSync::KnifeMock.new('cookbook', :local)}
	let(:remote_knife) {ChefSync::KnifeMock.new('cookbook', :remote)}

	context 'when the local and remote are the same version number' do
		it 'has no required actions when all files are the same' do
			cb = ChefSync::Cookbook.new('0.1.0', '0.1.0', 'boyardee', true, local_knife, remote_knife)
			allow(cb).to receive(:compare_cookbook_files).and_return([])

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end

		it 'needs to be updated when a file is different' do
			cb = ChefSync::Cookbook.new('0.1.0', '0.1.0', 'boyardee', true, local_knife, remote_knife)
			allow(cb).to receive(:compare_cookbook_files).and_return([{'spaghetti' => :file_changed}])

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_changed)
		end

		it 'needs to be updated when a file does not exist locally' do
			cb = ChefSync::Cookbook.new('0.1.0', '0.1.0', 'boyardee', true, local_knife, remote_knife)
			allow(cb).to receive(:compare_cookbook_files).and_return([{'meatballs' => :file_missing}])

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_changed)
		end
	end

	context 'when the local version is newer' do
		it 'needs to be updated' do
			cb = ChefSync::Cookbook.new('0.1.2', '0.1.0', 'boyardee', true, local_knife, remote_knife)

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end
	end

	context 'when the local version is older' do
		it 'returns an error message' do
			cb = ChefSync::Cookbook.new('0.1.0', '0.1.2', 'boyardee', true, local_knife, remote_knife)

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_regressed)
		end
	end

	context 'when the remote does not exist' do
		it 'needs to be created' do
			cb = ChefSync::Cookbook.new('0.1.0', nil, 'boyardee', true, local_knife, remote_knife)

			action = cb.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end
	end

end