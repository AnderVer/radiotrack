# 🎉 M9 — Вторая станция (Europa Plus): Итоги реализации

**Дата:** 19 февраля 2026 г.
**Статус:** ✅ Реализовано

---

## 📋 Резюме

Реализована вторая радиостанция — **Европа Плюс** — с использованием JSON API для получения плейлиста.

### Выполненные задачи

| Задача | Статус | Файлы |
|--------|--------|-------|
| **Анализ API Европы Плюс** | ✅ | docs/STATIONS_INVENTORY.md |
| **EuropaPlusPlaylistParser** | ✅ | app/services/europa_plus_playlist_parser.rb |
| **EuropaPlusIngestJob** | ✅ | app/jobs/europa_plus_ingest_job.rb |
| **Обновление Parser Factory** | ✅ | app/services/playlist_parser_factory.rb |
| **Тесты парсера** | ✅ | test/services/europa_plus_playlist_parser_test.rb |
| **Fixture JSON** | ✅ | test/fixtures/files/europa_plus_playlist.json |

**Итого:** 6 из 6 задач M9 выполнены (100%).

---

## 🔧 Технические детали

### 1. Europa Plus API

**Endpoint:** `https://europaplus.ru/api/playlist`

**Метод:** GET

**Формат ответа:** JSON

**Структура ответа:**
```json
{
  "tracks": [
    {
      "artist": "The Weeknd",
      "title": "Blinding Lights",
      "played_at": "2026-02-19T12:30:00Z",
      "duration": 200
    }
  ]
}
```

**Особенности:**
- Прямой доступ к JSON API (без JavaScript)
- Поддержка разных форматов timestamp:
  - ISO 8601: `"2026-02-19T12:30:00Z"`
  - Unix timestamp: `1708347400`
  - Unix timestamp (string): `"1708347400"`
- Разные структуры JSON (tracks/items/data/result)
- Fallback на HTML парсинг (если API возвращает HTML)

---

### 2. EuropaPlusPlaylistParser

**Файл:** `app/services/europa_plus_playlist_parser.rb`

**Наследование:** `BasePlaylistParser`

**Основные методы:**

```ruby
# Fetch и parse JSON из API
def fetch_and_parse(url: nil)
  # Возвращает массив track hash
end

# Parse JSON или HTML
def parse(html: nil, json: nil)
  # Поддержка разных форматов
end

# URL API endpoint
def playlist_url
  "https://europaplus.ru/api/playlist"
end
```

**Ключевые особенности:**
- Парсинг JSON с поддержкой разных структур
- Извлечение полей с fallback (artist/artist_name/performer)
- Конвертация timestamp в UTC
- Fallback на HTML парсинг
- Логирование ошибок

---

### 3. EuropaPlusIngestJob

**Файл:** `app/jobs/europa_plus_ingest_job.rb`

**Наследование:** `ApplicationJob`

**Очередь:** `:default`

**Retry:** 3 попытки (exponential backoff)

**Алгоритм работы:**
1. Найти станцию по коду `europe_plus`
2. Вызвать парсер для получения треков
3. Для каждого трека:
   - Проверить наличие дублей (app-level dedup)
   - Создать Detection (если не существует)
4. Вернуть статистику: created/skipped/total

**Идемпотентность:**
```ruby
# Проверка перед созданием
existing = Detection.find_by(
  station_id: station.id,
  played_at: track[:played_at],
  artist_title_normalized: key
)

# Пропуск дубля
return false if existing
```

---

### 4. Parser Factory

**Файл:** `app/services/playlist_parser_factory.rb`

**Обновления:**
```ruby
PARSER_MAP = {
  "avtoradio" => AvtoradioPlaylistParser,
  "europe_plus" => EuropaPlusPlaylistParser  # ← Добавлено
}.freeze
```

**Использование:**
```ruby
parser = PlaylistParserFactory.for_station("europe_plus")
tracks = parser.fetch_and_parse
```

---

### 5. Тесты

**Файл:** `test/services/europa_plus_playlist_parser_test.rb`

**Количество тестов:** 15

**Покрытые сценарии:**
- ✅ Парсинг JSON response с треками
- ✅ Пустой массив треков
- ✅ Отсутствующий ключ "tracks"
- ✅ Разные JSON структуры (items/data)
- ✅ Пропуск треков без artist
- ✅ Пропуск треков без title
- ✅ Unix timestamp (integer)
- ✅ Unix timestamp (string)
- ✅ ISO 8601 timestamp
- ✅ Invalid JSON structure (ParseError)
- ✅ playlist_url returns correct endpoint
- ✅ station_name returns correct name
- ✅ normalize_track_key consistency
- ✅ create_track_hash structure

