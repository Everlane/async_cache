require 'spec_helper'
require 'httparty'

require_relative './support/config'

describe AsyncCache::Store do
  context '#fetch' do
    before(:all) do
      unless File.exist? VERSION_PATH
        raise "Version file #{VERSION_PATH} doesn't exist"
      end
    end

    before(:each) do
      # 'y' is the locator used in `support/sinatra.rb`.
      Rails.cache.delete LOCATOR
    end

    after(:each) do
      sleep 1
    end

    def get_endpoint
      response = HTTParty.get 'http://localhost:4567'
      expect(response.success?).to eq true

      return response.body
    end

    def touch_version_file
      FileUtils.touch VERSION_PATH
    end

    it 'serves the fresh version if the cache is empty' do
      get_endpoint
    end

    it "serves the old version if it's cached" do
      body1 = get_endpoint

      touch_version_file

      body2 = get_endpoint

      expect(body1).to eq body2
    end

    it 'serves the new version after the worker has run' do
      body1 = get_endpoint

      touch_version_file

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
