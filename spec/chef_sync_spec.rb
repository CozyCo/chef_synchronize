require 'chef_sync'

describe 'chef_sync' do

	describe 'ChefSync::Environment' do
		context 'when the local and remote are the same' do
			it "doesn't have any required actions" do
				env = ChefSync::Environment.new('fancypants')
				allow(env).to receive(:get_local_resource).and_return('badger')
				allow(env).to receive(:get_remote_resource).and_return('badger')

				expect(env.compare_local_and_remote_versions).to be_nil
			end
		end

		context 'when the local and remote are different' do
			it "has required actions" do
				env = ChefSync::Environment.new('fancypants')
				allow(env).to receive(:get_local_resource).and_return('badger')
				allow(env).to receive(:get_remote_resource).and_return('mushroom')

				expect(env.compare_local_and_remote_versions).to be_a(String)
			end
		end

		context 'when the remote does not exist' do
			it "has required actions" do
				env = ChefSync::Environment.new('fancypants')
				allow(env).to receive(:get_local_resource).and_return('badger')
				allow(env).to receive(:get_remote_resource).and_return(nil)

				expect(env.compare_local_and_remote_versions).to be_a(String)
			end
		end
	end

	describe 'ChefSync::Role' do
		context 'when the local and remote are the same' do
			it "doesn't have any required actions" do
				role = ChefSync::Role.new('potato')
				allow(role).to receive(:get_local_resource).and_return('mushroom')
				allow(role).to receive(:get_remote_resource).and_return('mushroom')

				expect(role.compare_local_and_remote_versions).to be_nil
			end
		end

		context 'when the local and remote are different' do
			it "has required actions" do
				role = ChefSync::Role.new('potato')
				allow(role).to receive(:get_local_resource).and_return('mushroom')
				allow(role).to receive(:get_remote_resource).and_return('snake')

				expect(role.compare_local_and_remote_versions).to be_a(String)
			end
		end

		context 'when the remote does not exist' do
			it "has required actions" do
				role = ChefSync::Role.new('potato')
				allow(role).to receive(:get_local_resource).and_return('mushroom')
				allow(role).to receive(:get_remote_resource).and_return(nil)

				expect(role.compare_local_and_remote_versions).to be_a(String)
			end
		end
	end

	describe 'ChefSync::DataBag' do
		let(:dbag_list) {['rainbows']}

		context 'when the local and remote are the same' do
			it "doesn't have any required actions" do
				dbag = ChefSync::DataBag.new('potahto')
				allow(dbag).to receive(:get_local_resource_show_list).and_return(dbag_list)
				allow(dbag).to receive(:get_local_resource).and_return('unicorns')
				allow(dbag).to receive(:get_remote_resource).and_return('unicorns')

				expect(dbag.compare_local_and_remote_versions).to be_nil
			end
		end

		context 'when the local and remote are different' do
			it "has required actions" do
				dbag = ChefSync::DataBag.new('potahto')
				allow(dbag).to receive(:get_local_resource_show_list).and_return(dbag_list)
				allow(dbag).to receive(:get_local_resource).and_return('unicorns')
				allow(dbag).to receive(:get_remote_resource).and_return('butterflies')

				expect(dbag.compare_local_and_remote_versions).to be_a(String)
			end
		end

		context 'when the remote does not exist' do
			it "has required actions" do
				dbag = ChefSync::DataBag.new('potahto')
				allow(dbag).to receive(:get_local_resource_show_list).and_return(dbag_list)
				allow(dbag).to receive(:get_local_resource).and_return('rainbows')
				allow(dbag).to receive(:get_remote_resource).and_return(nil)

				expect(dbag.compare_local_and_remote_versions).to be_a(String)
			end
		end
	end

	describe 'ChefSync::Cookbook' do
		context 'when the local and remote are the same version number' do
			it "doesn't have any required actions when all files are the same" do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.0')
				allow(cb).to receive(:compare_cookbook_file_checksums).and_return(nil)

				expect(cb.compare_local_and_remote_versions).to be_nil
			end

			it "has required actions when a file is different" do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.0')
				allow(cb).to receive(:compare_cookbook_file_checksums).and_return('spaghetti')

				expect(cb.compare_local_and_remote_versions).to be_a(String)
			end

			it "has required actions when a file doesn't exist locally" do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.0')
				allow(cb).to receive(:compare_cookbook_file_checksums).and_return('meatballs')

				expect(cb.compare_local_and_remote_versions).to be_a(String)
			end
		end

		context 'when the local version is newer' do
			it "has required actions" do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.2', '0.1.0')

				expect(cb.compare_local_and_remote_versions).to be_a(String)
			end
		end

		context 'when the local version is older' do
			it "has required actions" do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', '0.1.2')

				expect(cb.compare_local_and_remote_versions).to be_a(String)
			end
		end

		context 'when the remote does not exist' do
			it "has required actions" do
				cb = ChefSync::Cookbook.new('boyardee', '0.1.0', nil)

				expect(cb.compare_local_and_remote_versions).to be_a(String)
			end
		end
	end

end