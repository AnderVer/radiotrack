# RadioTrack MVP

Сервис отслеживания треков в радиоэфире для участников радиоконкурсов.

**Целевая аудитория:** Слушатели радиостанций, участвующие в эфирных конкурсах (угадать трек перед конкурсом).

**Платформы:** Web + PWA + Telegram Mini App (единый код)

## Стек

- **Backend:** Ruby 3.3, Rails 8.0, PostgreSQL 16
- **Frontend:** Hotwire (Turbo + Stimulus) — работает как PWA и TMA
- **Auth:** Devise + OmniAuth (VK, Yandex, Telegram)
- **Recognition:** AudD.io / ACRCloud (внешний сервис распознавания)
- **Deployment:** Docker

## Быстрый старт

### Требования

- Docker Desktop
- Git

### Установка

1. Клонируйте репозиторий:
```bash
cd "c:\Акселерация Обучение\AutoRadio\RadioTrack"
```

2. Скопируйте .env.example в .env и заполните:
```bash
cp .env.example .env
# Отредактируйте .env, добавив API ключи
```

3. Запустите Docker-контейнеры:
```bash
docker --context desktop-linux compose up -d
```

4. Инициализируйте базу данных:
```bash
docker --context desktop-linux compose exec web bin/rails db:create db:migrate db:seed
```

5. Откройте http://localhost:3000

## Радиостанции (MVP)

10 станций для MVP:
- Авторадио
- Европа Плюс
- DFM
- Love Radio
- Русское Радио
- Energy
- Хит FM
- НАШЕ Радио
- Радио Рекорд
- Юмор FM

## Функционал MVP

### Бесплатно (Guest)
- 3 станции в закладках
- 3 плейлиста × 10 треков
- 3 попытки "Где играет" (trial)
- Просмотр "последнего трека" с задержкой

### Auth (залогинен)
- Закладки и плейлисты в БД
- Расширенные лимиты
- История просмотров

### Paid (подписка: 150₽/мес или 1500₽/год)
- Последний трек в реальном времени (обновление 5-10 сек)
- Плейлист эфира за 30 минут
- Прогноз "Будет скоро" (0-30 минут)
- Добавить текущий трек в плейлист
- Расширенные лимиты
- Безлимит "Где играет"

## API Endpoints

### Recognition (внешний сервис → наш API)
- `POST /api/recognition/callback` — webhook от AudD/ACRCloud

### Stations
- `GET /api/stations` — список станций
- `GET /api/stations/:id/last_track` — последний трек (Paid)
- `GET /api/stations/:id/playlist?range=30m` — плейлист эфира (Paid)
- `POST /api/stations/:id/capture_now_playing` — захват текущего трека (Paid)

### Tracks
- `GET /api/tracks/:id/where_now` — где играет сейчас (trial limited)
- `GET /api/tracks/:id/where_soon?window=30m` — прогноз (Paid)

### User Data
- `GET/POST /api/user/bookmarks` — закладки
- `GET /api/user/subscription_status` — статус подписки
- `CRUD /api/playlists` — плейлисты
- `CRUD /api/playlists/:id/items` — элементы плейлиста

### Import
- `POST /api/import_local_data` — импорт гостевых данных

## Разработка

### Запуск в режиме разработки
```bash
docker --context desktop-linux compose up -d
docker --context desktop-linux compose exec web bin/rails server -b 0.0.0.0
```

### Миграции
```bash
docker --context desktop-linux compose exec web bin/rails db:migrate
```

### Консоль Rails
```bash
docker --context desktop-linux compose exec web bin/rails console
```

### Тесты
```bash
docker --context desktop-linux compose exec web bin/rails test
```

### Логирование
```bash
docker --context desktop-linux compose logs -f web
```

## Переменные окружения

```env
# Database
DATABASE_URL=postgres://postgres:postgres@db:5432/radiotrack_development
SECRET_KEY_BASE=<generate-with-rails-secret>

# Recognition Service
RECOGNITION_PROVIDER=audd
AUDD_API_TOKEN=<audd-api-token>
RECOGNITION_CALLBACK_URL=https://your-domain.com/api/recognition/callback

# OAuth
VK_APP_ID=<vk-app-id>
VK_APP_SECRET=<vk-app-secret>
YANDEX_APP_ID=<yandex-app-id>
YANDEX_APP_SECRET=<yandex-app-secret>

# Telegram
TELEGRAM_BOT_TOKEN=<telegram-bot-token>
```

## Архитектура распознавания

```
Радиостанция (stream) → AudD.io/ACRCloud → Webhook → RadioTrack API → PostgreSQL
                                                              ↓
User (Web/PWA/TMA) ← API ←───────────────────────────────┘
```

Для MVP используется внешний сервис распознавания (AudD.io или ACRCloud), который:
1. Принимает URL потока радиостанции
2. Распознаёт треки в реальном времени
3. Отправляет результаты на webhook (наш `/api/recognition/callback`)
4. Мы сохраняем в базу и показываем пользователю

## Монетизация

- **Месячная подписка:** 150 RUB/месяц
- **Годовая подписка:** 1500 RUB/год (~125 RUB/месяц)

Платежи подключаются через Pay gem + российский эквайринг (Тинькофф/Сбер/ЮKassa)

## Лицензия

MIT
