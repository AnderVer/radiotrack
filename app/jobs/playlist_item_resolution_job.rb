# frozen_string_literal: true

class PlaylistItemResolutionJob < ApplicationJob
  queue_as :default

  # Retry on failure
  retry_on ActiveRecord::RecordNotFound, wait: :exponentially_longer
  retry_on Exception, wait: 5.seconds, attempts: 3

  def perform(playlist_item_id)
    item = PlaylistItem.find_by(id: playlist_item_id)
    return unless item&.pending?

    # Resolve the item
    item.resolve!

    # Log result
    Rails.logger.info "PlaylistItem #{item.id} resolved to: #{item.track_artist} - #{item.track_title}"
  end
end
