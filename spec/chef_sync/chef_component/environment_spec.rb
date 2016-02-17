require_relative '../../spec_helper'
require_relative '../chef_component_shared_behaviors'

describe 'ChefSync::Environment' do

	let(:resource_class) {ChefSync::Environment}

	let(:local_resource) do
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

	let(:remote_resource) do
		local_resource.merge({'description' => 'This is a different fake environment.'})
	end

	let(:init_args) { {name: 'fake_environment'} }

	it_should_behave_like 'a chef resource'

end