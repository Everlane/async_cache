require 'spec_helper'
require 'async_cache/workers/active_job'

describe AsyncCache::Workers::ActiveJobWorker do
  subject do
    AsyncCache::Workers::ActiveJobWorker
  end

  describe '::has_workers?' do
    it 'returns true' do
      expect(subject.send :has_workers?).to eql true
    end
  end

  describe '::enqueue_async_job' do
    it 'enqueues a job' do
      key        = 'abc123'
      version    = 456
      expires_in = 789
      block      = 'proc { }'
      arguments  = []

      expect(subject).to receive(:perform_later).with(key, version, expires_in, arguments, block)

      subject.enqueue_async_job(
        key:        key,
        version:    version,
        expires_in: expires_in,
        block:      block,
        arguments:  arguments
      )
    end
  end
end
