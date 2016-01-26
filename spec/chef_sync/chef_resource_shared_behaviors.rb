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

	let(:args) do
		init_args.merge({local_knife: local_knife, remote_knife: remote_knife, dryrun: false})
	end

	it 'has no required action when the local and remote are the same' do
		remote_knife.set_success(local_resource)

		resource = resource_class.new(args)

		action = resource.compare_local_and_remote_versions
		expect(action).to be_a(Symbol)
		expect(action).to eq(:none)
	end

	it 'needs to be updated when the local and remote are different' do
		remote_knife.set_success(remote_resource)

		resource = resource_class.new(args)

		action = resource.compare_local_and_remote_versions
		expect(action).to be_a(Symbol)
		expect(action).to eq(:update)
	end

	it 'needs to be created when the remote does not exist' do
		error = "ERROR: The object you are looking for could not be found"
		remote_knife.set_error(error, 100)

		resource = resource_class.new(args)

		action = resource.compare_local_and_remote_versions
		expect(action).to be_a(Symbol)
		expect(action).to eq(:create)
	end

end
