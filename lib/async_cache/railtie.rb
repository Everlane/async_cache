module AsyncCache
  class Railtie < ::Rails::Railtie
    rake_tasks do
      %w[clear].each do |name|
        file = File.join(File.dirname(__FILE__), "tasks/#{name}.rake")

        load file
      end
    end
  end
end
