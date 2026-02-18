# frozen_string_literal: true

# Seed data for RadioTrack MVP
# Target stations for contest tracking (B2C MVP)

# Create federal radio stations (10 stations for MVP)
stations = [
  # Original 4 from requirements
  {
    code: "avtoradio",
    title: "Авторадио",
    player_url: "https://www.avtoradio.ru/",
    stream_url: "https://live253.hostingradio.ru:8050/avtoradio",
    playlist_url: "https://www.avtoradio.ru/playlist",
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "europe_plus",
    title: "Европа Плюс",
    player_url: "https://europaplus.ru/",
    stream_url: "https://ep128.hostingradio.ru:8030/ep128",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "dfm",
    title: "DFM",
    player_url: "https://dfm.ru/",
    stream_url: "https://dfm.hostingradio.ru:8000/dfm",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "love_radio",
    title: "Love Radio",
    player_url: "https://loveradio.ru/",
    stream_url: "https://love.hostingradio.ru:8000/love",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "russkoe_radio",
    title: "Русское Радио",
    player_url: "https://rusradio.ru/",
    stream_url: "https://rusradio.hostingradio.ru:8000/rusradio",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "energy",
    title: "Energy",
    player_url: "https://www.energyfm.ru/",
    stream_url: "https://pub0101.101.ru:8000/stream/air/aac/64/99",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "hit_fm",
    title: "Хит FM",
    player_url: "https://hitfm.ru/",
    stream_url: "https://hitfm.hostingradio.ru:8000/hitfm_a",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "nashe",
    title: "НАШЕ Радио",
    player_url: "https://nashe.ru/",
    stream_url: "https://nashe.hostingradio.ru:8000/nashe",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "record",
    title: "Радио Рекорд",
    player_url: "https://radiorecord.ru/",
    stream_url: "https://air.radiorecord.ru:805/rr_320",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  },
  {
    code: "yumor_fm",
    title: "Юмор FM",
    player_url: "https://yumorfm.ru/",
    stream_url: "https://yumor.hostingradio.ru:8000/yumor",
    playlist_url: nil,  # To be determined
    federal: true,
    active: true,
    contest_enabled: true
  }
]

puts "Seeding #{stations.count} radio stations..."

stations.each do |station_data|
  Station.find_or_create_by!(code: station_data[:code]) do |station|
    station.title = station_data[:title]
    station.player_url = station_data[:player_url]
    station.stream_url = station_data[:stream_url]
    station.federal = station_data[:federal]
    station.active = station_data[:active]
    station.contest_enabled = station_data[:contest_enabled]
  end
end

puts "✅ Created #{Station.count} radio stations"

# Create sample detections (for testing)
if Rails.env.development?
  artists = [
    "The Weeknd", "Dua Lipa", "Ed Sheeran", "Ariana Grande", "Justin Bieber",
    "Taylor Swift", "Bruno Mars", "Billie Eilish", "Post Malone", "Imagine Dragons"
  ]

  titles = [
    "Blinding Lights", "Levitating", "Shape of You", "7 rings", "Peaches",
    "Anti-Hero", "Uptown Funk", "bad guy", "Circles", "Believer"
  ]

  Station.find_each do |station|
    10.times do |i|
      Detection.find_or_create_by!(
        station: station,
        artist: artists[i % artists.length],
        title: titles[i % titles.length],
        played_at: (i * 10).minutes.ago
      ) do |detection|
        detection.confidence = 0.9
        detection.source = "seed"
      end
    end
  end

  puts "✅ Created sample detections"
end

puts "🎉 Seeding completed!"
