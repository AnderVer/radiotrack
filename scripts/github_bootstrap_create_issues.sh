#!/usr/bin/env bash
set -euo pipefail

REPO="AnderVer/radiotrack"

# ----- helpers -----
ensure_label() {
  local name="$1"
  local color="$2"
  local desc="$3"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null 2>&1 || true
}

milestone_number() {
  local title="$1"
  gh api --repo "$REPO" \
    -H "Accept: application/vnd.github+json" \
    "/repos/${REPO}/milestones?state=all&per_page=100" \
    --jq ".[] | select(.title==\"${title}\") | .number" | head -n 1
}

ensure_milestone() {
  local title="$1"
  local description="$2"
  local num
  num="$(milestone_number "$title" || true)"
  if [[ -z "${num}" ]]; then
    gh api --repo "$REPO" \
      -H "Accept: application/vnd.github+json" \
      -X POST "/repos/${REPO}/milestones" \
      -f "title=${title}" \
      -f "description=${description}" >/dev/null
  fi
}

create_issue() {
  local title="$1"
  local milestone="$2"
  local labels_csv="$3"
  local body="$4"

  gh issue create \
    --repo "$REPO" \
    --title "$title" \
    --milestone "$milestone" \
    --label "$labels_csv" \
    --body "$body"
}

# ----- milestones -----
ensure_milestone "M0 Bootstrap" "Docker/ENV/DB smoke; базовая воспроизводимость локального запуска."
ensure_milestone "M1 Avtoradio ingest" "Парсер Авторадио + ingest job + идемпотентность."
ensure_milestone "M2 Dedup" "Cleanup дублей + unique index на detections."
ensure_milestone "M3 Solid Queue schedule" "Конфиги Solid Queue + периодический запуск ingest."
ensure_milestone "M4 UI (Hotwire)" "MVP UI на Hotwire/Turbo вокруг станций и detections."
ensure_milestone "M5 OAuth" "VK/Yandex OmniAuth + Identity linking + статус подписки."
ensure_milestone "M6 Recognition fallback" "AudD как опциональный fallback."
ensure_milestone "M7 PWA" "Manifest и минимальная PWA-обвязка."
ensure_milestone "M8 Tests" "Критические тесты: парсер, timezone, дедуп, лимиты."
ensure_milestone "M9 Stations inventory" "Инвентаризация источников плейлистов + базовая архитектура парсеров."

# ----- labels -----
# colors are arbitrary but fixed; feel free to change later
ensure_label "type:feature" "1F6FEB" "Feature work"
ensure_label "type:chore"   "6E7781" "Maintenance / chores"
ensure_label "type:bug"     "D1242F" "Bug"
ensure_label "type:test"    "8250DF" "Tests"
ensure_label "type:docs"    "0E8A16" "Documentation"

ensure_label "area:infra"  "0B3D91" "Docker, env, bootstrapping"
ensure_label "area:db"     "5319E7" "Migrations, indexes, schema"
ensure_label "area:parser" "0052CC" "Playlist parsers"
ensure_label "area:jobs"   "C2E0C6" "Background jobs, Solid Queue"
ensure_label "area:api"    "FBCA04" "API controllers/endpoints"
ensure_label "area:ui"     "BFDADC" "Hotwire/Turbo UI"
ensure_label "area:auth"   "F9D0C4" "Devise/OmniAuth"
ensure_label "area:pwa"    "D4C5F9" "PWA/manifest"

ensure_label "priority:P0" "B60205" "Blocker / MVP critical"
ensure_label "priority:P1" "D93F0B" "High"
ensure_label "priority:P2" "0E8A16" "Normal"

ensure_label "station:avtoradio" "1D76DB" "Avtoradio station work"
ensure_label "station:europaplus" "E74C3C" "Europa Plus station work"

# ----- issues: M0 -----
create_issue \
  "Docs: быстрый старт (Docker/DB/Queue)" \
  "M0 Bootstrap" \
  "type:docs,area:infra,priority:P0" \
"Цель: зафиксировать единую воспроизводимую инструкцию локального запуска через Docker.

Acceptance criteria:
- В README есть команды:
  - docker compose up -d
  - docker compose exec web bin/rails db:migrate
  - docker compose exec web bin/rails console
  - docker compose exec web bin/rails solid_queue:start