**Fixture:**
- `test/fixtures/files/europa_plus_playlist.json` — пример JSON ответа API

---

## 📊 Сравнение с Авторадио

| Характеристика | Авторадио | Европа Плюс |
|----------------|------------|-------------|
| **Формат** | HTML | JSON API |
| **URL** | `/playlist` | `/api/playlist` |
| **JS нужен** | ❌ Нет | ❌ Нет |
| **Парсер** | `AvtoradioPlaylistParser` | `EuropaPlusPlaylistParser` |
| **Сложность** | Easy | Medium |
| **Конвертация времени** | МСК→UTC | UTC (готово) |
| **Дедупликация** | ✅ | ✅ |
| **Тесты** | ✅ 10 тестов | ✅ 15 тестов |

---

## 🚀 Как использовать

### Ручной запуск

```bash
# В Docker
docker compose exec web bin/rails console

# Запуск ingest
EuropaPlusIngestJob.perform_now

# Проверка результатов
Detection.where(source: "europaplus_api").count
Detection.where(source: "europaplus_api").last(5)
```

### Автоматический запуск (Solid Queue)

Добавьте recurring task в `config/application.rb`:

```ruby
Rails.application.config.solid_queue_recurring_tasks = [
  {
    class: "AvtoradioIngestJob",
    queue: "default",
    schedule: "*/2 * * * *"  # Каждые 2 минуты
  },
  {
    class: "EuropaPlusIngestJob",
    queue: "default",
    schedule: "*/2 * * * *"  # Каждые 2 минуты
  }
]
```

Перезапустите Solid Queue:
```bash
docker compose restart web
```

---

## 📈 Метрики

### Код

| Компонент | Файлы | Строки |
|-----------|-------|--------|
| Parser | 1 | ~230 |
| Job | 1 | ~120 |
| Tests | 1 | ~140 |
| Fixture | 1 | ~30 |
| Factory (update) | 1 | ~5 |
| **Итого** | **5** | **~525** |

### Тесты

| Метрика | Значение |
|---------|----------|
| Количество тестов | 15 |
| Покрытие | JSON parsing, timestamps, edge cases |
| Fixture файлы | 1 (JSON) |

---

## 🎯 Готовность к продакшену

| Компонент | Готовность | Примечание |
|-----------|------------|------------|
| Parser | 100% | JSON API + HTML fallback |
| Job | 100% | Retry, dedup, logging |
| Tests | 100% | 15 тестов |
| Documentation | 100% | STATIONS_INVENTORY.md обновлён |
| Recurring schedule | ⏸ | Требуется настройка |

**Общая готовность:** 90% (требуется настройка расписания)

---

## 📝 Следующие шаги

### Приоритет 1: Настройка расписания

1. [ ] Добавить EuropaPlusIngestJob в `config/application.rb`
2. [ ] Настроить интервал (каждые 2-5 минут)
3. [ ] Протестировать recurring task

### Приоритет 2: Анализ остальных станций

1. [ ] Energy (`https://www.energyfm.ru/`)
2. [ ] Хит FM (`https://hitfm.ru/`)
3. [ ] НАШЕ Радио (`https://nashe.ru/`)
4. [ ] Радио Рекорд (`https://radiorecord.ru/`)
5. [ ] Юмор FM (`https://yumorfm.ru/`)

### Приоритет 3: Улучшения

1. [ ] Мониторинг ошибок парсинга
2. [ ] Метрики количества созданных detections
3. [ ] Алерты при отсутствии данных

---

## 🎁 Бонусы

### Архитектурные решения

1. **Базовый класс `BasePlaylistParser`**
   - Общие методы для всех парсеров
   - Timezone конвертация
   - Нормализация ключей
   - User-Agent headers

2. **Factory pattern**
   - Единая точка создания парсеров
   - Легко добавлять новые станции

3. **Idempotent Jobs**
   - App-level dedup
   - DB-level unique index
   - Безопасный retry

4. **Flexible JSON parsing**
   - Поддержка разных структур
   - Fallback на HTML
   - Graceful error handling

---

## 📞 Контакты

**Вопросы и предложения:**
- GitHub: https://github.com/AnderVer/radiotrack
- Документация: `docs/STATIONS_INVENTORY.md`

---

<div align="center">

**RadioTrack** — M9 (Europa Plus) ✅ | 2 из 10 станций реализовано 🚀

[![Rails 8.0](https://img.shields.io/badge/Rails-8.0-blue.svg)](https://rubyonrails.org/)
[![Ruby 3.3.0](https://img.shields.io/badge/Ruby-3.3.0-red.svg)](https://www.ruby-lang.org/)
[![License MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>
