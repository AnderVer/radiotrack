# 📋 RadioTrack — Синхронизация по проекту

**Дата:** 18 февраля 2026  
**Статус:** Анализ завершён, готовность к реализации

---

## 🎯 Резюме

Проект **RadioTrack (B2C)** реализован на **Rails 8** с использованием **ActiveRecord**, **Devise**, **Solid Queue** и **Hotwire**. Модель данных соответствует документации B2C (Next.js-версия адаптирована под Rails).

**Ключевое решение:** Используем **открытые плейлисты радиостанций** (парсинг HTML) вместо платных сервисов распознавания (AudD/ACRCloud).

---

## 📊 1. Структура проекта (Rails 8)

| Компонент | Статус | Версия/Примечание |
|-----------|--------|-------------------|
| **Фреймворк** | ✅ Rails | 8.0.0 |
| **Язык** | ✅ Ruby | 3.3.0 |
| **ORM** | ✅ ActiveRecord | 8.0 |
| **Auth** | ✅ Devise + OmniAuth | VK, Yandex, Telegram |
| **Queue** | ✅ Solid Queue | Rails 8 native |
| **UI** | ✅ Hotwire | Turbo + Stimulus + Importmap |
| **БД** | ✅ PostgreSQL | 16 (Docker) |
| **CORS** | ✅ rack-cors | Настроен |
| **Authorization** | ✅ Pundit | Подключён |

**Docker:**
- `docker-compose.yml` — 2 сервиса (db, web)
- Redis ❌ не подключён (Solid Queue работает без Redis)

---

## 🗄 2. Модель данных

### 2.1. Сущность "факт проигрывания"

| Параметр | Значение |
|----------|----------|
| **Модель** | `Detection` |
| **Таблица** | `detections` |
| **Отдельная таблица tracks** | ❌ Нет (денормализовано) |

### 2.2. Поля Detection

```ruby
# db/schema.rb
create_table "detections" do |t|
  t.bigint "station_id", null: false          # FK → stations
  t.string "artist", null: false
  t.string "title", null: false
  t.string "artist_title_normalized", null: false
  t.datetime "played_at", null: false
  t.float "confidence", default: 1.0
  t.string "source"                           # "api", "audd", "acrcloud", "playlist"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

### 2.3. Индексы

```ruby
add_index :detections, :station_id
add_index :detections, :played_at
add_index :detections, :artist_title_normalized
add_index :detections, [:station_id, :played_at]  # композитный, не unique
```

**Unique index:** ❌ Отсутствует — требуется миграция.

### 2.4. Нормализация треков

**Текущая реализация (Detection model):**
```ruby
# app/models/detection.rb
before_save :normalize_artist_title

private

def normalize_artist_title
  self.artist_title_normalized = "#{artist.to_s.downcase.strip}-#{title.to_s.downcase.strip}"
end
```

**Формат:** `"artist-title"` (разделитель `-`)

**Документация (Next.js):** `"artist|title"` (разделитель `|`)

**Рекомендация:** Оставить текущий формат (`-`), чтобы не ломать существующий код.

---

## 🔐 3. Модель User и лимиты

### 3.1. Планы доступа

```ruby
# app/models/application_record.rb
PLAN_GUEST = "guest"
PLAN_AUTH  = "auth"
PLAN_PAID  = "paid"
```

### 3.2. Лимиты по планам

| Лимит | Guest | Auth | Paid |
|-------|-------|------|------|
| **Закладки станций** | 3 | ∞ | ∞ |
| **Плейлисты** | 3 | 10 | 50 |
| **Треков в плейлисте** | 10 | 50 | 100 |
| **Trial "Где играет"** | 3/день | 3/день | ∞ |
| **Последний трек** | ❌ | ❌ | ✅ |
| **Плейлист эфира** | ❌ | ❌ | ✅ |
| **Прогноз Soon** | ❌ | ❌ | ✅ |
| **Capture now playing** | ❌ | ❌ | ✅ |

### 3.3. Trial списывается на tune_in

**Код (User model):**
```ruby
def trial_tune_in_remaining
  return nil if paid?
  attempts_today = tune_in_attempts.where("created_at >= ?", Time.current.beginning_of_day).count
  [TRIAL_TUNE_IN_LIMIT - attempts_today, 0].max
end

def can_tune_in?
  return true if paid?
  (trial_tune_in_remaining || 0) > 0
end

def record_tune_in!
  tune_in_attempts.create!
end
```

**Где вызывается:** `Api::TracksController#where_now`

**Когда:** При **GET-запросе** `/api/tracks/:id/where_now` (поиск где играет трек).

---

## 📡 4. API Endpoints

### 4.1. Stations

| Endpoint | Method | Доступ | Описание |
|----------|--------|--------|----------|
| `/api/stations` | GET | Public | Список станций |
| `/api/stations/:id` | GET | Public | Детали станции |
| `/api/stations/:id/last_track` | GET | Paid | Последний трек |
| `/api/stations/:id/playlist` | GET | Paid | Плейлист эфира (30м) |
| `/api/stations/:id/capture_now_playing` | POST | Paid | Захватить текущий трек |

