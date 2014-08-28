# require_relative '../spec_helper.rb'

# describe 'Deploy' do
#   describe 'pull' do
#     let(:config) { Armada::Configuration.send(:new) }
#     let(:task) { Deploy.new }

#     before do
#       config.hosts = ["bld-foo-01:4243"]
#       config.image = "foo.io/someorg/myimage"
#       config.tag   = "latest"
#       config.opts  = opts
#       Deploy.stub :new => task
#       Docker::Image.stub(:create).and_return(double("image", :id => 'asdf'))
#       Armada.stub(:config).and_return(config)
#     end

#     context 'when --no-pull is true' do
#       let(:opts) { { :no_pull => true } }
#       it "should not pull from the repository" do
#         expect(Docker::Image).should_not_receive(:create)
#         task.pull
#       end
#     end

#     context 'when --no-pull is false' do
#       let(:opts) { { :no_pull => false } }
#       it "should pull from the repository" do
#         expect(Docker::Image).to receive(:create)
#         task.pull
#       end
#     end

#   end
# end
