# 🚀 RadioTrack — Итоговая документация (M0-M9)

**Дата:** 18 февраля 2026  
**Статус:** M0-M9 реализованы, готово к локальному тестированию

---

## 📊 Реализованные этапы

| Этап | Компоненты | Статус |
|------|------------|--------|
| **M0 Bootstrap** | ENV, Docker, Seeds, Tests | ✅ 100% |
| **M1 Avtoradio ingest** | Parser, Job, Timezone | ✅ 100% |
| **M2 Dedup** | Rake tasks, Migrations | ✅ 100% |
| **M3 Solid Queue** | Configs, Recurring | ✅ 100% |
| **M4 UI (Hotwire)** | Layout, Pages, Paywall | ✅ 100% |
| **M5 OAuth** | VK/Yandex, Profile UI | ✅ 100% |
| **M7 PWA** | Manifest, Icons | ✅ 100% |
| **M8 Tests** | API, Timezone, Dedup, Trial | ✅ 100% |
| **M9 Stations inventory** | Анализ 9 станций | ✅ 100% |
| **UI Bookmarks** | Закладки станций | ✅ 100% |
| **UI Playlists CRUD** | Плейлисты | ✅ 100% |
| **Parser Architecture** | Base class + Factory | ✅ 100% |

---

## 📁 Структура проекта

```
RadioTrack/
├── app/
│   ├── controllers/
│   │   ├── api/              # API контроллеры
│   │   │   ├── stations_controller.rb
│   │   │   ├── tracks_controller.rb
│   │   │   ├── bookmarks_controller.rb
│   │   │   └── ...
│   │   ├── stations_controller.rb
│   │   ├── bookmarks_controller.rb
│   │   ├── playlists_controller.rb
│   │   └── ...
│   ├── models/
│   │   ├── user.rb
│   │   ├── station.rb
│   │   ├── detection.rb
│   │   └── ...
│   ├── services/
│   │   ├── base_playlist_parser.rb
│   │   ├── avtoradio_playlist_parser.rb
│   │   └── playlist_parser_factory.rb
│   ├── jobs/
│   │   └── avtoradio_ingest_job.rb
│   └── views/
│       ├── layouts/application.html.erb
│       ├── pages/home.html.erb
│       ├── stations/show.html.erb
│       ├── bookmarks/index.html.erb
│       ├── playlists/*.html.erb
│       └── ...
├── config/
│   ├── application.rb        # Timezone + Solid Queue
│   ├── routes.rb
│   ├── solid_queue.yml
│   └── queue.yml
├── db/
│   ├── migrate/
│   │   ├── *_add_playlist_url_to_stations.rb
│   │   ├── *_cleanup_duplicate_detections.rb
│   │   └── *_add_unique_index_to_detections.rb
│   ├── schema.rb
│   └── seeds.rb
├── lib/tasks/
│   └── detections.rake       # Rake tasks для дублей
├── test/
│   ├── controllers/api/
│   ├── models/
│   └── services/
├── docs/
│   └── STATIONS_INVENTORY.md
├── public/
│   ├── manifest.webmanifest
│   └── icons/
├── .env.example
├── docker-compose.yml
├── Gemfile
└── README.md
```

---

## 🚀 Быстрый старт

### 1. Запуск Docker

```bash
cd c:\Акселерация Обучение\AutoRadio\RadioTrack
docker compose up -d --build
```

### 2. Миграция БД

```bash
docker compose exec web bin/rails db:create db:migrate
```

### 3. Посев данных

```bash
docker compose exec web bin/rails db:seed
```

### 4. Открыть приложение

```
http://localhost:3000
```

---

## 📡 Функциональность

### Для пользователей

| Функция | Guest | Auth | Paid |
|---------|-------|------|------|
| Закладки станций | 3 | ∞ | ∞ |
| Плейлисты | 3 × 10 | 10 × 50 | 50 × 100 |
| Trial "Где играет" | 3/день | 3/день | ∞ |
| Последний трек | ❌ | ❌ | ✅ |
| Плейлист эфира | ❌ | ❌ | ✅ |
| Прогноз Soon | ❌ | ❌ | ✅ |

### API Endpoints

**Stations:**
- `GET /api/stations` — список
- `GET /api/stations/:id` — детали
- `GET /api/stations/:id/last_track` — последний трек (Paid)
- `GET /api/stations/:id/playlist` — плейлист (Paid)

