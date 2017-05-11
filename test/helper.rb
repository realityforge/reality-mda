$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'test/unit/assertions'
require 'reality/mda'

class Reality::Mda::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
    FileUtils.mkdir_p self.working_dir

    self.class.send(:remove_const, :TestModule) if self.class.const_defined?(:TestModule)
    self.class.class_eval <<-RUBY
      module TestModule
      end
    RUBY
  end

  def teardown
    if passed?
      FileUtils.rm_rf self.working_dir if File.exist?(self.working_dir)
    else
      $stderr.puts "Test #{self.class.name}.#{name} Failed. Leaving working directory #{self.working_dir}"
    end
  end

  def local_dir(directory = SecureRandom.hex)
    "#{working_dir}/#{directory}"
  end

  def working_dir
    @working_dir ||= "#{workspace_dir}/#{SecureRandom.hex}"
  end

  def workspace_dir
    @workspace_dir ||= ENV['TEST_TMP_DIR'] || File.expand_path("#{File.dirname(__FILE__)}/../tmp/workspace")
  end
end
