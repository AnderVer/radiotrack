# Радиоконкурс MVP | Функционал, Стек, Сроки

Дата: февраль 2026
Статус: Брейншторм финализирован
Версия: 1.1

---

## 1. ПРОДУКТОВОЕ ВИДЕНИЕ

### Проблема
Слушатели федеральных радиостанций хотят:
- Узнать, что сейчас играет в прямом эфире
- Найти, на какой станции проигрывается нужный трек
- Сохранить закладки станций и пользовательские плейлисты
- Не пропустить участие в конкурсах благодаря быстрым обновлениям
- Добавить в свой плейлист “тот самый трек”, который звучит сейчас, даже если названия нет под рукой

### Решение
Подписочный сервис “Последний трек в эфире” (рабочее название):
- Бесплатно (без оплаты): 3 станции в избранном, 3 плейлиста × 10 треков локально, “Слушать” 3 раза (trial), без доступа к “последнему треку” и “плейлисту эфира”.
- На подписке: полный доступ к “последнему треку/плейлисту эфира”, расширенные лимиты, real‑time, прогноз “будет скоро”, а также добавление “трека который играет сейчас” в пользовательский плейлист с последующим определением названия.

### Монетизация
- Подписка: 99–199 RUB/месяц (стартовая гипотеза).
- Каналы входа: VK ID, Yandex ID, Telegram Mini App (seamless).
- Trial: 3 попытки “Слушать”, затем paywall.

Доп. опция монетизации (пост‑MVP, требует юр.проработки):
- “Купить/добавить в музыку”: продавать треки/подписки на музыку пользователю по комиссии при наличии соглашений с правообладателями/агрегаторами.
- Примеры того, что такие модели существуют: Apple Services Performance Partners позволяет зарабатывать комиссию на квалифицированных подписках Apple Music и продажах контента по партнёрским ссылкам; 7digital API исторически позиционируется как дающий каталог и “commissions on sales” с интегрированной покупкой. [web:317][web:328]

---

## 2. ФУНКЦИОНАЛ

### MVP (Неделя 1–3/4)

#### Основные фичи
1) Авторизация (обязательна для сохранения данных)
- VK ID OAuth + Yandex ID OAuth
- Telegram Mini App (initData validation на сервере)
- Devise + Identity для привязки методов входа к одному аккаунту

2) Последний трек (платная фича)
- GET /api/stations/:id/last_track → artist, title, played_at
- Доступна только Paid пользователям
- Обновляется каждые 10–15 секунд (polling через Turbo)

3) Плейлист федерального эфира (платная фича)
- GET /api/stations/:id/playlist?range=30m → последние 30 минут треков
- Платный пользователь видит эфирный плейлист

4) Закладки станций
- Гостевой режим: до 3 станций локально
- После логина: импорт в серверную базу; Paid → неограниченно
- API: POST/DELETE /api/station_bookmarks

5) Пользовательские плейлисты
- Гостевой режим: 3 плейлиста × 10 треков локально
- После логина: импорт + Auth → хранение в БД (с лимитами)
- Paid: расширенные лимиты (10–50 плейлистов × 100 треков)
- CRUD: POST /api/playlists, PATCH /api/playlists/:id, DELETE

6) Фича “Где играет” (trial/лимит)
- Трек из плейлиста → “Где она играет?”
- GET /api/tracks/:id/where_now → станции “играет сейчас”
- Лимит: 3 попытки в день без подписки (или 3 попытки вообще, как стартовая гипотеза)
- “Слушать” для MVP: открытие official player_url станции в новой вкладке (без встроенного плеера)

7) Прогноз “Будет скоро (0–30 минут)” (платная фича)
- GET /api/tracks/:id/where_soon?window=30m → станции с ETA на 30 минут
- Baseline‑прогноз: медиана интервалов повторов + сезонность по времени суток
- Confidence: низкая/средняя/высокая
- Только Paid