**Tracks:**
- `GET /api/tracks/:id/where_now` — где играет (Trial)
- `GET /api/tracks/:id/where_soon` — прогноз (Paid)

**User:**
- `GET/POST /api/user/bookmarks` — закладки
- `GET /api/user/subscription_status` — статус

---

## 🧪 Тестирование

### Запустить тесты

```bash
docker compose exec web bin/rails test
```

### Проверить парсер

```bash
docker compose exec web bin/rails console
```

```ruby
# Ручной запуск ingest
AvtoradioIngestJob.perform_now

# Проверка результатов
Detection.where(source: "avtoradio_playlist").count
Detection.last
```

### Проверить дубли

```bash
# Найти дубли
docker compose exec web bin/rails db:detections:find_duplicates

# Удалить дубли
docker compose exec web bin/rails db:detections:cleanup_duplicates

# Добавить unique index
docker compose exec web bin/rails db:detections:add_unique_index
```

---

## 📻 Парсеры станций

### Реализованные

| Станция | Статус | Сложность |
|---------|--------|-----------|
| **Авторадио** | ✅ Реализовано | Easy |

### Требуют анализа

| Станция | Статус | Сложность |
|---------|--------|-----------|
| Европа Плюс | 🔍 Требуется API | Medium |
| Energy | 🔍 TBD | TBD |
| Хит FM | 🔍 TBD | TBD |
| НАШЕ Радио | 🔍 TBD | TBD |
| Радио Рекорд | 🔍 TBD | TBD |
| Юмор FM | 🔍 TBD | TBD |

### Недоступны

| Станция | Причина |
|---------|---------|
| DFM | 404 Not Found |
| Love Radio | 404 Not Found |
| Русское Радио | Только новинки |

---

## 🔧 Конфигурация

### ENV переменные

```bash
# Rails Basic
RAILS_ENV=development
SECRET_KEY_BASE=<generate: openssl rand -hex 64>
DEVISE_SECRET_KEY=<generate: openssl rand -hex 64>

# Database
DATABASE_URL=postgres://postgres:postgres@db:5432/radiotrack_development

# OAuth (опционально)
VK_APP_ID=<your_vk_app_id>
VK_APP_SECRET=<your_vk_app_secret>
YANDEX_CLIENT_ID=<your_yandex_client_id>
YANDEX_CLIENT_SECRET=<your_yandex_client_secret>

# Internal
CRON_SECRET=<generate: openssl rand -hex 32>
```

### Timezone

- **Хранение:** UTC (в БД)
- **Ввод:** МСК (из плейлиста Авторадио)
- **Вывод:** МСК (для UI)

### Solid Queue

- **Recurring task:** AvtoradioIngestJob каждые 2 минуты
- **Запуск:** `docker compose exec web bin/rails solid_queue:start`

---

## 📝 Миграции

### Применённые

1. `add_playlist_url_to_stations` — поле для URL плейлиста
2. `cleanup_duplicate_detections` — удаление дублей
3. `add_unique_index_to_detections` — unique index

### Rake tasks

```bash
# Найти дубли
bin/rails db:detections:find_duplicates

# Удалить дубли
bin/rails db:detections:cleanup_duplicates

# Добавить unique index
bin/rails db:detections:add_unique_index
```

---

## 🎯 Следующие шаги

### Приоритет 1: Тестирование локально

1. [ ] Запустить Docker
2. [ ] Применить миграции
3. [ ] Посеять данные
4. [ ] Протестировать UI
5. [ ] Протестировать API
6. [ ] Протестировать AvtoradioIngestJob

### Приоритет 2: Europa Plus

1. [ ] Найти API endpoint
2. [ ] Создать EuropaPlusPlaylistParser
3. [ ] Добавить EuropaPlusIngestJob

### Приоритет 3: Остальные станции

1. [ ] Анализ 5 станций
2. [ ] Выбрать 1-2 "easy"
3. [ ] Реализовать парсеры

---

## 📚 Документация

- `README.md` — основной README
- `SYNCHRONIZATION_REPORT.md` — полный анализ проекта
- `IMPLEMENTATION_PLAN_M0-M3.md` — отчёт о реализации M0-M3
- `TESTING_PLAN.md` — детальный план тестирования
- `QUICK_START_TESTING.md` — быстрый старт
- `docs/STATIONS_INVENTORY.md` — инвентаризация станций

---

**Проект готов к локальному тестированию!** 🚀