### 4.2. Tracks

| Endpoint | Method | Доступ | Описание |
|----------|--------|--------|----------|
| `/api/tracks/:id/where_now` | GET | Trial | Где играет трек сейчас |
| `/api/tracks/:id/where_soon` | GET | Paid | Прогноз "Будет скоро" |

### 4.3. User

| Endpoint | Method | Доступ | Описание |
|----------|--------|--------|----------|
| `/api/user/bookmarks` | GET/POST | Auth | Закладки станций |
| `/api/user/subscription_status` | GET | Auth | Статус подписки |
| `/api/playlists` | CRUD | Auth | Плейлисты |
| `/api/import_local_data` | POST | Auth | Импорт guest-плейлистов |

---

## 🕒 5. Timezone

**Конфигурация:**
```ruby
# config/application.rb
# config.time_zone = "Central Time (US & Canada)"  # закомментировано
```

**По умолчанию Rails 8:** `UTC`

**В коде:** `Time.current` (конвертирует в UTC для БД).

**Парсер Авторадио:** Требуется явная конвертация **МСК → UTC** при сохранении `played_at`.

**Формула:** `МСК = UTC + 3 часа` → `UTC = МСК - 3 часа`

---

## 📻 6. Авторадио — парсинг плейлиста

### 6.1. Источник

| Параметр | Значение |
|----------|----------|
| **URL** | `https://www.avtoradio.ru/playlist` |
| **Тип контента** | SSR HTML (статический, не требует JS) |
| **Защита от ботов** | Нет CAPTCHA в явном виде |
| **Обновление** | Каждые 1–2 минуты |

### 6.2. HTML структура

```html
<h1 class="mb40">Что за песня звучала 18 февраля 2026 в 11:38?</h1>

<ul class="what-list mb20">
  <li class="fl pr">
    <span class="time fl">11:38</span>
    <div class="what-cover-block pr fl">
      <img src="..." class="cover" width="58" height="58">
    </div>
    <div class="what-name fl">
      <b>30.02</b><br>
      Примером
    </div>
    ...
  </li>
  <li class="fl pr">
    <span class="time fl">11:35</span>
    <div class="what-name fl">
      <b>Високосный Год</b><br>
      Глупое, Несмешное Кино
    </div>
    ...
  </li>
</ul>
```

### 6.3. Селекторы для парсинга

```css
ul.what-list > li                    /* каждый трек */
  span.time                          /* время "11:38" */
  div.what-name > b                  /* артист */
  div.what-name > text после <br>    /* название трека */
```

### 6.4. Парсинг даты

**Формат в заголовке:** `ДД месяц ГОДД в ЧЧ:ММ`

**Пример:** `Что за песня звучала 18 февраля 2026 в 11:38?`

**Regex:**
```ruby
/Что за песня звучала\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+в\s+(\d{2}):(\d{2})/
```

### 6.5. Месяцы на русском

```ruby
MONTHS = {
  "января" => 1, "февраля" => 2, "марта" => 3, "апреля" => 4,
  "мая" => 5, "июня" => 6, "июля" => 7, "августа" => 8,
  "сентября" => 9, "октября" => 10, "ноября" => 11, "декабря" => 12
}.freeze
```

---

## 🧩 7. Jobs и фоновые задачи

### 7.1. Текущее состояние

| Компонент | Статус |
|-----------|--------|
| **Gemfile** | `gem "solid_queue"` ✅ |
| **Redis** | ❌ Нет в docker-compose |
| **Sidekiq** | ❌ Не используется |
| **Solid Queue** | ✅ Подключён, нет конфигов |
| **Jobs** | `PlaylistItemResolutionJob` (существует) |

### 7.2. Существующие Job'ы

```ruby
# app/jobs/playlist_item_resolution_job.rb
class PlaylistItemResolutionJob < ApplicationJob
  def perform(playlist_item_id)
    # Resolve pending playlist item
  end
end
```

### 7.3. Требуемые Job'ы

| Job | Описание | Расписание |
|-----|----------|------------|
| `AvtoradioIngestJob` | Парсинг плейлиста Авторадио | Каждые 1–2 мин |
| `ResolvePendingJob` | Обработка pending playlist items | Каждую минуту |
| `DemoIngestJob` | Демо-данные (опционально) | Каждые 2 мин |

---

## 🔒 8. Дедупликация данных

### 8.1. Текущее состояние

**Прикладной дедуп:** ❌ Отсутствует.

**БД дедуп:** ❌ Unique index отсутствует.

**Риск:** При запуске крона возможны дубликаты при:
- Повторном запуске того же job
- Параллельном выполнении
- Ретраях после ошибок

### 8.2. План защиты

**Уровень 1: Прикладная проверка**
```ruby
existing = Detection.find_by(
  station_id: station.id,
  played_at: played_at,
  artist_title_normalized: track_key
)

unless existing
  Detection.create!(...)
end
```

