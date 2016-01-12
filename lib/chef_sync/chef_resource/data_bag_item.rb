class DataBagItem < ChefSync::ChefResource

	@resource_type = 'data_bag'

	attr_reader :file_name

	def initialize(name, file_name)
		@file_name = file_name

		super(name)
	end

	def self.sync
		local_data_bag_list = self.get_local_resource_list
		all_required_actions = {}

		local_data_bag_list.each do |dbag|
			local_dbag_items = self.get_local_resource_show_list(dbag)

			local_dbag_items.each do |resource_name|
				resource = self.new(dbag, resource_name)
				file_location = "#{resource.name}/#{resource.file_name}"
				all_required_actions[file_location] = resource.compare_local_and_remote_versions
			end
		end
		return all_required_actions
	end

	def self.get_local_resource_show_list(dbag)
		return self.get_formatted_knife_data(:data_bag_show, [dbag, '-z'])
	end

	def resource_path
		return "#{self.class.resource_type}s/#{self.name}/#{self.file_name}"
	end

	def get_local_resource
		return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, self.file_name, '-z'])
	end

	def get_remote_resource
		return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, self.file_name])
	end

	def compare_local_and_remote_versions
		local_data_bag = self.get_local_resource
		remote_data_bag = self.get_remote_resource

		case
		when !remote_data_bag
			self.required_action = :create
		when local_data_bag != remote_data_bag
			self.required_action = :update
		end
		return self.required_action
	end

end
