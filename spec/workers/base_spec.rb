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

  describe '#perform' do
    class TestWorker
      include AsyncCache::Workers::Base
    end

    subject do
      TestWorker.new
    end

    it 'evaluates the job and writes to the backend' do
      backend = spy 'Backend'
      allow(AsyncCache).to receive(:backend).and_return(backend)

      key             = 'test'
      version         = 42
      expires_in      = 1337
      block_arguments = [1]
      block_source    = 'proc { |arg| arg * 2 }'

      expect(backend).to receive(:write).with(key, [2, version], expires_in: expires_in)

      subject.perform key, version, expires_in, block_arguments, block_source
    end
  end
end
