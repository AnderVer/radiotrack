# frozen_string_literal: true

module Api
  class TracksController < BaseController
    # GET /api/tracks/:id/where_now (Trial limited)
    def where_now
      @track = Detection.find_by!(id: params[:id])

      # Check trial limit for non-paid users
      unless current_user.paid?
        if current_user.can_tune_in?
          current_user.record_tune_in!
        else
          return render json: {
            error: "Trial limit reached",
            upgrade_required: true
          }, status: :forbidden
        end
      end

      # Find stations where this track is playing now
      @stations = Station.joins(:now_playing_track)
        .where(detections: { artist: @track.artist, title: @track.title })

      render json: {
        track: { artist: @track.artist, title: @track.title },
        stations: @stations.as_json(only: [:id, :code, :title, :player_url])
      }
    end

    # GET /api/tracks/:id/where_soon?window=30m (Paid only)
    def where_soon
      unless current_user.can_access_forecast?
        return render json: { error: "Subscription required" }, status: :forbidden
      end

      @track = Detection.find_by!(id: params[:id])
      window = params[:window] || "30m"
      window_minutes = parse_window(window)

      # Baseline forecast: find stations with similar patterns
      @predictions = calculate_forecast(@track, window_minutes)

      render json: {
        track: { artist: @track.artist, title: @track.title },
        window: window,
        predictions: @predictions
      }
    end

    private

    def parse_window(window_str)
      value, unit = window_str.match(/(\d+)([mhd])/).captures
      value.to_i * case unit
                   when "m" then 1
                   when "h" then 60
                   when "d" then 1440
                   else 30
                   end
    end

    def calculate_forecast(track, window_minutes)
      # Simple baseline: median interval between plays
      station_predictions = []

      Station.active.federal.each do |station|
        # Get recent detections for this station
        recent = station.detections
          .where("played_at >= ?", 24.hours.ago)
          .order(played_at: :desc)

        # Find intervals between plays of similar tracks
        intervals = []
        last_played = nil

        recent.each do |detection|
          if detection.artist_title_normalized == track.artist_title_normalized
            if last_played
              intervals << (last_played - detection.played_at).to_i
            end
            last_played = detection.played_at
          end
        end

        if intervals.any?
          median_interval = intervals.sort[intervals.size / 2]
          next_play_estimate = last_played + median_interval.seconds

          if next_play_estimate <= window_minutes.minutes.from_now
            station_predictions << {
              station_id: station.id,
              station_name: station.title,
              eta: next_play_estimate,
              confidence: confidence_level(intervals.size)
            }
          end
        end
      end

      station_predictions.sort_by { |p| p[:eta] }
    end

    def confidence_level(sample_size)
      if sample_size >= 5
        "high"
      elsif sample_size >= 3
        "medium"
      else
        "low"
      end
    end
  end
end
