require 'spec_helper'
require 'async_cache/workers/sidekiq'

describe AsyncCache::Workers::SidekiqWorker do
  subject do
    AsyncCache::Workers::SidekiqWorker
  end

  describe '.sidekiq_options' do
    # See `spec_helper.rb` which makes it think the gem is loaded.
    it 'has the uniqueness option for `sidekiq-unique-jobs`' do
      expect(subject.sidekiq_options_hash).to include 'unique'
    end
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
