require 'spec_helper'

describe AsyncCache::Workers do
  subject do
    AsyncCache::Workers
  end

  describe '::worker_for_name' do
    it 'finds the Sidekiq worker' do
      expect(subject.worker_for_name :sidekiq).to eql AsyncCache::Workers::SidekiqWorker
    end

    it 'finds the ActiveJob worker' do
      expect(subject.worker_for_name :active_job).to eql AsyncCache::Workers::ActiveJobWorker
    end
  end
end
