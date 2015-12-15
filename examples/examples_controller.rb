# This is an example of how to use AsyncCache in a Rails API controller; it
# is loosely based on patterns currently in use in production at Everlane.

class ExamplesController < ApplicationController
  def index
    locator = 'examples'
    version = Example.maximum :updated_at
    options = {
      expires_in:        1.week,
      # Force it to synchronously regenerate for admin users so that they
      # can see their changes reflected immediately
      synchronous_regen: current_user.admin?
    }

    json = async_cache.fetch(locator, version, options) do
      ExamplesPresenter.new.to_json
    end

    self.response_body = json
    self.content_type  = 'application/json'
  end

  private

  def async_cache
    Rails.application.config.async_cache
  end
end

# We use presenters at Everlane as a sort of view-model. Controllers handle
# application logic such as writing to the database or redirecting clients
# while presenters handle loading data for the views and rendering views.

class ExamplesPresenter < Presenter
  def initialize
    @examples = Example.all
  end

  def to_json
    @examples.map(&:as_json).to_json
  end
end
