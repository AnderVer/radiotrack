class CleanupDuplicateDetections < ActiveRecord::Migration[8.0]
  def up
    puts "Cleaning up duplicate detections..."

    # Find and delete duplicates, keeping the record with the lowest ID
    # Using SQL for efficiency with large datasets

    # Create a temporary table to hold duplicate groups
    execute <<-SQL
      DELETE FROM detections
      WHERE id IN (
        SELECT id FROM (
          SELECT id,
                 ROW_NUMBER() OVER (
                   PARTITION BY station_id, played_at, artist_title_normalized
                   ORDER BY id
                 ) as rn
          FROM detections
        ) t
        WHERE rn > 1
      )
    SQL

    puts "Duplicate detections cleaned up"
  end

  def down
    # No rollback - duplicates cleanup is destructive
    puts "Cannot rollback duplicate cleanup"
  end
end