**Уровень 2: Unique index**
```ruby
# Миграция
add_index :detections, [:station_id, :played_at, :artist_title_normalized],
          unique: true,
          name: "index_detections_unique_station_played_artist_title"
```

**Важно:** Перед добавлением unique index нужно удалить существующие дубли.

---

## 📁 9. Миграции

### 9.1. Список миграций

```
20260218000001_create_users.rb
20260218000002_create_identities.rb
20260218000003_create_stations.rb
20260218000004_create_detections.rb
20260218000005_create_station_bookmarks.rb
20260218000006_create_playlists.rb
20260218000007_create_playlist_items.rb
20260218000008_create_tune_in_attempts.rb
20260218000009_add_stream_url_to_stations.rb
```

### 9.2. Требуемые миграции

| Миграция | Описание | Приоритет |
|----------|----------|-----------|
| `add_unique_index_to_detections.rb` | Unique index + cleanup дублей | Высокий |
| `add_source_to_detections.rb` | Изменить `source` на `not null` | Средний |
| `add_msk_timezone_config.rb` | Настройка timezone МСК | Средний |

---

## 🎯 10. План работ

### Приоритет 1: Парсер Авторадио

- [ ] Создать сервис `app/services/avtoradio_playlist_parser.rb`
- [ ] Создать job `app/jobs/avtoradio_ingest_job.rb`
- [ ] Создать endpoint `app/controllers/api/internal/ingest_controller.rb`
- [ ] Добавить route `post "/api/internal/ingest/avtoradio"`
- [ ] Настроить Solid Queue расписание
- [ ] Тесты: парсинг HTML, конвертация МСК → UTC, дедупликация

### Приоритет 2: Unique index

- [ ] Миграция: поиск и удаление дублей
- [ ] Миграция: добавление unique index
- [ ] Тесты: попытка создания дубля

### Приоритет 3: Solid Queue настройка

- [ ] Добавить конфиг `config/solid_queue.yml`
- [ ] Настроить `config.queue.yml`
- [ ] Обновить `docker-compose.yml` (если нужен Redis)
- [ ] Запуск воркера в Docker
- [ ] Мониторинг очередей

### Приоритет 4: Инвентаризация станций

- [ ] Проверить 9 станций на наличие открытых плейлистов
- [ ] Документировать форматы (HTML/JSON/API)
- [ ] Оценить сложность парсинга для каждой
- [ ] Создать абстрактный базовый парсер

---

## 📎 Приложения

### A. Ссылки на файлы

| Файл | Путь |
|------|------|
| **Gemfile** | `/Gemfile` |
| **Schema** | `/db/schema.rb` |
| **User Model** | `/app/models/user.rb` |
| **Detection Model** | `/app/models/detection.rb` |
| **Stations Controller** | `/app/controllers/api/stations_controller.rb` |
| **Tracks Controller** | `/app/controllers/api/tracks_controller.rb` |
| **Docker Compose** | `/docker-compose.yml` |

### B. ENV переменные

```bash
# Database
DATABASE_URL=postgres://postgres:postgres@db:5432/radiotrack_development

# Secret key base
SECRET_KEY_BASE=dev_secret_key_base_change_in_production

# Host configuration
HOST=0.0.0.0

# Recognition Service (опционально, не используется для парсинга)
RECOGNITION_PROVIDER=audd
AUDD_API_TOKEN=<audd-api-token>
RECOGNITION_CALLBACK_URL=https://your-domain.com/api/recognition/callback

# OAuth
VK_APP_ID=<vk-app-id>
VK_APP_SECRET=<vk-app-secret>
YANDEX_APP_ID=<yandex-app-id>
YANDEX_APP_SECRET=<yandex-app-secret>

# Internal cron secret (для job endpoints)
CRON_SECRET=<generate-random-secret>
```

### C. Полезные команды

```bash
# Запуск Docker
docker compose up -d

# Миграции БД
docker compose exec web bin/rails db:migrate

# Консоль Rails
docker compose exec web bin/rails console

# Запуск Solid Queue
docker compose exec web bin/rails solid_queue:start

# Запуск job в консоли
AvtoradioIngestJob.perform_now

# Проверка дублей в БД
Detection.select(:station_id, :played_at, :artist_title_normalized)
         .group(:station_id, :played_at, :artist_title_normalized)
         .having("COUNT(*) > 1").count
```

---

## ✅ Чек-лист готовности

| Компонент | Статус | Готовность |
|-----------|--------|------------|
| **Модель Detection** | ✅ Существует | 100% |
| **Модель Station** | ✅ Существует | 100% |
| **Модель User** | ✅ Существует | 100% |
| **API Endpoints** | ✅ Существуют | 80% |
| **Парсер Авторадио** | ❌ Не реализован | 0% |
| **Unique index** | ❌ Не добавлен | 0% |
| **Solid Queue** | ⚠️ Частично | 30% |
| **Timezone МСК** | ❌ Не настроен | 0% |
| **Guest плейлисты** | ❌ Не реализованы | 0% |

---

**Синхронизация завершена.** Готов к реализации следующего этапа.
