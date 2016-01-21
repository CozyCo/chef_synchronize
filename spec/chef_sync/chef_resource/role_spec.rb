require_relative '../../spec_helper'

describe 'ChefSync::Role' do

	before(:all) do
		@local_role = {
			'name': 'fake_role',
			'default_attributes': {},
			'override_attributes': {},
			'json_class': 'Chef::Role',
			'description': 'Fake chef role.',
			'chef_type': 'role',
			'run_list': [],
			'env_run_lists': {}
		}

		ChefSync::Role.local_knife = ChefSync::KnifeMock.new('role', :local)
		ChefSync::Role.local_knife.set_success(@local_role)
		ChefSync::Role.remote_knife = ChefSync::KnifeMock.new('role', :remote)
		ChefSync::Role.dryrun = false
	end

	context 'when the local and remote are the same' do
		it 'has no required action' do
			ChefSync::Role.remote_knife.set_success(@local_role)

			role = ChefSync::Role.new(name: 'fake_role')

			action = role.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:none)
		end
	end

	context 'when the local and remote are different' do
		it 'needs to be updated' do
			remote_role = @local_role.merge({'description' => 'This is a different fake chef role.'})
			ChefSync::Role.remote_knife.set_success(remote_role)

			role = ChefSync::Role.new(name: 'fake_role')

			action = role.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:update)
		end
	end

	context 'when the remote does not exist' do
		it 'needs to be created' do
			error = "ERROR: The object you are looking for could not be found"
			ChefSync::Role.remote_knife.set_error(error, 100)

			role = ChefSync::Role.new(name: 'fake_role')

			action = role.compare_local_and_remote_versions
			expect(action).to be_a(Symbol)
			expect(action).to eq(:create)
		end
	end

end