require 'spec_helper'
require 'httparty'

require_relative './support/sidekiq'

describe AsyncCache::Store do
  context '#fetch' do
    before(:all) do
      @version_path = File.join(File.dirname(__FILE__), 'support', 'version.txt')

      unless File.exist? @version_path
        raise "Version file #{@version_path} doesn't exist"
      end
    end

    before(:each) do
      # 'y' is the locator used in `support/sinatra.rb`.
      Rails.cache.delete 'y'
    end

    after(:each) do
      sleep 1
    end

    def get_endpoint
      response = HTTParty.get 'http://localhost:4567'
      expect(response.success?).to eq true

      return response.body
    end

    it 'serves the fresh version if the cache is empty' do
      get_endpoint
    end

    it "serves the old version if it's cached" do
      body1 = get_endpoint

      FileUtils.touch @version_path

      body2 = get_endpoint

      expect(body1).to eq body2
    end

    it 'serves the new version after the worker has run' do
      body1 = get_endpoint

      FileUtils.touch @version_path

      body2 = get_endpoint
      # Check again that it served the old version
      expect(body2).to eq body1

      sleep 0.5 # Give the worker a chance to run

      body3 = get_endpoint
      # Check that it served the new version after the worker ran
      expect(body3).not_to eq body1
    end
  end
end
