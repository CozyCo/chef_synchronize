class ChefSync::DataBagItem < ChefSync::ChefResource

	@resource_type = 'data_bag'

	attr_reader :data_bag

	def initialize(dbag, file_name)
		@data_bag = dbag

		super(file_name)
	end

	def self.sync(dryrun=false)
		local_data_bag_list = self.get_local_resource_list
		self.resource_total = local_data_bag_list.count
		action_summary = {}

		local_data_bag_list.each do |dbag|
			local_dbag_items = self.get_local_resource_show_list(dbag)

			local_dbag_items.each do |resource_name|
				resource = self.new(dbag, resource_name)
				action_summary[resource] = resource.sync(dryrun)
			end
		end
		return self.formatted_action_summary(action_summary)
	end

	def self.get_local_resource_show_list(data_bag)
		return ChefSync::Knife.capture(self.knife_show_resource_command, [data_bag, '-z'])
	end

	def resource_path
		return "#{self.class.resource_type}s/#{self.data_bag}/#{self.name}"
	end

	def get_local_resource
		return ChefSync::Knife.capture(self.class.knife_show_resource_command, [self.data_bag, self.name, '-z'])
	end

	def get_remote_resource
		return ChefSync::Knife.capture(self.class.knife_show_resource_command, [self.data_bag, self.name])
	end

	def update_remote_resource
		return ChefSync::Knife.upload(self.class.knife_upload_resource_command, [self.data_bag, self.file_name_with_extension])
	end

end
