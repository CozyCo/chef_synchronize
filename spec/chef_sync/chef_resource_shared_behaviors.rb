require_relative '../spec_helper'

RSpec.shared_examples 'a chef resource' do

	before(:all) do
		@resource_class.local_knife = ChefSync::KnifeMock.new(@resource_class.resource_type, :local)
		@resource_class.local_knife.set_success(@local_resource)
		@resource_class.remote_knife = ChefSync::KnifeMock.new(@resource_class.resource_type, :remote)
		@resource_class.dryrun = false
	end

	it 'has no required action when the local and remote are the same' do
		@resource_class.remote_knife.set_success(@local_resource)

		role = @resource_class.new(init_args)

		action = role.compare_local_and_remote_versions
		expect(action).to be_a(Symbol)
		expect(action).to eq(:none)
	end

	it 'needs to be updated when the local and remote are different' do
		@resource_class.remote_knife.set_success(@remote_resource)

		role = @resource_class.new(init_args)

		action = role.compare_local_and_remote_versions
		expect(action).to be_a(Symbol)
		expect(action).to eq(:update)
	end

	it 'needs to be created when the remote does not exist' do
		error = "ERROR: The object you are looking for could not be found"
		@resource_class.remote_knife.set_error(error, 100)

		role = @resource_class.new(init_args)

		action = role.compare_local_and_remote_versions
		expect(action).to be_a(Symbol)
		expect(action).to eq(:create)
	end

end