8) Новая фича: “Добавить трек, который играет сейчас (не зная названия)” (платная фича)
- На экране станции Paid пользователь нажимает “Добавить текущий трек в мой плейлист”.
- Система добавляет в плейлист “черновик” (Pending item), привязанный к станции и времени захвата.
- Через короткое время (до 1–2 минут) item “разрешается”: подставляются artist/title по данным detections/now_playing этой станции.
- Если разрешить не удалось (данных нет/ошибка источника) — показываем “Не удалось определить, попробуйте позже” и оставляем item в статусе unresolved или предлагаем удалить.

#### UI/UX
- Главный экран: избранные станции; для Paid — их последний трек
- Экран станции:
  - Последний трек (Paid)
  - Плейлист эфира за 30 мин (Paid)
  - Кнопка “Добавить текущий трек в мой плейлист” (Paid) → выбор плейлиста → добавление Pending item
  - Кнопка “Добавить в закладки”
- Экран плейлиста:
  - Редактирование
  - Для Pending item: бейдж “Определяем…”; после resolve — показ artist/title
  - “Где играет” (для каждого трека)
- Экран входа: VK/Yandex/TG

#### Технический контроль
- Devise для сессий
- Pundit/Policies для авторизации и лимитов (paywall, trial, тариф)
- Entitlements: trial_tune_in_remaining, plan_code, paid_until, лимиты по тарифам

---

### Итерация 2 (Неделя 4–6, опционально)
- Оплата: Pay gem + Stripe/Braintree (или российский эквайринг/провайдер позже)
- Push‑обновления: Action Cable вместо polling (если нужно)
- Прогноз на 2–3 часа: расширение окна “будет скоро”
- Улучшение resolve‑логики “текущего трека” (несколько кандидатов, confidence)

### Итерация 3+ (пост‑MVP)
- Коммерция треков: партнёрские ссылки/покупка трека/подписки (требует прав/лицензий и анализа юрисдикций)
- B2B: API метаданных/виджеты для партнёров

---

## 3. АРХИТЕКТУРА И СТЕК

Backend
- Rails 8 (Ruby 3.3)
- PostgreSQL
- Background jobs: Active Job + Solid Queue
- WebSockets (позже): Action Cable
- Authentication: Devise + OmniAuth (VK, Yandex) + custom TG initData validation
- Authorization: Pundit
- Payments (позже): Pay gem

Frontend
- Hotwire (Turbo Rails + Stimulus)
- Client storage: localStorage (MVP), IndexedDB (позже)
- Telegram Mini App: TMA.js SDK + server validation

Deployment
- Heroku/Railway/AWS (на выбор)
- Monitoring: Sentry (позже)

---

## 4. ДАННЫЕ И МОДЕЛИ

### Core Models
User
- id, email, encrypted_password, created_at, updated_at
- subscription: paid_until, plan_code, trial_tune_in_remaining
- identities: (VK, Yandex, Telegram)

Identity
- user_id, provider (vk/yandex/telegram), uid, access_token (опционально)

Station
- id, code, title, player_url, description
- now_playing_track_id, now_playing_started_at (опционально)

Detection
- id, station_id, artist, title, artist_title_normalized, played_at, confidence, source

StationBookmark
- user_id, station_id

Playlist
- id, user_id, title, created_at
- local_id (для импорта гостевых плейлистов)

PlaylistItem (обновлено)
- playlist_id
- track_artist (nullable)
- track_title (nullable)
- position
- status: resolved | pending | unresolved
- captured_station_id (nullable) — откуда “сняли” текущий трек
- captured_at (nullable) — время нажатия “добавить текущий трек”
- resolved_detection_id (nullable) — ссылка на Detection, если нашли
- resolved_at (nullable)
- unresolved_reason (nullable)

TuneInAttempt
- user_id, track_id, attempt_number, created_at

---

## 5. API Endpoints

### Auth
- POST /auth/vk/callback
- POST /auth/yandex/callback
- POST /auth/telegram
- POST /import_local_data — импорт гостевых плейлистов