- Отдельно указано, что Redis не нужен (Solid Queue без Redis).

Checklist:
- [ ] Обновить/добавить раздел \"Local development (Docker)\".
- [ ] Добавить раздел \"Running Solid Queue\".
- [ ] Проверить инструкцию на чистом окружении."

create_issue \
  "Infra: добавить/обновить .env.example (полный список ENV)" \
  "M0 Bootstrap" \
  "type:chore,area:infra,priority:P0" \
"Цель: добавить .env.example со всеми переменными окружения, ожидаемыми приложением.

Acceptance criteria:
- .env.example содержит:
  DATABASE_URL, SECRET_KEY_BASE, HOST,
  RECOGNITION_PROVIDER, AUDD_API_TOKEN, RECOGNITION_CALLBACK_URL,
  VK_APP_ID, VK_APP_SECRET, YANDEX_APP_ID, YANDEX_APP_SECRET,
  CRON_SECRET
- В файле только примерные значения (без реальных секретов).

Checklist:
- [ ] Создать/обновить .env.example.
- [ ] Обновить README: как применить env локально."

create_issue \
  "DB: seeds — 10 станций для MVP (Avtoradio + 9)" \
  "M0 Bootstrap" \
  "type:feature,area:db,priority:P0" \
"Цель: сделать db/seeds.rb, который создаёт 10 станций для MVP.

Acceptance criteria:
- bin/rails db:seed создаёт 10 станций.
- Seed идемпотентен (повторный запуск не множит записи).
- У станций заполнены минимальные поля для UI и ingest (например name, stream_url, если используется).

Checklist:
- [ ] Добавить список станций в seeds.
- [ ] Проверить на чистой БД в Docker."

create_issue \
  "Smoke: Detection работает (создать Station + Detection + прочитать назад)" \
  "M0 Bootstrap" \
  "type:test,area:db,priority:P0" \
"Цель: минимальная проверка, что модель Detection и схема валидны.

Acceptance criteria:
- Есть spec (или minitest), который:
  - создаёт Station
  - создаёт Detection с artist/title/played_at/source
  - проверяет, что artist_title_normalized заполнился
- Тест проходит локально в Docker.

Checklist:
- [ ] Добавить spec модели Detection.
- [ ] Зафиксировать команду запуска тестов в README."

# ----- issues: M1 -----
create_issue \
  "Parser(Avtoradio): AvtoradioPlaylistParser (CSS selectors)" \
  "M1 Avtoradio ingest" \
  "type:feature,area:parser,priority:P0,station:avtoradio" \
"Цель: сервис, который парсит HTML плейлиста Авторадио по селекторам.

Контракт:
- call(html:) -> массив элементов с time_str, artist, title

Acceptance criteria:
- Парсинг:
  - ul.what-list > li (каждый трек)
  - span.time (HH:MM)
  - div.what-name > b (артист)
  - текст после <br> в div.what-name (название)
- На пустом/сломавшемся HTML возвращает [] и пишет понятный лог/ошибку.

Checklist:
- [ ] Реализовать разбор списка li.
- [ ] Реализовать извлечение времени/артиста/названия."

create_issue \
  "Parser(Avtoradio): дата из заголовка + ru months map" \
  "M1 Avtoradio ingest" \
  "type:feature,area:parser,priority:P0,station:avtoradio" \
"Цель: парсить дату из заголовка страницы Авторадио (ru-месяцы).

