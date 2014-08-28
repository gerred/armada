# require 'docker'

# module Armada
#   class Task
#     include Armada::Logging

#     class << self
#       def inherited klass
#         (class << self; self; end).send :define_method, klass.name.demodulize.underscore do |*args|
#           klass.new(*args).run!
#         end
#       end

#       def define name, &block
#         (class << self; self; end).send :define_method, name.to_s do |*args|
#           block.call *args
#         end
#       end
#     end
#   end
# end
