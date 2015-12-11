require 'spec_helper'

describe AsyncCache::Workers::SidekiqWorker do
  subject do
    AsyncCache::Workers::SidekiqWorker
  end

  describe '::has_workers?' do
    it 'returns false if no Sidekiq queues are available' do
      allow(subject).to receive(:sidekiq_options).and_return({'queue' => 'good_queue'})

      allow_any_instance_of(Sidekiq::ProcessSet).to receive(:to_a).and_return([
        { 'queues' => ['bad_queue'] }
      ])

      expect(subject.send :has_workers?).to eql false
    end
  end

  describe '::enqueue_async_job' do
    it 'enqueues a job' do
      key        = 'abc123'
      version    = 456
      expires_in = 789
      block      = 'proc { }'
      arguments  = []

      expect(subject).to receive(:perform_async).with(key, version, expires_in, arguments, block)

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
