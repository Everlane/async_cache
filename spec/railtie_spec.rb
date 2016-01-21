require 'spec_helper'

describe AsyncCache do
  context 'Railtie' do
    class Application < Rails::Application
    end

    before(:all) do
      app = Application.new
      app.load_tasks
    end

    it 'adds the async_cache:* tasks' do
      expect(Rake::Task.task_defined?('async_cache:clear')).to eq true
    end
  end
end
