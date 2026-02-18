# 🚀 RadioTrack — Реализованный план работ (M0–M3)

**Дата:** 18 февраля 2026  
**Статус:** M0 Bootstrap ✅, M1 Avtoradio ingest ✅, M2 Dedup ✅, M3 Solid Queue ✅

---

## 📋 Реализованные задачи

### ✅ M0 — Bootstrap

| Задача | Статус | Файлы |
|--------|--------|-------|
| **Docs: быстрый старт (Docker/DB/Queue)** | ✅ | `README.md` |
| **Infra: добавить/обновить `.env.example`** | ✅ | `.env.example` |
| **DB: seeds — 10 станций для MVP** | ✅ | `db/seeds.rb` |
| **Smoke: Detection работает** | ✅ | `test/models/detection_test.rb`, `test/test_helper.rb` |

**Дополнительно:**
- Миграция для `playlist_url`: `db/migrate/20260218000010_add_playlist_url_to_stations.rb`
- Обновлена модель `Station` (scope `with_playlist`, метод `has_public_playlist?`)

---

### ✅ M1 — Avtoradio ingest

| Задача | Статус | Файлы |
|--------|--------|-------|
| **Parser: AvtoradioPlaylistParser (CSS selectors)** | ✅ | `app/services/avtoradio_playlist_parser.rb` |
| **Parser: дата из заголовка + ru months map** | ✅ | `app/services/avtoradio_playlist_parser.rb` |
| **Timezone: МСК→UTC для played_at** | ✅ | `app/services/avtoradio_playlist_parser.rb` |
| **Job: AvtoradioIngestJob** | ✅ | `app/jobs/avtoradio_ingest_job.rb` |
| **Ingest idempotency (app-level dedup)** | ✅ | `app/jobs/avtoradio_ingest_job.rb` |
| **Test: AvtoradioPlaylistParser** | ✅ | `test/services/avtoradio_playlist_parser_test.rb` |
| **Fixture: HTML для теста** | ✅ | `test/fixtures/files/avtoradio_playlist.html` |

**Дополнительно:**
- Добавлен `nokogiri` в `Gemfile`

---

### ✅ M2 — Dedup

| Задача | Статус | Файлы |
|--------|--------|-------|
| **Rake task: найти дубли detections** | ✅ | `lib/tasks/detections.rake` |
| **Migration: cleanup дублей** | ✅ | `db/migrate/20260218000011_cleanup_duplicate_detections.rb` |
| **Migration: unique index** | ✅ | `db/migrate/20260218000012_add_unique_index_to_detections.rb` |

**Rake tasks:**
```bash
# Найти дубли
docker compose exec web bin/rails db:detections:find_duplicates

# Удалить дубли (оставить oldest by ID)
docker compose exec web bin/rails db:detections:cleanup_duplicates

# Добавить unique index
docker compose exec web bin/rails db:detections:add_unique_index
```

---

### ✅ M3 — Solid Queue schedule

| Задача | Статус | Файлы |
|--------|--------|-------|
| **Config: solid_queue.yml** | ✅ | `config/solid_queue.yml` |
| **Config: queue.yml** | ✅ | `config/queue.yml` |
| **Recurring: AvtoradioIngestJob (каждые 1–2 минуты)** | ✅ | `config/application.rb` |

**Настройки:**
- Timezone: `Europe/Moscow`
- Active Record: `default_timezone = :utc`
- Recurring task: `*/2 * * * *` (каждые 2 минуты)

---

## 📦 Зависимости

### Gemfile (новые)

```ruby
# HTML parsing for playlists
gem "nokogiri"

# HTTP client (уже был)
gem "httparty"
```

**Установка:**
```bash
docker compose exec web bundle install
```

---

## 🛠 Как использовать

### 1. Запуск Docker

```bash
docker compose up -d
```

### 2. Установка зависимостей

```bash
docker compose exec web bundle install
```

### 3. Миграция БД

```bash
# Применить все миграции
docker compose exec web bin/rails db:migrate

# Посеять данные (10 станций + sample detections)
docker compose exec web bin/rails db:seed
```

### 4. Запуск Solid Queue

```bash
# В отдельном терминале
docker compose exec web bin/rails solid_queue:start
```

**Примечание:** AvtoradioIngestJob будет запускаться автоматически каждые 2 минуты.

### 5. Проверка работы

```bash
# Консоль Rails
docker compose exec web bin/rails console

# Проверка станций
Station.count  # => 10

# Проверка Detection
Detection.first

# Ручной запуск ingest
AvtoradioIngestJob.perform_now
```

### 6. Запуск тестов

```bash
# Все тесты
docker compose exec web bin/rails test

# Тест парсера
docker compose exec web bin/rails test test/services/avtoradio_playlist_parser_test.rb

# Тест модели Detection
docker compose exec web bin/rails test test/models/detection_test.rb
```

### 7. Rake tasks для работы с дублями

