class ChefSync
	class ChefResource

		CHANGE_LOG_SUMMARIES = {
			:create => " was created.",
			:update => " was updated."
		}

		ACTIONABLE_CHANGES = [:create, :update]

		FILE_EXTENSION = ".json"

		class << self; attr_reader :resource_type end
		@resource_type = ''

		class << self; attr_accessor :resource_total end
		@resource_total = 0

		attr_reader :name
		attr_accessor :change

		def initialize(name)
			@name = name
			@change = :none
		end

		def self.sync(dryrun=false)
			local_resource_list = self.get_local_resource_list
			self.resource_total = local_resource_list.count
			action_summary = {}

			local_resource_list.each do |resource_name|
				resource = self.new(resource_name)
				action_summary[resource] = resource.sync(dryrun)
			end
			return self.formatted_action_summary(action_summary)
		end

		def self.formatted_action_summary(action_summary)
			changed_resources = action_summary.reject {|resource, action| action == :none}
			output = []

			changed_resources.each do |resource, action|
				output << resource.resource_path + CHANGE_LOG_SUMMARIES[action]
			end
			return output
		end

		def self.get_local_resource_list
			return ChefSync::Knife.capture(self.knife_list_resource_command, ['-z'])
		end

		def self.knife_list_resource_command
			return "#{self.resource_type}_list".to_sym
		end

		def self.knife_show_resource_command
			return "#{self.resource_type}_show".to_sym
		end

		def self.knife_upload_resource_command
			return "#{self.resource_type}_from_file".to_sym
		end

		def resource_path
			return "#{self.class.resource_type}s/#{self.name}"
		end

		def file_name_with_extension
			return self.name + FILE_EXTENSION
		end

		def get_local_resource
			return ChefSync::Knife.capture(self.class.knife_show_resource_command, [self.name, '-z'])
		end

		def get_remote_resource
			return ChefSync::Knife.capture(self.class.knife_show_resource_command, [self.name])
		end

		def upload_remote_resource
			return ChefSync::Knife.upload(self.class.knife_upload_resource_command, [self.file_name_with_extension])
		end

		def compare_local_and_remote_versions
			local_resource = self.get_local_resource
			remote_resource = self.get_remote_resource

			case
			when !remote_resource
				self.change = :create
			when local_resource != remote_resource
				self.change = :update
			end

			return self.change
		end

		def sync(dryrun)
			action = self.compare_local_and_remote_versions
			if !dryrun and ACTIONABLE_CHANGES.include?(self.change)
				self.upload_remote_resource
			end
			return action
		end

	end
end