### Stations & Detection
- GET /api/stations
- GET /api/stations/:id/last_track (Paid)
- GET /api/stations/:id/playlist?range=30m (Paid)

### Track Lookup
- GET /api/tracks/:id/where_now (лимитировано trial)
- GET /api/tracks/:id/where_soon?window=30m (Paid)

### New: Capture now playing (Paid)
- POST /api/stations/:id/capture_now_playing
  body: { playlist_id }
  result: { playlist_item_id, status: "pending" }
- POST /api/playlist_items/:id/resolve (опционально, ручной “перепробовать”)

### User Data
- GET /api/user/bookmarks
- GET /api/user/subscription_status
- POST/PATCH/DELETE /api/playlists
- POST/PATCH/DELETE /api/playlist_items

---

## 6. СРОКИ И ФАЗЫ

| Фаза | Длительность | Что делаем |
|------|--------------|-----------|
| Прототип | 2–3 дня | Rails scaffolding, Devise, основные модели |
| Auth | 3–4 дня | VK/Yandex OAuth, Telegram seamless, Identity |
| Detection & Last Track | 4–5 дней | Инжест плейлиста, now_playing, API, Turbo UI |
| Плейлисты & Импорт | 3–4 дня | localStorage, серверные плейлисты, импорт |
| “Где играет” | 2–3 дня | Поиск трека, trial‑лимит, редирект на плеер |
| “Добавить текущий трек” | 2–3 дня | Pending items, resolve job, UI бейджи |
| Прогноз “Будет скоро” | 3–4 дня | Baseline‑алгоритм, confidence scoring |
| Тестирование & Полировка | 3–4 дня | E2E, UX, антифрод, индексы |
| Deploy | 1–2 дня | Production setup, мониторинг, документация |
| Итого MVP | 23–32 дня | 3–5 недель |

---

## 7. ТАРИФЫ И ENTITLEMENTS

Guest (без логина)
- Нет: последний трек, плейлист эфира, прогноз “скоро”, capture now playing
- Да: 3 станции в закладках (локально)
- Да: 3 плейлиста × 10 треков (локально)
- Да: 3 попытки “Слушать/Где играет” (trial)

Auth (залогинен, без оплаты)
- Нет: последний трек, плейлист эфира, прогноз “скоро”, capture now playing
- Да: закладки и плейлисты в БД (лимиты выше гостя)
- Да: расширенный trial (по решению)

Paid (подписка активна)
- Да: последний трек, плейлист эфира
- Да: прогноз “будет скоро” на 30 минут
- Да: capture now playing (добавить текущий трек в плейлист с последующим определением)
- Да: расширенные лимиты по плейлистам/трекам, безлимит “Где играет”

---

## 8. CRITICAL PATH И РИСКИ (добавлено)

Риск: “Добавить текущий трек” может иногда неверно разрешиться или не разрешиться
- Причины: задержки источника, разрывы в metadata, нет played_at/shift по времени
- Решения MVP:
  - Матч по окну времени (например, captured_at ± 90 сек) и по станции
  - Если несколько кандидатов — выбрать самый близкий по времени
  - Если не найдено — пометить unresolved и дать кнопку “повторить”/“удалить”

---

## 9. SUCCESS METRICS (MVP)

- Конверсия Paid в “capture now playing” (сколько раз нажимают и сколько успешно resolved)
- Resolve success rate (доля pending, ставших resolved за 2 минуты)
- Trial → Paid после исчерпания 3 “Слушать”
- Retention D1/D7/D30

---

## 10. NEXT STEPS (после MVP)

Неделя 4–6
- Оплата
- Push‑обновления
- Прогноз 2–3 часа
- Улучшение resolve‑алгоритма

Месяц 2+
- A/B тесты тарифов и trial
- Увеличение числа станций
- Партнёрские интеграции и коммерция треков (если юридически и коммерчески целесообразно)

---

Документ версии 1.1 | Готово
