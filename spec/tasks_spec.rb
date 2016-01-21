require 'spec_helper'

describe AsyncCache do
  context 'tasks' do
    before(:all) do
      require 'rake'
      Rake.application.clear
      Rake.application.add_import File.join(File.dirname(__FILE__), '../lib/async_cache/tasks/clear.rake')
      Rake.application.load_imports
    end

    before(:each) do
      # Reset the array of known store instances
      AsyncCache::Store.instance_eval { @stores = [] }
    end

    describe ':clear' do
      it 'clears with worker queues' do
        store = AsyncCache::Store.new backend: Rails.cache, worker: :sidekiq

        queue_double = double 'Sidekiq::Queue'
        allow(Sidekiq::Queue).to receive(:new).and_return(queue_double)

        expect(queue_double).to receive(:clear)

        Rake.application['async_cache:clear'].execute
      end
    end
  end
end
