require 'tqdm'

class ChefSync
	class ChefResource

		extend Enumerable

		CHANGE_LOG_SUMMARIES = {
			:create => " was created.",
			:update => " was updated."
		}

		ACTIONABLE_CHANGES = [:create, :update]

		FILE_EXTENSION = ".json"

		class << self; attr_reader :resource_type end
		class << self; attr_accessor :total_resources end
		class << self; attr_accessor :dryrun end
		class << self; attr_accessor :local_knife end
		class << self; attr_accessor :remote_knife end

		attr_reader :change

		def initialize(name:)
			@name = name
			@name_with_extension = name + FILE_EXTENSION

			@change = :none
		end

		def self.each
			self.local_knife = ChefSync::Knife.new(self.resource_type, :local)
			self.remote_knife = ChefSync::Knife.new(self.resource_type, :remote)

			local_resources = self.get_local_resources
			self.total_resources = local_resources.count

			local_resources.tqdm(leave: true, desc: "Checking #{self.resource_type}s").each do |args|
				resource = self.new(args)
				resource.sync
				yield resource
			end
		end

		def self.changes(dryrun)
			self.dryrun = dryrun

			return self.reject {|resource| resource.change == :none}.map do |resource|
				resource.resource_path + CHANGE_LOG_SUMMARIES[resource.change]
			end
		end

		def self.get_local_resources
			local_resources = self.local_knife.list
			return local_resources.map {|resource_name| {name: resource_name}}
		end

		def self.actionable_change?(action)
			return ACTIONABLE_CHANGES.include?(action)
		end

		def resource_path
			return "#{self.class.resource_type}s/#{@name}"
		end

		def get_local_resource
			return self.class.local_knife.show(@name)
		end

		def get_remote_resource
			return self.class.remote_knife.show(@name)
		end

		def upload_resource
			return self.class.remote_knife.upload(@name_with_extension)
		end

		def compare_local_and_remote_versions
			local_resource = self.get_local_resource
			remote_resource = self.get_remote_resource

			case
			when remote_resource.empty?
				@change = :create
			when local_resource != remote_resource
				@change = :update
			end

			return @change
		end

		def sync
			action = self.compare_local_and_remote_versions
			if !self.class.dryrun and self.class.actionable_change?(@change)
				self.upload_resource
			end
			return action
		end

	end
end
