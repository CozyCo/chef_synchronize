require_relative '../../spec_helper'

describe 'ChefSync::Environment' do

	before(:all) do
		@local_env = {
			'name': 'fake_environment',
			'default_attributes': {},
			'override_attributes': {},
			'json_class': 'Chef::Environment',
			'description': 'Fake chef environment.',
			'cookbook_versions': {},
			'chef_type': 'environment'
		}

		ChefSync::Environment.local_knife = ChefSync::KnifeMock.new('environment', :local)
		ChefSync::Environment.local_knife.set_success(@local_env)
		ChefSync::Environment.remote_knife = ChefSync::KnifeMock.new('environment', :remote)
		ChefSync::Environment.dryrun = false
	end

	context 'when the local and remote are the same' do
		it 'has no required action' do
			ChefSync::Environment.remote_knife.set_success(@local_env)

			env = ChefSync::Environment.new(name: 'fake_env')

			action = env.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end
	end

	context 'when the local and remote are different' do
		it 'needs to be updated' do
			remote_env = @local_env.merge({'description' => 'This is a different fake environment.'})
			ChefSync::Environment.remote_knife.set_success(remote_env)

			env = ChefSync::Environment.new(name: 'fake_env')

			action = env.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end
	end

	context 'when the remote does not exist' do
		it 'needs to be created' do
			error = "ERROR: The object you are looking for could not be found"
			ChefSync::Environment.remote_knife.set_error(error, 100)

			env = ChefSync::Environment.new(name: 'fake_env')

			action = env.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end
	end

end