Acceptance criteria:
- Реализован MONTHS map (\"февраля\" => 2 и т.д.).
- Regex/логика извлекает день/месяц/год из заголовка.
- При ошибке парсинга ingest не пишет мусор (явный лог/исключение).

Checklist:
- [ ] Добавить MONTHS map.
- [ ] Добавить метод extract_date_from_header(text)."

create_issue \
  "Timezone(Avtoradio): МСК → UTC для played_at" \
  "M1 Avtoradio ingest" \
  "type:feature,area:parser,priority:P0,station:avtoradio" \
"Цель: played_at хранится в UTC, входные данные Авторадио — МСК, нужна конвертация.

Acceptance criteria:
- Есть метод, который из (date, time_str) строит UTC-time.
- Есть unit-тест: МСК 11:38 -> UTC 08:38.

Checklist:
- [ ] Использовать ActiveSupport::TimeZone[\"Europe/Moscow\"].
- [ ] Добавить unit-тест конвертации."

create_issue \
  "Job: AvtoradioIngestJob (fetch + parse + persist detections)" \
  "M1 Avtoradio ingest" \
  "type:feature,area:jobs,area:parser,priority:P0,station:avtoradio" \
"Цель: job скачивает https://www.avtoradio.ru/playlist, парсит и пишет detections.

Acceptance criteria:
- AvtoradioIngestJob.perform_now создаёт Detection записи для станции Авторадио.
- У записей проставлен source = \"playlist\" (и confidence при необходимости).
- Ошибки сети/пустой HTML обработаны (лог + безопасное завершение).

Checklist:
- [ ] Fetch HTML.
- [ ] Parse HTML.
- [ ] Persist Detection."

create_issue \
  "Ingest: идемпотентность (app-level dedup по station_id/played_at/artist_title_normalized)" \
  "M1 Avtoradio ingest" \
  "type:feature,area:db,area:parser,priority:P0,station:avtoradio" \
"Цель: повторный запуск ingest не должен множить detections (до unique index и после него).

Acceptance criteria:
- Перед create! выполняется find_by(station_id, played_at, artist_title_normalized) и пропуск, если найдено.
- 2 запуска AvtoradioIngestJob подряд (на одинаковом HTML) -> одинаковое число записей.
- Есть тест/скрипт проверки.

Checklist:
- [ ] Реализовать прикладной дедуп.
- [ ] Добавить интеграционный тест или воспроизводимый сценарий."

create_issue \
  "API internal (опционально): POST /api/internal/ingest/avtoradio под CRON_SECRET" \
  "M1 Avtoradio ingest" \
  "type:feature,area:api,priority:P2,station:avtoradio" \
"Цель: internal endpoint для ручного/внешнего триггера ingest (если нужен).

Acceptance criteria:
- Endpoint защищён CRON_SECRET.
- Endpoint запускает ingest и возвращает ok/ошибка.

Checklist:
- [ ] Controller + route.
- [ ] Проверка секрета."

# ----- issues: M2 -----
create_issue \
  "DB: rake task найти дубли detections по (station_id, played_at, artist_title_normalized)" \
  "M2 Dedup" \
  "type:chore,area:db,priority:P0" \
"Цель: быстро находить дубли перед добавлением unique index.

Acceptance criteria:
- Есть rake task (или runner script), который выводит количество групп дублей и примеры.
- Запрос основан на group/having COUNT(*) > 1.

Checklist:
- [ ] Реализовать запрос.
- [ ] Документировать запуск."

create_issue \
  "DB migration: cleanup дублей detections (до unique index)" \
  "M2 Dedup" \
  "type:feature,area:db,priority:P0" \
"Цель: удалить существующие дубли перед unique index.

Acceptance criteria:
- Миграция удаляет дубли детерминированно (например, оставляет минимальный id).
- Миграция не падает по памяти (батчи или SQL).
- Логирует, сколько удалено.

Checklist:
- [ ] Написать миграцию cleanup.
- [ ] Прогнать на dev данных."

create_issue \
  "DB migration: unique index на detections (station_id, played_at, artist_title_normalized)" \
  "M2 Dedup" \
  "type:feature,area:db,priority:P0" \
"Цель: добавить уникальность на уровне БД.

Acceptance criteria:
- Добавлен индекс:
  index_detections_unique_station_played_artist_title
  UNIQUE (station_id, played_at, artist_title_normalized)
- Попытка вставить дубль вызывает ошибку уникальности.
- Есть тест на DB constraint.

Checklist:
- [ ] Миграция add_index unique.
- [ ] Тест на ошибку уникальности."

# ----- issues: M3 -----
create_issue \
  "Solid Queue: добавить config/solid_queue.yml" \
  "M3 Solid Queue schedule" \
  "type:feature,area:jobs,priority:P1" \
"Цель: зафиксировать конфиг Solid Queue в репозитории.

Acceptance criteria:
- В проекте есть config/solid_queue.yml.
- В README описан запуск воркера: bin/rails solid_queue:start

Checklist:
- [ ] Добавить файл конфига.
- [ ] Проверить запуск в Docker."

create_issue \
  "Solid Queue: добавить/обновить config/queue.yml" \
  "M3 Solid Queue schedule" \
  "type:feature,area:jobs,priority:P1" \
"Цель: зафиксировать очереди/приоритеты.

Acceptance criteria:
- В проекте есть config/queue.yml.
- Job'ы используют ожидаемые очереди (если применимо).

Checklist:
- [ ] Добавить/обновить config/queue.yml.
- [ ] Документация."

create_issue \
  "Solid Queue recurring: AvtoradioIngestJob каждые 1–2 минуты" \
  "M3 Solid Queue schedule" \
  "type:feature,area:jobs,priority:P1,station:avtoradio" \
"Цель: включить периодический запуск ingest Авторадио каждые 1–2 минуты.

Acceptance criteria:
- При запущенном воркере job выполняется регулярно.
- Дубли не появляются (app dedup + unique index).

Checklist:
- [ ] Настроить recurring.
- [ ] Добавить минимальные логи/метрики (сколько записали/пропустили)."

create_issue \
  "Jobs: ResolvePendingJob — решить нужен ли в MVP (и реализовать/отложить)" \
  "M3 Solid Queue schedule" \
  "type:chore,area:jobs,priority:P2" \
"Цель: подтвердить необходимость ResolvePendingJob.

Acceptance criteria:
- Принято решение: делаем сейчас или откладываем.
- Если делаем: есть job + расписание (каждую минуту).

Checklist:
- [ ] Аудит модели PlaylistItem и статусов.
- [ ] Реализовать или закрыть как not planned."

# ----- issues: M4 -----
create_issue \
  "UI: главная страница (список станций)" \
  "M4 UI (Hotwire)" \
  "type:feature,area:ui,priority:P1" \
"Цель: публичная главная страница со списком станций.

Acceptance criteria:
- Отображаются станции из БД.
- Переход на страницу станции работает.

Checklist:
- [ ] Controller + view.
- [ ] Turbo-friendly навигация."

create_issue \
  "UI: страница станции (последние detections, время в МСК)" \
  "M4 UI (Hotwire)" \
  "type:feature,area:ui,priority:P1" \
"Цель: страница станции показывает последние N detections.

Acceptance criteria:
- Список detections отсортирован по played_at desc.
- Время отображается в МСК (конвертация UTC->MSK на выводе).
- Пустое состояние обработано.

Checklist:
- [ ] Query + view.
- [ ] Конвертация timezone на выводе."

create_issue \
  "UI: paywall CTA для Paid функций (playlist/last_track/capture)" \
  "M4 UI (Hotwire)" \
  "type:feature,area:ui,priority:P2" \
"Цель: UI-обвязка вокруг платных endpoints.

Acceptance criteria:
- Non-paid видит CTA вместо данных.
- Paid видит данные.

Checklist:
- [ ] Компонент paywall.
- [ ] Проверка статуса пользователя."

# ----- issues: M5 -----
create_issue \
  "OAuth: VK вход + Identity linking" \
  "M5 OAuth" \
  "type:feature,area:auth,priority:P1" \
"Цель: настроить OmniAuth VK и связку Identity -> User.

Acceptance criteria:
- Логин VK работает в dev.
- Identity создаётся/находится корректно.
- User создаётся/привязывается корректно.

Checklist:
- [ ] Provider config.
- [ ] Callback flow.
- [ ] Проверить ENV VK_APP_ID/VK_APP_SECRET."

create_issue \
  "OAuth: Yandex вход + Identity linking" \
  "M5 OAuth" \
  "type:feature,area:auth,priority:P1" \
"Цель: настроить OmniAuth Yandex и связку Identity -> User.

Acceptance criteria:
- Логин Yandex работает в dev.
- Identity создаётся/находится корректно.
- User создаётся/привязывается корректно.

Checklist:
- [ ] Provider config.
- [ ] Callback flow.
- [ ] Проверить ENV YANDEX_APP_ID/YANDEX_APP_SECRET."

create_issue \
  "API+UI: /api/user/subscription_status + отображение статуса" \
  "M5 OAuth" \
  "type:feature,area:api,area:ui,priority:P2" \
"Цель: показать пользователю текущий план и статус подписки.

Acceptance criteria:
- Endpoint возвращает план (guest/auth/paid) и полезные поля (например остаток trial).
- В UI профиля отображается статус.

Checklist:
- [ ] Контракт ответа.
- [ ] Простая страница профиля."

# ----- issues: M6 -----
create_issue \
  "Recognition: ENV wiring + базовый клиент AudD (fallback, не включать в MVP поток)" \
  "M6 Recognition fallback" \
  "type:feature,area:api,priority:P2" \
"Цель: подготовить AudD как опциональный fallback.

Acceptance criteria:
- Если recognition не включён, отсутствие токена не ломает приложение.
- Базовый клиент с таймаутами/ошибками готов.

Checklist:
- [ ] Клиент.
- [ ] Документация ENV.
- [ ] Переключатель RECOGNITION_PROVIDER."

# ----- issues: M7 -----
create_issue \
  "PWA: manifest.webmanifest + иконки (192/512)" \
  "M7 PWA" \
  "type:feature,area:pwa,priority:P2" \
"Цель: минимальная PWA-обвязка (манифест + иконки).

Acceptance criteria:
- Манифест отдается корректно.
- Иконки доступны.
- start_url корректный.

Checklist:
- [ ] Добавить manifest.
- [ ] Добавить иконки.
- [ ] Подключить в layout."

# ----- issues: M8 -----
create_issue \
  "Test: AvtoradioPlaylistParser (HTML fixture → tracks)" \
  "M8 Tests" \
  "type:test,area:parser,priority:P1,station:avtoradio" \
"Цель: тест парсера без сети на HTML-фикстуре.

Acceptance criteria:
- Фикстура HTML лежит в spec/fixtures.
- Тест проверяет минимум 2 трека (время/артист/название).

Checklist:
- [ ] Добавить fixture.
- [ ] Написать spec."

create_issue \
  "Test: МСК→UTC конвертация played_at" \
  "M8 Tests" \
  "type:test,area:parser,priority:P1" \
"Цель: зафиксировать timezone-конвертацию тестом.

Acceptance criteria:
- Тест проверяет смещение МСК->UTC (-3 часа).

Checklist:
- [ ] Unit test конвертации."

create_issue \
  "Test: Unique index защита (DB-level) для detections" \
  "M8 Tests" \
  "type:test,area:db,priority:P1" \
"Цель: тест на уникальность после добавления unique index.

Acceptance criteria:
- Попытка создать дубль падает на DB уровне (ошибка уникальности).

Checklist:
- [ ] Spec/тест на уникальность."

create_issue \
  "Test: Trial tune_in списание на GET /api/tracks/:id/where_now" \
  "M8 Tests" \
  "type:test,area:api,priority:P1" \
"Цель: зафиксировать логику trial-limits на where_now.

Acceptance criteria:
- Запрос создаёт TuneInAttempt и уменьшает остаток.
- При превышении лимита guest/auth получает отказ.
- Paid проходит без ограничений.

Checklist:
- [ ] Тест guest/auth/paid.
- [ ] Проверка попыток за день."

# ----- issues: M9 -----
create_issue \
  "Inventory: 9 станций — источники плейлистов (URL/тип/антибот) + оценка сложности" \
  "M9 Stations inventory" \
  "type:docs,area:parser,priority:P2" \
"Цель: собрать таблицу источников по 9 станциям.

Acceptance criteria:
- docs/stations_inventory.md с таблицей по всем 9 станциям:
  URL, формат (HTML/JSON/API), нужен ли JS, антибот, частота обновления, сложность (easy/medium/hard).
- Отметка: берём в MVP или откладываем.

Checklist:
- [ ] Заполнить таблицу.
- [ ] Принять решение по каждой станции."

create_issue \
  "Parser architecture: базовый интерфейс парсеров + 2-я простая станция" \
  "M9 Stations inventory" \
  "type:feature,area:parser,priority:P2" \
"Цель: масштабируемая архитектура парсеров после Авторадио.

Acceptance criteria:
- Есть базовый контракт (fetch/parse/to_detections).
- Реализован второй парсер для \"easy\" станции из инвентаризации.
- Есть тест парсера.

Checklist:
- [ ] Добавить базовый интерфейс.
- [ ] Выбрать станцию №2.
- [ ] Реализовать парсер и тест."

echo "✅ Все GitHub issues созданы успешно!"
