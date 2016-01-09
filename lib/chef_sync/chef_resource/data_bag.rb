class DataBag < ChefResource

	@resource_type = 'data_bag'

	def get_local_resource_show_list
		return self.class.get_formatted_knife_data(:data_bag_show, [self.name, '-z'])
	end

	def get_local_resource(dbag_file)
		return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, dbag_file, '-z'])
	end

	def get_remote_resource(dbag_file)
		return self.class.get_formatted_knife_data(self.class.knife_show_resource_command, [self.name, dbag_file])
	end

	def compare_local_and_remote_versions
		data_bag_files = self.get_local_resource_show_list

		data_bag_files.each do |file|
			local_resource = self.get_local_resource(file)
			remote_resource = self.get_remote_resource(file)
			file_path = "#{self.resource_path}/#{file}"

			case
			when local_resource != remote_resource
				return "#{file_path} should be uploaded to the chef server."
			when !remote_resource
				return "#{file_path} is new and should be uploaded to the chef server."
			end
		end
		return nil
	end

end
