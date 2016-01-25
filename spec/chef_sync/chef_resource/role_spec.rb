require_relative '../../spec_helper'
require_relative '../chef_resource_shared_behaviors'

describe 'ChefSync::Role' do

	before(:all) do
		@resource_class = ChefSync::Role

		@local_resource = {
			'name': 'fake_role',
			'default_attributes': {},
			'override_attributes': {},
			'json_class': 'Chef::Role',
			'description': 'Fake chef role.',
			'chef_type': 'role',
			'run_list': [],
			'env_run_lists': {}
		}

		@remote_resource = @local_resource.merge({'description' => 'This is a different fake chef role.'})
	end

	let(:init_args) { {name: 'fake_role'} }

	it_should_behave_like 'a chef resource'

end