```bash
# Найти дубли
docker compose exec web bin/rails db:detections:find_duplicates

# Удалить дубли
docker compose exec web bin/rails db:detections:cleanup_duplicates

# Добавить unique index (после очистки)
docker compose exec web bin/rails db:detections:add_unique_index
```

---

## 📊 Структура файлов

```
app/
├── jobs/
│   └── avtoradio_ingest_job.rb          # Job для ingest
├── models/
│   ├── application_record.rb            # Базовая модель (лимиты, plan_code)
│   ├── detection.rb                     # Факт проигрывания
│   └── station.rb                       # Радиостанция
├── services/
│   └── avtoradio_playlist_parser.rb     # Парсер плейлиста
└── ...

config/
├── application.rb                       # Timezone + Solid Queue recurring
├── queue.yml                            # Queue adapter config
└── solid_queue.yml                      # Solid Queue config

db/
├── migrate/
│   ├── ...
│   ├── 20260218000010_add_playlist_url_to_stations.rb
│   ├── 20260218000011_cleanup_duplicate_detections.rb
│   └── 20260218000012_add_unique_index_to_detections.rb
├── schema.rb
└── seeds.rb

lib/
└── tasks/
    └── detections.rake                  # Rake tasks для дублей

test/
├── fixtures/
│   └── files/
│       └── avtoradio_playlist.html      # HTML fixture для теста
├── models/
│   └── detection_test.rb
├── services/
│   └── avtoradio_playlist_parser_test.rb
└── test_helper.rb

.env.example                              # Полный список ENV
README.md                                 # Обновлённая документация
```

---

## 🔧 ENV переменные

### Обязательные

```bash
# Rails Basic
RAILS_ENV=development
SECRET_KEY_BASE=<generate: openssl rand -hex 64>
DEVISE_SECRET_KEY=<generate: openssl rand -hex 64>

# Database
DATABASE_URL=postgres://postgres:postgres@db:5432/radiotrack_development

# Host
HOST=0.0.0.0
```

### Опциональные (OAuth, Recognition)

```bash
# OAuth (не требуется для MVP)
VK_APP_ID=
VK_APP_SECRET=
YANDEX_CLIENT_ID=
YANDEX_CLIENT_SECRET=

# Recognition (fallback, не используется в MVP)
RECOGNITION_PROVIDER=
AUDD_API_TOKEN=
RECOGNITION_CALLBACK_URL=

# Internal cron/jobs
CRON_SECRET=<generate: openssl rand -hex 32>
```

---

## 🎯 Следующие шаги (M4–M9)

### M4 — UI (Hotwire)

- [ ] UI: главная страница (список станций)
- [ ] UI: страница станции (последние detections)
- [ ] UI: paywall CTA для Paid функций

### M5 — OAuth

- [ ] OAuth VK: вход + Identity linking
- [ ] OAuth Yandex: вход + Identity linking
- [ ] API+UI: subscription_status

### M6 — Recognition fallback

- [ ] ENV wiring + базовый клиент AudD

### M7 — PWA

- [ ] manifest.webmanifest + иконки

### M8 — Tests

- [ ] Test: МСК→UTC конвертация played_at
- [ ] Test: Unique index защита (DB-level)
- [ ] Test: Trial tune_in списание

### M9 — Stations inventory

- [ ] Inventory: 9 станций — источники плейлистов
- [ ] Parser architecture: базовый интерфейс + 2-я станция

---

## 📝 Заметки

### Timezone

- **Хранение:** UTC (в БД)
- **Ввод:** МСК (из плейлиста Авторадио)
- **Вывод:** МСК (для UI)
- **Конвертация:** `ActiveRecord::TimeZone["Europe/Moscow"]`

### Дедупликация

1. **Прикладной уровень:** Проверка перед `create!` в `AvtoradioIngestJob`
2. **Уровень БД:** Unique index на `(station_id, played_at, artist_title_normalized)`

### Solid Queue

- **Без Redis:** Использует PostgreSQL
- **Recurring tasks:** В `config/application.rb`
- **Запуск:** `bin/rails solid_queue:start`

---

## ✅ Чек-лист готовности

| Компонент | Статус |
|-----------|--------|
| **Модель Detection** | ✅ 100% |
| **Модель Station** | ✅ 100% |
| **Модель User** | ✅ 100% |
| **AvtoradioParser** | ✅ 100% |
| **AvtoradioIngestJob** | ✅ 100% |
| **Solid Queue config** | ✅ 100% |
| **Unique index** | ✅ 100% (миграция готова) |
| **Timezone МСК** | ✅ 100% |
| **Тесты** | ✅ 100% (Detection + Parser) |
| **UI** | ❌ 0% (следующий этап) |
| **OAuth** | ❌ 0% |
| **PWA** | ❌ 0% |

---

**M0–M3 завершены.** Готов к реализации M4 (UI) и последующих этапов.
