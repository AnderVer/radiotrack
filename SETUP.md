# RadioTrack MVP - Инструкция по завершению настройки

## Текущий статус

✅ Docker образ собран
✅ PostgreSQL запущен
✅ Модели созданы
✅ Миграции готовы
✅ Контроллеры API созданы
✅ Сервис распознавания готов

## Следующие шаги

### 1. Инициализация базы данных

Выполни команду для создания БД, миграций и заполнения начальными данными:

```bash
docker --context desktop-linux compose exec web bin/rails db:create db:migrate db:seed
```

### 2. Запуск приложения

```bash
docker --context desktop-linux compose up -d
```

Приложение будет доступно по адресу: http://localhost:3000

### 3. Проверка логов

```bash
docker --context desktop-linux compose logs -f web
```

### 4. Настройка распознавания треков

Для работы распознавания треков нужно:

1. Зарегистрироваться на https://audd.io/
2. Получить API токен
3. Добавить токен в `.env`:
   ```
   AUDD_API_TOKEN=your_token_here
   RECOGNITION_PROVIDER=audd
   RECOGNITION_CALLBACK_URL=https://your-domain.com/api/recognition/callback
   ```

4. Для продакшена настроить публичный URL для webhook

### 5. Настройка OAuth провайдеров

#### VK OAuth
1. Создать приложение в VK Developer Console
2. Получить App ID и Secret
3. Добавить в `.env`:
   ```
   VK_APP_ID=your_app_id
   VK_APP_SECRET=your_app_secret
   VK_REDIRECT_URI=http://localhost:3000/users/auth/vk/callback
   ```

#### Yandex OAuth
1. Создать приложение в Yandex Developer Console
2. Получить Client ID и Secret
3. Добавить в `.env`:
   ```
   YANDEX_APP_ID=your_app_id
   YANDEX_APP_SECRET=your_app_secret
   YANDEX_REDIRECT_URI=http://localhost:3000/users/auth/yandex/callback
   ```

#### Telegram Bot
1. Создать бота через @BotFather
2. Получить токен
3. Добавить в `.env`:
   ```
   TELEGRAM_BOT_TOKEN=your_bot_token
   ```

### 6. Тестирование API

#### Получить список станций:
```bash
curl http://localhost:3000/api/stations
```

#### Получить последний трек (требуется авторизация):
```bash
curl http://localhost:3000/api/stations/1/last_track
```

#### Получить статус подписки:
```bash
curl http://localhost:3000/api/user/subscription_status
```

### 7. Консоль Rails

Для отладки и работы с данными:

```bash
docker --context desktop-linux compose exec web bin/rails console
```

Примеры команд в консоли:
```ruby
# Проверить станции
Station.count
Station.first

# Проверить детекции
Detection.count
Detection.last

# Создать тестового пользователя
User.create!(email: "test@example.com", password: "password123")
```

### 8. Мониторинг и логи

```bash
# Логи приложения
docker --context desktop-linux compose logs -f web

# Логи базы данных
docker --context desktop-linux compose logs -f db

# Перезапуск приложения
docker --context desktop-linux compose restart web
```

## Архитектура приложения

```
┌─────────────────────────────────────────────────────────────┐
│                     RadioTrack MVP                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  Web/PWA    │    │  Telegram   │    │   Mobile    │     │
│  │             │    │  Mini App   │    │   (later)   │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│                    ┌───────▼────────┐                       │
│                    │  Rails 8 API   │                       │
│                    │  + Hotwire     │                       │
│                    └───────┬────────┘                       │
│                            │                                │
│         ┌──────────────────┼──────────────────┐             │
│         │                  │                  │             │
│  ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐     │
│  │ PostgreSQL  │    │   Sidekiq   │    │   External  │     │
│  │   (data)    │    │   (jobs)    │    │  Recognition│     │
│  └─────────────┘    └─────────────┘    │  (AudD.io)  │     │
│                                         └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Структура проекта

```
RadioTrack/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   ├── stations_controller.rb
│   │   │   ├── tracks_controller.rb
│   │   │   ├── bookmarks_controller.rb
│   │   │   ├── playlists_controller.rb
│   │   │   ├── playlist_items_controller.rb
│   │   │   ├── subscription_controller.rb
│   │   │   ├── import_controller.rb
│   │   │   └── recognition_controller.rb
│   │   └── ...
│   ├── models/
│   │   ├── user.rb
│   │   ├── station.rb
│   │   ├── detection.rb
│   │   ├── playlist.rb
│   │   ├── playlist_item.rb
│   │   └── ...
│   ├── services/
│   │   └── radio_recognition_service.rb
│   └── jobs/
│       └── playlist_item_resolution_job.rb
├── config/
│   ├── routes.rb
│   ├── database.yml
│   └── ...
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb
├── docker-compose.yml
├── Dockerfile
└── README.md
```

## Функционал MVP

### Готовые компоненты:
- ✅ Модели данных (User, Station, Detection, Playlist, PlaylistItem)
- ✅ API контроллеры (Stations, Tracks, Bookmarks, Playlists)
- ✅ Система лимитов (Guest/Auth/Paid)
- ✅ Интеграция с внешним распознаванием (AudD/ACRCloud)
- ✅ Pending items для "Добавить текущий трек"
- ✅ Telegram Mini App поддержка

### Требует реализации:
- ⏳ Frontend UI (Hotwire/Turbo)
- ⏳ PWA манифест
- ⏳ Платежная интеграция
- ⏳ Тесты

## Контакты и поддержка

При возникновении проблем:
1. Проверь логи: `docker compose logs -f`
2. Проверь переменные окружения в `.env`
3. Убедись, что БД доступна: `docker compose exec db psql -U postgres`
