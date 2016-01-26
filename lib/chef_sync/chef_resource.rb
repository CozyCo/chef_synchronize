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

		attr_reader :change

		def initialize(name:, local_knife:, remote_knife:, dryrun:)
			@name = name
			@name_with_extension = name + FILE_EXTENSION

			@local_knife = local_knife
			@remote_knife = remote_knife
			@dryrun = dryrun

			@change = :none
		end

		def self.each
			local_knife = self.make_local_knife
			remote_knife = self.make_remote_knife

			local_resources = self.get_local_resources(local_knife, remote_knife)
			self.total_resources = local_resources.count

			default_args = {local_knife: local_knife, remote_knife: remote_knife, dryrun: self.dryrun}
			local_resources.tqdm(leave: true, desc: "Checking #{self.resource_type}s").each do |args|
				resource = self.new(args.merge(default_args))
				resource.sync
				yield resource
			end
		end

		def self.changes(dryrun)
			self.dryrun = dryrun

			return self.select(&:changed?).flat_map(&:summarize_changes)
		end

		def self.get_local_resources(local_knife, remote_knife)
			local_resources = local_knife.list
			return local_resources.map {|resource_name| {name: resource_name}}
		end

		def self.make_local_knife
			return ChefSync::Knife.new(self.resource_type, :local)
		end

		def self.make_remote_knife
			return ChefSync::Knife.new(self.resource_type, :remote)
		end

		def changed?
			return @change != :none
		end

		def actionable_change?
			return ACTIONABLE_CHANGES.include?(@change)
		end

		def summarize_changes
			return self.resource_path + CHANGE_LOG_SUMMARIES[@change]
		end

		def resource_path
			return "#{self.class.resource_type}s/#{@name}"
		end

		def get_local_resource
			return @local_knife.show(@name)
		end

		def get_remote_resource
			return @remote_knife.show(@name)
		end

		def upload_resource
			return @remote_knife.upload(@name_with_extension)
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
			if !@dryrun and self.actionable_change?
				self.upload_resource
			end
			return action
		end

	end
end
