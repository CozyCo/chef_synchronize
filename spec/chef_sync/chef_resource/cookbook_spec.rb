require_relative '../../spec_helper'

describe 'ChefSync::Cookbook' do

	let(:local_knife) do
		ChefSync::KnifeMock.new(ChefSync::Cookbook.resource_type, :local)
	end

	let(:remote_knife) do
		ChefSync::KnifeMock.new(ChefSync::Cookbook.resource_type, :remote)
	end

	let(:dryrun_args) do
		{
			name: 'boyardee',
			local_knife: local_knife,
			remote_knife: remote_knife,
			dryrun: true
		}
	end

	let(:no_dryrun_args) {dryrun_args.merge(dryrun: false)}

	context 'when the local and remote are the same version number' do

		let(:args) do
			dryrun_args.merge({local_version_number: '0.1.0', remote_version_number: '0.1.0'})
		end

		it 'has no required actions when all files are the same' do
			cb = ChefSync::Cookbook.new(args)
			expect(cb).to receive(:upload_resource).never
			expect(cb).to receive(:compare_cookbook_files).and_return([])

			action = cb.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end

		it 'needs to be updated when a file is different' do
			cb = ChefSync::Cookbook.new(args)
			expect(cb).to receive(:upload_resource).never
			expect(cb).to receive(:compare_cookbook_files).and_return([{'spaghetti' => :file_changed}])

			action = cb.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_changed)
		end

		it 'needs to be updated when a file does not exist locally' do
			cb = ChefSync::Cookbook.new(args)
			expect(cb).to receive(:upload_resource).never
			expect(cb).to receive(:compare_cookbook_files).and_return([{'meatballs' => :file_missing}])

			action = cb.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_changed)
		end
	end

	context 'when the local version is newer' do

		let(:version_args) { {local_version_number: '0.1.2', remote_version_number: '0.1.0'} }

		it 'needs to be updated' do
			cb = ChefSync::Cookbook.new(dryrun_args.merge(version_args))
			expect(cb).to receive(:upload_resource).never

			action = cb.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end

		it 'uploads the new cookbook version when not in dryrun mode' do
			remote_knife.set_success("")

			cb = ChefSync::Cookbook.new(no_dryrun_args.merge(version_args))
			expect(cb).to receive(:upload_resource)
			cb.sync
		end
	end

	context 'when the local version is older' do
		it 'returns an error message' do
			version_args = {local_version_number: '0.1.0', remote_version_number: '0.1.2'}
			cb = ChefSync::Cookbook.new(dryrun_args.merge(version_args))
			expect(cb).to receive(:upload_resource).never

			action = cb.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:version_regressed)
		end
	end

	context 'when the remote does not exist' do

		let(:version_args) { {local_version_number: '0.1.0', remote_version_number: nil} }

		it 'needs to be created' do
			cb = ChefSync::Cookbook.new(dryrun_args.merge(version_args))
			expect(cb).to receive(:upload_resource).never

			action = cb.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end

		it 'uploads the new cookbook when not in dryrun mode' do
			remote_knife.set_success("")

			cb = ChefSync::Cookbook.new(no_dryrun_args.merge(version_args))
			expect(cb).to receive(:upload_resource)
			cb.sync
		end
	end

end