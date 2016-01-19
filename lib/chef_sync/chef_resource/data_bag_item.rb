class ChefSync::DataBagItem < ChefSync::ChefResource

	@resource_type = 'data_bag'

	attr_reader :data_bag

	def initialize(dbag, *args)
		@data_bag = dbag
		super(*args)
	end

	def self.sync(dryrun)
		local_knife = ChefSync::Knife.new(self.resource_type, :local)
		remote_knife = ChefSync::Knife.new(self.resource_type, :remote)

		local_data_bag_list = local_knife.list
		self.resource_total = local_data_bag_list.count
		action_summary = {}

		local_data_bag_list.each do |dbag|
			local_dbag_items = local_knife.show(dbag)

			local_dbag_items.each do |resource_name|
				resource = self.new(dbag, resource_name, dryrun, local_knife, remote_knife)
				action_summary[resource] = resource.sync
			end
		end
		return self.formatted_action_summary(action_summary)
	end

	def resource_path
		return "#{self.class.resource_type}s/#{self.data_bag}/#{self.name}"
	end

	def get_resource(knife)
		return knife.show(self.data_bag, self.name)
	end

	def upload_resource
		return self.remote_knife.upload(self.data_bag, self.name_with_extension)
	end

end
