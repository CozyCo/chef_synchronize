require_relative '../../spec_helper'
require_relative '../chef_resource_shared_behaviors'

describe 'ChefSync::Environment' do

	before(:all) do
		@resource_class = ChefSync::Environment

		@local_resource = {
			'name': 'fake_environment',
			'default_attributes': {},
			'override_attributes': {},
			'json_class': 'Chef::Environment',
			'description': 'Fake chef environment.',
			'cookbook_versions': {},
			'chef_type': 'environment'
		}

		@remote_resource = @local_resource.merge({'description' => 'This is a different fake environment.'})
	end

	let(:init_args) { {name: 'fake_environment'} }

	it_should_behave_like 'a chef resource'

end