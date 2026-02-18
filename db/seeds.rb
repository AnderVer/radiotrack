# frozen_string_literal: true

# Seed data for RadioTrack MVP
# Target stations for contest tracking (B2C MVP)

# Create federal radio stations (10 stations for MVP)
stations = [
  # Original 4 from requirements
  { code: "avtoradio", title: "Авторадио", player_url: "https://live253.hostingradio.ru:8050/avtoradio", stream_url: "https://live253.hostingradio.ru:8050/avtoradio" },
  { code: "europe_plus", title: "Европа Плюс", player_url: "https://ep128.hostingradio.ru:8030/ep128", stream_url: "https://ep128.hostingradio.ru:8030/ep128" },
  { code: "dfm", title: "DFM", player_url: "https://dfm.hostingradio.ru:8000/dfm", stream_url: "https://dfm.hostingradio.ru:8000/dfm" },
  { code: "love_radio", title: "Love Radio", player_url: "https://love.hostingradio.ru:8000/love", stream_url: "https://love.hostingradio.ru:8000/love" },
  
  # Additional 6 stations with contests
  { code: "russkoe_radio", title: "Русское Радио", player_url: "https://rusradio.hostingradio.ru:8000/rusradio", stream_url: "https://rusradio.hostingradio.ru:8000/rusradio" },
  { code: "energy", title: "Energy", player_url: "https://pub0101.101.ru:8000/stream/air/aac/64/99", stream_url: "https://pub0101.101.ru:8000/stream/air/aac/64/99" },
  { code: "hit_fm", title: "Хит FM", player_url: "https://hitfm.hostingradio.ru:8000/hitfm_a", stream_url: "https://hitfm.hostingradio.ru:8000/hitfm_a" },
  { code: "nashe", title: "НАШЕ Радио", player_url: "https://nashe.hostingradio.ru:8000/nashe", stream_url: "https://nashe.hostingradio.ru:8000/nashe" },
  { code: "record", title: "Радио Рекорд", player_url: "https://air.radiorecord.ru:805/rr_320", stream_url: "https://air.radiorecord.ru:805/rr_320" },
  { code: "yumor_fm", title: "Юмор FM", player_url: "https://yumor.hostingradio.ru:8000/yumor", stream_url: "https://yumor.hostingradio.ru:8000/yumor" }
]

stations.each do |station_data|
  Station.find_or_create_by!(code: station_data[:code]) do |station|
    station.title = station_data[:title]
    station.player_url = station_data[:player_url]
    station.federal = true
    station.active = true
  end
end

puts "Created #{Station.count} radio stations"

# Create sample detections (for testing)
if Rails.env.development?
  require "faker"

  artists = [
    "The Weeknd", "Dua Lipa", "Ed Sheeran", "Ariana Grande", "Justin Bieber",
    "Taylor Swift", "Bruno Mars", "Billie Eilish", "Post Malone", "Imagine Dragons"
  ]

  titles = [
    "Blinding Lights", "Levitating", "Shape of You", "7 rings", "Peaches",
    "Anti-Hero", "Uptown Funk", "bad guy", "Circles", "Believer"
  ]

  Station.all.each do |station|
    50.times do |i|
      Detection.create!(
        station: station,
        artist: artists.sample,
        title: titles.sample,
        played_at: rand(1.hour..24.hours).ago,
        confidence: rand(0.8..1.0),
        source: "api"
      )
    end
  end

  puts "Created sample detections"
end
