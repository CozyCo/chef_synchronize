require_relative '../../spec_helper'
require_relative '../chef_resource_shared_behaviors'

describe 'ChefSync::DataBagItem' do

	before(:all) do
		@resource_class = ChefSync::DataBagItem

		@local_resource = {
			'id': 'fake_dbag',
			'data': {
				'stuff': 'fake data'
			}
		}

		@remote_resource = @local_resource.merge({'data' => {'stuff' => 'different fake data'}})
	end

	let(:init_args) { {name: 'fake_data_bag_item', data_bag: 'fake_data_bag'} }

	it_should_behave_like 'a chef resource'

end