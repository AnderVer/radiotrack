# 📻 RadioTrack — Сервис отслеживания треков в радиоэфире

[![Ruby](https://img.shields.io/badge/Ruby-3.3.0-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.0-blue.svg)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Сервис для участников радиоконкурсов — отслеживайте последний трек в эфире радиостанции в реальном времени.

## 🎯 О проекте

**Целевая аудитория:** Слушатели радиостанций, участвующие в эфирных конкурсах (угадать трек перед конкурсом).

**Платформы:** Web + PWA + Telegram Mini App (единый код)

## ✨ Возможности

### Для пользователей

| Функция | Guest | Auth | Paid |
|---------|-------|------|------|
| Закладки станций | 3 | ∞ | ∞ |
| Плейлисты | 3 × 10 треков | 10 × 50 | 50 × 100 |
| Trial "Где играет" | 3 попытки | Расширено | Безлимит |
| Последний трек | ❌ | ❌ | ✅ |
| Плейлист эфира | ❌ | ❌ | ✅ |
| Прогноз "Будет скоро" | ❌ | ❌ | ✅ |
| Добавить текущий трек | ❌ | ❌ | ✅ |

### Технологические преимущества

- **Real-time отслеживание** — обновление каждые 5-10 секунд
- **Внешнее распознавание** — AudD.io / ACRCloud для точности
- **Hotwire/Turbo** — SPA-ощущение без сложного JavaScript
- **Docker** — простая установка и развертывание

## 🚀 Быстрый старт

### Требования

- Docker Desktop
- Git
- GitHub CLI (опционально, для работы с задачами)

### Установка

```bash
# Клонирование репозитория
git clone https://github.com/AnderVer/radiotrack.git
cd radiotrack

# Копирование .env
cp .env.example .env

# Запуск Docker
docker compose up -d

# Инициализация БД
docker compose exec web bin/rails db:create db:migrate db:seed

# Открыть http://localhost:3000
```

### Запуск Solid Queue (фоновые задачи)

```bash
# В отдельном терминале
docker compose exec web bin/rails solid_queue:start
```

**Примечание:** Solid Queue работает без Redis — используется PostgreSQL.

### Проверка работы

```bash
# Консоль Rails
docker compose exec web bin/rails console

# Проверка станций
Station.count  # должно быть 10

# Проверка Detection
Detection.first

# Запуск тестов (если есть)
docker compose exec web bin/rails test
```

### Логи

```bash
# Логи веб-сервера
docker compose logs -f web

# Логи базы данных
docker compose logs -f db

# Логи Solid Queue (если запущен)
docker compose exec web tail -f log/development.log
```

## 📡 Радиостанции (MVP)

10 станций для MVP:

- 🇷🇺 Авторадио
- 🇷🇺 Европа Плюс
- 🇷🇺 DFM
- 🇷🇺 Love Radio
- 🇷🇺 Русское Радио
- 🇷🇺 Energy
- 🇷🇺 Хит FM
- 🇷🇺 НАШЕ Радио
- 🇷🇺 Радио Рекорд
- 🇷🇺 Юмор FM

## 🏗 Архитектура

```
┌─────────────────────────────────────────────────────────┐
│                  RadioTrack MVP                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Web/PWA  ←→  Telegram Mini App  ←→  Mobile (later)    │
│       ↓              ↓                    ↓             │
│       └──────────────┼────────────────────┘             │
│                      │                                  │
│              ┌───────▼────────┐                         │
│              │  Rails 8 API   │                         │
│              │  + Hotwire     │                         │
│              └───────┬────────┘                         │
│                      │                                  │
│       ┌──────────────┼──────────────┐                   │
│       ↓              ↓              ↓                   │
│  PostgreSQL    Solid Queue    Open Playlists           │
│   (data)       (background)   (Avtoradio, etc.)        │
└─────────────────────────────────────────────────────────┘
```

**Ключевое решение:** Основной источник данных "что играло" — **открытые плейлисты радиостанций** (парсинг HTML). AudD/ACRCloud — опциональный fallback.

## 📚 API Endpoints

### Recognition
- `POST /api/recognition/callback` — webhook от AudD/ACRCloud

### Stations
- `GET /api/stations` — список станций
- `GET /api/stations/:id/last_track` — последний трек (Paid)
- `GET /api/stations/:id/playlist?range=30m` — плейлист эфира (Paid)
- `POST /api/stations/:id/capture_now_playing` — захват трека (Paid)

### Tracks
- `GET /api/tracks/:id/where_now` — где играет (trial limited)
- `GET /api/tracks/:id/where_soon?window=30m` — прогноз (Paid)

### User
- `GET/POST /api/user/bookmarks` — закладки
- `GET /api/user/subscription_status` — статус подписки
- `CRUD /api/playlists` — плейлисты

## 💰 Монетизация

| План | Цена | Возможности |
|------|------|-------------|
| **Guest** | Бесплатно | Базовые лимиты |
| **Auth** | Бесплатно | Расширенные лимиты |
| **Paid** | 150₽/мес или 1500₽/год | Полный доступ |

## 🛠 Разработка

```bash
# Запуск в режиме разработки
docker compose up -d
docker compose exec web bin/rails server -b 0.0.0.0

# Миграции
docker compose exec web bin/rails db:migrate

# Консоль Rails
docker compose exec web bin/rails console

# Тесты
docker compose exec web bin/rails test

# Логи
docker compose logs -f web
```

## 📦 Переменные окружения

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

## 📄 Лицензия

[MIT](LICENSE)

## 👥 Команда

- Solo Founder / Developer

## 📞 Контакты

- Website: [TBD]
- Telegram: [TBD]
- Email: [TBD]

---

<div align="center">

**RadioTrack** — Узнай трек и выиграй приз! 🏆

[![Stars](https://img.shields.io/github/stars/YOUR_USERNAME/radiotrack?style=social)](https://github.com/YOUR_USERNAME/radiotrack/stargazers)
[![Forks](https://img.shields.io/github/forks/YOUR_USERNAME/radiotrack?style=social)](https://github.com/YOUR_USERNAME/radiotrack/network/members)

</div>
