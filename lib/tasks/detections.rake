# frozen_string_literal: true

namespace :db do
  namespace :detections do
    desc "Find duplicate detections by (station_id, played_at, artist_title_normalized)"
    task find_duplicates: :environment do
      puts "🔍 Finding duplicate detections..."
      puts "=" * 60

      # Find duplicates using GROUP BY and HAVING
      duplicates = Detection
        .select(:station_id, :played_at, :artist_title_normalized, "COUNT(*) as count, ARRAY_AGG(id) as ids")
        .group(:station_id, :played_at, :artist_title_normalized)
        .having("COUNT(*) > 1")

      duplicate_count = 0

      duplicates.each do |dup|
        duplicate_count += 1
        station = Station.find_by(id: dup.station_id)
        station_code = station&.code || "unknown"

        puts "\nDuplicate group ##{duplicate_count}:"
        puts "  Station: #{station_code} (ID: #{dup.station_id})"
        puts "  Played at: #{dup.played_at}"
        puts "  Track: #{dup.artist_title_normalized}"
        puts "  Count: #{dup.count}"
        puts "  IDs: #{dup.ids.join(', ')}"

        # Show first 3 duplicates as sample
        Detection.where(id: dup.ids.first(3)).each do |d|
          puts "    - ID #{d.id}: #{d.artist} - #{d.title} (source: #{d.source}, created: #{d.created_at})"
        end
      end

      puts "\n" + "=" * 60
      if duplicate_count > 0
        puts "❌ Found #{duplicate_count} duplicate groups"
        puts "Run 'rake db:detections:cleanup_duplicates' to remove them"
      else
        puts "✅ No duplicates found"
      end
    end

    desc "Cleanup duplicate detections (keep oldest by ID)"
    task cleanup_duplicates: :environment do
      puts "🧹 Cleaning up duplicate detections..."
      puts "=" * 60

      # Find duplicates
      duplicates = Detection
        .select(:station_id, :played_at, :artist_title_normalized, "COUNT(*) as count, ARRAY_AGG(id) as ids")
        .group(:station_id, :played_at, :artist_title_normalized)
        .having("COUNT(*) > 1")

      total_deleted = 0

      duplicates.each do |dup|
        ids = dup.ids.sort # Keep oldest (lowest ID)
        ids_to_delete = ids[1..-1] # Delete all except first

        next if ids_to_delete.blank?

        deleted_count = Detection.where(id: ids_to_delete).delete_all
        total_deleted += deleted_count

        station = Station.find_by(id: dup.station_id)
        station_code = station&.code || "unknown"

        puts "Deleted #{deleted_count} duplicates for #{station_code} at #{dup.played_at}"
      end

      puts "\n" + "=" * 60
      puts "✅ Deleted #{total_deleted} duplicate detections"
    end

    desc "Add unique index to detections (station_id, played_at, artist_title_normalized)"
    task add_unique_index: :environment do
      puts "📌 Adding unique index to detections..."

      # Check if index already exists
      indexes = ActiveRecord::Base.connection.indexes(:detections)
      unique_index = indexes.find { |i| i.name == "index_detections_unique_station_played_artist_title" }

      if unique_index
        puts "⚠️  Unique index already exists"
        return
      end

      # Check for duplicates first
      duplicates = Detection
        .select(:station_id, :played_at, :artist_title_normalized)
        .group(:station_id, :played_at, :artist_title_normalized)
        .having("COUNT(*) > 1")
        .count

      if duplicates.any?
        puts "❌ Found #{duplicates.size} duplicate groups. Run 'rake db:detections:cleanup_duplicates' first"
        return
      end

      # Add unique index
      ActiveRecord::Base.connection.add_index(
        :detections,
        [:station_id, :played_at, :artist_title_normalized],
        unique: true,
        name: "index_detections_unique_station_played_artist_title"
      )

      puts "✅ Unique index added successfully"
    end
  end
end
