require_relative '../../spec_helper'
require_relative '../chef_component_shared_behaviors'

describe 'ChefSync::DataBagItem' do

	let(:resource_class) {ChefSync::DataBagItem}

	let(:local_resource) do
		{
			'id': 'fake_dbag',
			'data': {
				'stuff': 'fake data'
			}
		}
	end

	let(:remote_resource) do
		local_resource.merge({'data' => {'stuff' => 'different fake data'}})
	end

	let(:init_args) { {name: 'fake_data_bag_item', data_bag: 'fake_data_bag'} }

	it_should_behave_like 'a chef resource'

end