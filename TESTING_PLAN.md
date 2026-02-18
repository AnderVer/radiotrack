# 🧪 RadioTrack — План тестирования локально

**Дата:** 18 февраля 2026  
**Статус:** M0-M7 реализованы, готово к тестированию

---

## 📋 Реализованные этапы

| Этап | Компоненты | Статус |
|------|------------|--------|
| **M0 Bootstrap** | ENV, Docker, Seeds, Tests | ✅ 100% |
| **M1 Avtoradio ingest** | Parser, Job, Timezone, Idempotency | ✅ 100% |
| **M2 Dedup** | Rake tasks, Migrations, Unique index | ✅ 100% |
| **M3 Solid Queue** | Configs, Recurring schedule | ✅ 100% |
| **M4 UI (Hotwire)** | Layout, Home, Station page, Paywall | ✅ 100% |
| **M5 OAuth** | VK/Yandex login, Subscription UI | ✅ 100% |
| **M7 PWA** | Manifest, Icons | ✅ 100% |

---

## 🚀 Запуск приложения

### 1. Запуск Docker

```bash
cd c:\Акселерация Обучение\AutoRadio\RadioTrack
docker compose up -d
```

**Проверка:**
```bash
docker compose ps
# Должны быть: radiotrack-db-1, radiotrack-web-1
```

### 2. Миграция БД

```bash
docker compose exec web bin/rails db:migrate
```

### 3. Посев данных (seeds)

```bash
docker compose exec web bin/rails db:seed
```

**Проверка:**
```bash
docker compose exec web bin/rails console
> Station.count  # => 10
> Detection.count  # => 100+ (sample detections)
```

### 4. Запуск Solid Queue (фоновые задачи)

```bash
docker compose exec web bin/rails solid_queue:start
```

**Примечание:** AvtoradioIngestJob будет запускаться автоматически каждые 2 минуты.

### 5. Открыть приложение

```
http://localhost:3000
```

---

## ✅ Чек-лист тестирования

### Базовый UI (M4)

- [ ] **Главная страница** (`/`)
  - [ ] Отображаются 10 станций
  - [ ] У станций видны последние треки
  - [ ] Кнопки "Открыть" и "Подробнее" работают
  - [ ] Paywall блок виден для неавторизованных

- [ ] **Страница станции** (`/stations/1`)
  - [ ] Отображается информация о станции
  - [ ] Видны последние 20 треков
  - [ ] Paywall для "Последний трек" (неавторизованным)
  - [ ] Paywall для "Плейлист эфира"
  - [ ] Кнопки "Открыть сайт" и "Слушать" работают

### Авторизация (M5)

- [ ] **Страница входа** (`/users/sign_in`)
  - [ ] Форма email/password работает
  - [ ] Кнопка "Войти через VK" видна
  - [ ] Кнопка "Войти через Yandex" видна

- [ ] **Страница регистрации** (`/users/sign_up`)
  - [ ] Форма регистрации работает
  - [ ] Кнопки OAuth видны

- [ ] **Профиль пользователя** (`/user/profile`)
  - [ ] Отображается email и план
  - [ ] Кнопка "Активировать демо-подписку" работает
  - [ ] После активации виден статус Premium
  - [ ] Кнопка "Отменить подписку" работает

### Avtoradio Ingest (M1)

- [ ] **Ручной запуск job**
  ```bash
  docker compose exec web bin/rails console
  > AvtoradioIngestJob.perform_now
  ```

- [ ] **Проверка результатов**
  ```bash
  docker compose exec web bin/rails console
  > Detection.where(source: "avtoradio_playlist").count
  > Detection.where(source: "avtoradio_playlist").last
  ```

- [ ] **Solid Queue recurring**
  - [ ] Job запускается автоматически каждые 2 минуты
  - [ ] Логи Solid Queue показывают выполнение

### Dedup (M2)

- [ ] **Rake task: найти дубли**
  ```bash
  docker compose exec web bin/rails db:detections:find_duplicates
  ```

- [ ] **Rake task: удалить дубли**
  ```bash
  docker compose exec web bin/rails db:detections:cleanup_duplicates
  ```

- [ ] **Rake task: добавить unique index**
  ```bash
  docker compose exec web bin/rails db:detections:add_unique_index
  ```

### PWA (M7)

- [ ] **Manifest**
  - [ ] `http://localhost:3000/manifest.webmanifest` отдаёт JSON
  - [ ] В манифесте указаны иконки

- [ ] **Иконки**
  - [ ] `http://localhost:3000/icons/icon-192x192.svg` открывается
  - [ ] `http://localhost:3000/icons/icon-512x512.svg` открывается

- [ ] **Mobile**
  - [ ] В DevTools (F12) → Lighthouse → PWA audit проходит

---

## 🔧 Отладка

### Логи

```bash
# Веб-сервер
docker compose logs -f web

# База данных
docker compose logs -f db

# Solid Queue
docker compose exec web tail -f log/development.log
```

### Консоль Rails

```bash
docker compose exec web bin/rails console

# Проверка станций
Station.count
Station.first

# Проверка Detection
Detection.count
Detection.last

# Ручной запуск ingest
AvtoradioIngestJob.perform_now

# Проверка Solid Queue
SolidQueue::Job.count
SolidQueue::Process.all
```

### Миграции

```bash
# Статус миграций
docker compose exec web bin/rails db:migrate:status

# Откат последней миграции
docker compose exec web bin/rails db:rollback

# Применить все миграции
docker compose exec web bin/rails db:migrate
```

---

## 🐛 Известные проблемы

### 1. OAuth VK/Yandex не работает без реальных ключей

**Решение:** Для локального тестирования используйте email/password регистрацию.

Для OAuth получите ключи:
- VK: https://vk.com/editapp?act=create
- Yandex: https://oauth.yandex.ru/client/new

Добавьте в `.env`:
```bash
VK_APP_ID=your_vk_app_id
VK_APP_SECRET=your_vk_app_secret
YANDEX_CLIENT_ID=your_yandex_client_id
YANDEX_CLIENT_SECRET=your_yandex_client_secret
```

### 2. Docker build занимает много времени

**Причина:** Сборка Ruby image с зависимостями.

**Решение:** Дождитесь завершения (5-10 минут первый раз).

### 3. Solid Queue не запускается

**Проверка:**
```bash
docker compose exec web bin/rails solid_queue:inspect
```

**Перезапуск:**
```bash
docker compose restart web
```

---

## 📊 Ожидаемые результаты

### После `db:seed`

- **10 станций** в БД
- **100+ detections** (sample данные)
- Главная страница отображает все станции

### После `AvtoradioIngestJob.perform_now`

- **+4-10 detections** из Авторадио плейлиста
- `source = "avtoradio_playlist"`
- `played_at` в UTC (конвертация из МСК)

### После активации демо-подписки

- `current_user.plan_code = "paid"`
- `current_user.paid_until = 30.days.from_now`
- Разблокированы все premium функции

---

## 🎯 Критерии приёмки

**M0-M7 считаются завершёнными, если:**

1. ✅ Приложение запускается через `docker compose up -d`
2. ✅ Главная страница отображает 10 станций
3. ✅ Страница станции показывает последние треки
4. ✅ Регистрация/вход работают (email/password)
5. ✅ Демо-подписка активируется на 30 дней
6. ✅ Paywall виден для premium функций
7. ✅ AvtoradioIngestJob создаёт detections
8. ✅ PWA manifest доступен

---

**Готово к тестированию!** 🚀
