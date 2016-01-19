require_relative '../../spec_helper'

describe 'ChefSync::Environment' do

	let(:local_env) do
		{
			'name': 'fake_environment',
			'default_attributes': {},
			'override_attributes': {},
			'json_class': 'Chef::Environment',
			'description': 'Fake chef environment.',
			'cookbook_versions': {},
			'chef_type': 'environment'
		}
	end

	let(:local_knife) do
		local_knife = ChefSync::KnifeMock.new('environment', :local)
		local_knife.set_success(local_env)
		return local_knife
	end

	context 'when the local and remote are the same' do
		it 'has no required action' do
			remote_knife = ChefSync::KnifeMock.new('environment', :remote)
			remote_knife.set_success(local_env)

			env = ChefSync::Environment.new('fake_env', false, local_knife, remote_knife)

			action = env.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end
	end

	context 'when the local and remote are different' do
		it 'needs to be updated' do
			remote_env = local_env.merge({'description' => 'This is a different fake environment.'})
			remote_knife = ChefSync::KnifeMock.new('environment', :remote)
			remote_knife.set_success(remote_env)

			env = ChefSync::Environment.new('fake_env', false, local_knife, remote_knife)

			action = env.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end
	end

	context 'when the remote does not exist' do
		it 'needs to be created' do
			error = "ERROR: The object you are looking for could not be found"

			remote_knife = ChefSync::KnifeMock.new('environment', :remote)
			remote_knife.set_error(error, 100)

			env = ChefSync::Environment.new('fake_env', false, local_knife, remote_knife)

			action = env.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end
	end

end