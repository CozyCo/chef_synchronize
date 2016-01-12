class DataBag < ChefSync::ChefResource

	@resource_type = 'data_bag'

	def get_local_resource
		return self.class.get_formatted_knife_data(:data_bag_show, [self.name, '-z'])
	end

	def get_remote_resource
		return self.class.get_formatted_knife_data(:data_bag_show, [self.name])
	end

	def get_local_dbag_file(file)
		return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, file, '-z'])
	end

	def get_remote_dbag_file(file)
		return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, file])
	end

	def compare_local_and_remote_versions
		local_data_bag = self.get_local_resource
		remote_data_bag = self.get_remote_resource

		case
		when !remote_data_bag
			self.required_action = :create
		when local_data_bag != remote_data_bag
			self.required_action = :update
		when local_data_bag == remote_data_bag
			self.required_action = :update unless self.compare_data_bag_files.empty?
		end

		self.required_action = :update unless self.detailed_action_list.empty?
		return self.required_action
	end

	def compare_data_bag_files
		data_bag_files = self.get_local_resource

		data_bag_files.each do |file|
			local_file = self.get_local_dbag_file(file)
			remote_file = self.get_remote_dbag_file(file)

			file_path = "#{self.resource_path}/#{file}"
			file_action = {:path => file_path, :action => :none}

			case
			when !remote_file
				file_action[:action] = :create
			when local_file != remote_file
				file_action[:action] = :update
			end
			self.detailed_action_list << file_action if file_action[:action] != :none
		end
		return self.detailed_action_list
	end

end
