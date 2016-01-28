require_relative '../spec_helper'

RSpec.shared_examples 'a chef resource' do

	let(:local_knife) do
		local_knife = ChefSync::KnifeMock.new(resource_class.resource_type, :local)
		local_knife.set_success(local_resource)
		local_knife
	end

	let(:remote_knife) do
		ChefSync::KnifeMock.new(resource_class.resource_type, :remote)
	end

	let(:dryrun_args) do
		init_args.merge({local_knife: local_knife, remote_knife: remote_knife, dryrun: true})
	end

	let(:no_dryrun_args) {dryrun_args.merge({dryrun: false})}

	context 'when the local and remote are the same' do

		it 'has no required action' do
			remote_knife.set_success(local_resource)

			resource = resource_class.new(dryrun_args)
			expect(resource).to receive(:upload_resource).never

			action = resource.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end

	end


	context 'when the local and remote are different' do

		it 'needs to be updated' do
			remote_knife.set_success(remote_resource)

			resource = resource_class.new(dryrun_args)
			expect(resource).to receive(:upload_resource).never

			action = resource.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end

		it 'uploads the changed resource when not in dryrun mode' do
			remote_knife.set_success(remote_resource)

			resource = resource_class.new(no_dryrun_args)
			expect(resource).to receive(:upload_resource)
			resource.sync
		end

	end


	context 'when the remote does not exist' do

		it 'needs to be created' do
			error = "ERROR: The object you are looking for could not be found"
			remote_knife.set_error(error, 100)

			resource = resource_class.new(dryrun_args)
			expect(resource).to receive(:upload_resource).never

			action = resource.sync
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end

		it 'uploads the new resource when not in dryrun mode' do
			error = "ERROR: The object you are looking for could not be found"
			remote_knife.set_error(error, 100)

			resource = resource_class.new(no_dryrun_args)
			expect(resource).to receive(:upload_resource)
			resource.sync
		end

	end

end
