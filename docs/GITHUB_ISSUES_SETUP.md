# 🚀 GitHub Issues — Инструкция по созданию

## Быстрый старт

### Вариант 1: Автоматическое создание (через gh CLI)

1. **Аутентифицируйтесь в GitHub CLI:**
   ```bash
   gh auth login
   ```
   
   Следуйте инструкциям в терминале:
   - Выберите "GitHub.com"
   - Выберите "HTTPS"
   - Выберите "Login with a browser"
   - Скопируйте код и откройте ссылку в браузере
   - Вставьте код и подтвердите авторизацию

2. **Запустите скрипт создания issues:**
   ```bash
   bash scripts/github_bootstrap_create_issues.sh
   ```

3. **Проверьте результат:**
   ```bash
   gh issue list
   ```

---

### Вариант 2: Ручное создание (через веб-интерфейс)

Если gh CLI не работает, создайте issues вручную через GitHub UI:

#### 1. Создайте Milestones

Перейдите в **Issues → Milestones → New milestone**

Создайте следующие milestones:
- `M0 Bootstrap` — Docker/ENV/DB smoke; базовая воспроизводимость локального запуска.
- `M1 Avtoradio ingest` — Парсер Авторадио + ingest job + идемпотентность.
- `M2 Dedup` — Cleanup дублей + unique index на detections.
- `M3 Solid Queue schedule` — Конфиги Solid Queue + периодический запуск ingest.
- `M4 UI (Hotwire)` — MVP UI на Hotwire/Turbo вокруг станций и detections.
- `M5 OAuth` — VK/Yandex OmniAuth + Identity linking + статус подписки.
- `M6 Recognition fallback` — AudD как опциональный fallback.
- `M7 PWA` — Manifest и минимальная PWA-обвязка.
- `M8 Tests` — Критические тесты: парсер, timezone, дедуп, лимиты.
- `M9 Stations inventory` — Инвентаризация источников плейлистов + базовая архитектура парсеров.

---

#### 2. Создайте Labels

Перейдите в **Issues → Labels → New label**

Создайте следующие labels:

**Type:**
| Name | Color | Description |
|------|-------|-------------|
| `type:feature` | `#1F6FEB` | Feature work |
| `type:chore` | `#6E7781` | Maintenance / chores |
| `type:bug` | `#D1242F` | Bug |
| `type:test` | `#8250DF` | Tests |
| `type:docs` | `#0E8A16` | Documentation |

**Area:**
| Name | Color | Description |
|------|-------|-------------|
| `area:infra` | `#0B3D91` | Docker, env, bootstrapping |
| `area:db` | `#5319E7` | Migrations, indexes, schema |
| `area:parser` | `#0052CC` | Playlist parsers |
| `area:jobs` | `#C2E0C6` | Background jobs, Solid Queue |
| `area:api` | `#FBCA04` | API controllers/endpoints |
| `area:ui` | `#BFDADC` | Hotwire/Turbo UI |
| `area:auth` | `#F9D0C4` | Devise/OmniAuth |
| `area:pwa` | `#D4C5F9` | PWA/manifest |

**Priority:**
| Name | Color | Description |
|------|-------|-------------|
| `priority:P0` | `#B60205` | Blocker / MVP critical |
| `priority:P1` | `#D93F0B` | High |
| `priority:P2` | `#0E8A16` | Normal |

**Station:**
| Name | Color | Description |
|------|-------|-------------|
| `station:avtoradio` | `#1D76DB` | Avtoradio station work |
| `station:europaplus` | `#E74C3C` | Europa Plus station work |

---

#### 3. Создайте Issues

Перейдите в **Issues → New issue**

Создайте следующие issues (копируйте название и описание):

---

### M0 — Bootstrap (4 issues)

**1. Docs: быстрый старт (Docker/DB/Queue)**
- Milestone: `M0 Bootstrap`
- Labels: `type:docs`, `area:infra`, `priority:P0`
- Описание:
```
Цель: зафиксировать единую воспроизводимую инструкцию локального запуска через Docker.

Acceptance criteria:
- В README есть команды:
  - docker compose up -d
  - docker compose exec web bin/rails db:migrate
  - docker compose exec web bin/rails console
  - docker compose exec web bin/rails solid_queue:start
- Отдельно указано, что Redis не нужен (Solid Queue без Redis).

Checklist:
- [ ] Обновить/добавить раздел "Local development (Docker)".
- [ ] Добавить раздел "Running Solid Queue".
- [ ] Проверить инструкцию на чистом окружении.
```

**2. Infra: добавить/обновить .env.example (полный список ENV)**
- Milestone: `M0 Bootstrap`
- Labels: `type:chore`, `area:infra`, `priority:P0`
- Описание:
```
Цель: добавить .env.example со всеми переменными окружения, ожидаемыми приложением.

Acceptance criteria:
- .env.example содержит:
  DATABASE_URL, SECRET_KEY_BASE, HOST,
  RECOGNITION_PROVIDER, AUDD_API_TOKEN, RECOGNITION_CALLBACK_URL,
  VK_APP_ID, VK_APP_SECRET, YANDEX_APP_ID, YANDEX_APP_SECRET,
  CRON_SECRET
- В файле только примерные значения (без реальных секретов).

Checklist:
- [ ] Создать/обновить .env.example.
- [ ] Обновить README: как применить env локально.
```

**3. DB: seeds — 10 станций для MVP (Avtoradio + 9)**
- Milestone: `M0 Bootstrap`
- Labels: `type:feature`, `area:db`, `priority:P0`
- Описание:
```
Цель: сделать db/seeds.rb, который создаёт 10 станций для MVP.

Acceptance criteria:
- bin/rails db:seed создаёт 10 станций.
- Seed идемпотентен (повторный запуск не множит записи).
- У станций заполнены минимальные поля для UI и ingest.

Checklist:
- [ ] Добавить список станций в seeds.
- [ ] Проверить на чистой БД в Docker.
```

**4. Smoke: Detection работает (создать Station + Detection + прочитать назад)**
- Milestone: `M0 Bootstrap`
- Labels: `type:test`, `area:db`, `priority:P0`
- Описание:
```
Цель: минимальная проверка, что модель Detection и схема валидны.

Acceptance criteria:
- Есть spec (или minitest), который:
  - создаёт Station
  - создаёт Detection с artist/title/played_at/source
  - проверяет, что artist_title_normalized заполнился
- Тест проходит локально в Docker.

Checklist:
- [ ] Добавить spec модели Detection.
- [ ] Зафиксировать команду запуска тестов в README.
```

---

### M1 — Avtoradio ingest (6 issues)

**5. Parser(Avtoradio): AvtoradioPlaylistParser (CSS selectors)**
- Milestone: `M1 Avtoradio ingest`
- Labels: `type:feature`, `area:parser`, `priority:P0`, `station:avtoradio`
- Описание:
```
Цель: сервис, который парсит HTML плейлиста Авторадио по селекторам.

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
- [ ] Реализовать извлечение времени/артиста/названия.
```

**6. Parser(Avtoradio): дата из заголовка + ru months map**
- Milestone: `M1 Avtoradio ingest`
- Labels: `type:feature`, `area:parser`, `priority:P0`, `station:avtoradio`
- Описание:
```
Цель: парсить дату из заголовка страницы Авторадио (ru-месяцы).

Acceptance criteria:
- Реализован MONTHS map ("февраля" => 2 и т.д.).
- Regex/логика извлекает день/месяц/год из заголовка.
- При ошибке парсинга ingest не пишет мусор (явный лог/исключение).

Checklist:
- [ ] Добавить MONTHS map.
- [ ] Добавить метод extract_date_from_header(text).
```

**7. Timezone(Avtoradio): МСК → UTC для played_at**
- Milestone: `M1 Avtoradio ingest`
- Labels: `type:feature`, `area:parser`, `priority:P0`, `station:avtoradio`
- Описание:
```
Цель: played_at хранится в UTC, входные данные Авторадио — МСК, нужна конвертация.

Acceptance criteria:
- Есть метод, который из (date, time_str) строит UTC-time.
- Есть unit-тест: МСК 11:38 -> UTC 08:38.

Checklist:
- [ ] Использовать ActiveSupport::TimeZone["Europe/Moscow"].
- [ ] Добавить unit-тест конвертации.
```

**8. Job: AvtoradioIngestJob (fetch + parse + persist detections)**
- Milestone: `M1 Avtoradio ingest`
- Labels: `type:feature`, `area:jobs`, `area:parser`, `priority:P0`, `station:avtoradio`
- Описание:
```
Цель: job скачивает https://www.avtoradio.ru/playlist, парсит и пишет detections.

Acceptance criteria:
- AvtoradioIngestJob.perform_now создаёт Detection записи для станции Авторадио.
- У записей проставлен source = "playlist" (и confidence при необходимости).
- Ошибки сети/пустой HTML обработаны (лог + безопасное завершение).

Checklist:
- [ ] Fetch HTML.
- [ ] Parse HTML.
- [ ] Persist Detection.
```

**9. Ingest: идемпотентность (app-level dedup по station_id/played_at/artist_title_normalized)**
- Milestone: `M1 Avtoradio ingest`
- Labels: `type:feature`, `area:db`, `area:parser`, `priority:P0`, `station:avtoradio`
- Описание:
```
Цель: повторный запуск ingest не должен множить detections (до unique index и после него).

Acceptance criteria:
- Перед create! выполняется find_by(station_id, played_at, artist_title_normalized) и пропуск, если найдено.
- 2 запуска AvtoradioIngestJob подряд (на одинаковом HTML) -> одинаковое число записей.
- Есть тест/скрипт проверки.

Checklist:
- [ ] Реализовать прикладной дедуп.
- [ ] Добавить интеграционный тест или воспроизводимый сценарий.
```

**10. API internal (опционально): POST /api/internal/ingest/avtoradio под CRON_SECRET**
- Milestone: `M1 Avtoradio ingest`
- Labels: `type:feature`, `area:api`, `priority:P2`, `station:avtoradio`
- Описание:
```
Цель: internal endpoint для ручного/внешнего триггера ingest (если нужен).

Acceptance criteria:
- Endpoint защищён CRON_SECRET.
- Endpoint запускает ingest и возвращает ok/ошибка.

Checklist:
- [ ] Controller + route.
- [ ] Проверка секрета.
```

---

### M2 — Dedup (3 issues)

**11. DB: rake task найти дубли detections по (station_id, played_at, artist_title_normalized)**
- Milestone: `M2 Dedup`
- Labels: `type:chore`, `area:db`, `priority:P0`
- Описание:
```
Цель: быстро находить дубли перед добавлением unique index.

Acceptance criteria:
- Есть rake task (или runner script), который выводит количество групп дублей и примеры.
- Запрос основан на group/having COUNT(*) > 1.

Checklist:
- [ ] Реализовать запрос.
- [ ] Документировать запуск.
```

**12. DB migration: cleanup дублей detections (до unique index)**
- Milestone: `M2 Dedup`
- Labels: `type:feature`, `area:db`, `priority:P0`
- Описание:
```
Цель: удалить существующие дубли перед unique index.

Acceptance criteria:
- Миграция удаляет дубли детерминированно (например, оставляет минимальный id).
- Миграция не падает по памяти (батчи или SQL).
- Логирует, сколько удалено.

Checklist:
- [ ] Написать миграцию cleanup.
- [ ] Прогнать на dev данных.
```

**13. DB migration: unique index на detections (station_id, played_at, artist_title_normalized)**
- Milestone: `M2 Dedup`
- Labels: `type:feature`, `area:db`, `priority:P0`
- Описание:
```
Цель: добавить уникальность на уровне БД.

Acceptance criteria:
- Добавлен индекс:
  index_detections_unique_station_played_artist_title
  UNIQUE (station_id, played_at, artist_title_normalized)
- Попытка вставить дубль вызывает ошибку уникальности.
- Есть тест на DB constraint.

Checklist:
- [ ] Миграция add_index unique.
- [ ] Тест на ошибку уникальности.
```

---

### M3 — Solid Queue schedule (4 issues)

**14. Solid Queue: добавить config/solid_queue.yml**
- Milestone: `M3 Solid Queue schedule`
- Labels: `type:feature`, `area:jobs`, `priority:P1`
- Описание:
```
Цель: зафиксировать конфиг Solid Queue в репозитории.

Acceptance criteria:
- В проекте есть config/solid_queue.yml.
- В README описан запуск воркера: bin/rails solid_queue:start

Checklist:
- [ ] Добавить файл конфига.
- [ ] Проверить запуск в Docker.
```

**15. Solid Queue: добавить/обновить config/queue.yml**
- Milestone: `M3 Solid Queue schedule`
- Labels: `type:feature`, `area:jobs`, `priority:P1`
- Описание:
```
Цель: зафиксировать очереди/приоритеты.

Acceptance criteria:
- В проекте есть config/queue.yml.
- Job'ы используют ожидаемые очереди (если применимо).

Checklist:
- [ ] Добавить/обновить config/queue.yml.
- [ ] Документация.
```

**16. Solid Queue recurring: AvtoradioIngestJob каждые 1–2 минуты**
- Milestone: `M3 Solid Queue schedule`
- Labels: `type:feature`, `area:jobs`, `priority:P1`, `station:avtoradio`
- Описание:
```
Цель: включить периодический запуск ingest Авторадио каждые 1–2 минуты.

Acceptance criteria:
- При запущенном воркере job выполняется регулярно.
- Дубли не появляются (app dedup + unique index).

Checklist:
- [ ] Настроить recurring.
- [ ] Добавить минимальные логи/метрики (сколько записали/пропустили).
```

**17. Jobs: ResolvePendingJob — решить нужен ли в MVP (и реализовать/отложить)**
- Milestone: `M3 Solid Queue schedule`
- Labels: `type:chore`, `area:jobs`, `priority:P2`
- Описание:
```
Цель: подтвердить необходимость ResolvePendingJob.

Acceptance criteria:
- Принято решение: делаем сейчас или откладываем.
- Если делаем: есть job + расписание (каждую минуту).

Checklist:
- [ ] Аудит модели PlaylistItem и статусов.
- [ ] Реализовать или закрыть как not planned.
```

---

### M4 — UI (Hotwire) (3 issues)

**18. UI: главная страница (список станций)**
- Milestone: `M4 UI (Hotwire)`
- Labels: `type:feature`, `area:ui`, `priority:P1`
- Описание:
```
Цель: публичная главная страница со списком станций.

Acceptance criteria:
- Отображаются станции из БД.
- Переход на страницу станции работает.

Checklist:
- [ ] Controller + view.
- [ ] Turbo-friendly навигация.
```

**19. UI: страница станции (последние detections, время в МСК)**
- Milestone: `M4 UI (Hotwire)`
- Labels: `type:feature`, `area:ui`, `priority:P1`
- Описание:
```
Цель: страница станции показывает последние N detections.

Acceptance criteria:
- Список detections отсортирован по played_at desc.
- Время отображается в МСК (конвертация UTC->MSK на выводе).
- Пустое состояние обработано.

Checklist:
- [ ] Query + view.
- [ ] Конвертация timezone на выводе.
```

**20. UI: paywall CTA для Paid функций (playlist/last_track/capture)**
- Milestone: `M4 UI (Hotwire)`
- Labels: `type:feature`, `area:ui`, `priority:P2`
- Описание:
```
Цель: UI-обвязка вокруг платных endpoints.

Acceptance criteria:
- Non-paid видит CTA вместо данных.
- Paid видит данные.

Checklist:
- [ ] Компонент paywall.
- [ ] Проверка статуса пользователя.
```

---

### M5 — OAuth (3 issues)

**21. OAuth: VK вход + Identity linking**
- Milestone: `M5 OAuth`
- Labels: `type:feature`, `area:auth`, `priority:P1`
- Описание:
```
Цель: настроить OmniAuth VK и связку Identity -> User.

Acceptance criteria:
- Логин VK работает в dev.
- Identity создаётся/находится корректно.
- User создаётся/привязывается корректно.

Checklist:
- [ ] Provider config.
- [ ] Callback flow.
- [ ] Проверить ENV VK_APP_ID/VK_APP_SECRET.
```

**22. OAuth: Yandex вход + Identity linking**
- Milestone: `M5 OAuth`
- Labels: `type:feature`, `area:auth`, `priority:P1`
- Описание:
```
Цель: настроить OmniAuth Yandex и связку Identity -> User.

Acceptance criteria:
- Логин Yandex работает в dev.
- Identity создаётся/находится корректно.
- User создаётся/привязывается корректно.

Checklist:
- [ ] Provider config.
- [ ] Callback flow.
- [ ] Проверить ENV YANDEX_APP_ID/YANDEX_APP_SECRET.
```

**23. API+UI: /api/user/subscription_status + отображение статуса**
- Milestone: `M5 OAuth`
- Labels: `type:feature`, `area:api`, `area:ui`, `priority:P2`
- Описание:
```
Цель: показать пользователю текущий план и статус подписки.

Acceptance criteria:
- Endpoint возвращает план (guest/auth/paid) и полезные поля (например остаток trial).
- В UI профиля отображается статус.

Checklist:
- [ ] Контракт ответа.
- [ ] Простая страница профиля.
```

---

### M6 — Recognition fallback (1 issue)

**24. Recognition: ENV wiring + базовый клиент AudD (fallback, не включать в MVP поток)**
- Milestone: `M6 Recognition fallback`
- Labels: `type:feature`, `area:api`, `priority:P2`
- Описание:
```
Цель: подготовить AudD как опциональный fallback.

Acceptance criteria:
- Если recognition не включён, отсутствие токена не ломает приложение.
- Базовый клиент с таймаутами/ошибками готов.

Checklist:
- [ ] Клиент.
- [ ] Документация ENV.
- [ ] Переключатель RECOGNITION_PROVIDER.
```

---

### M7 — PWA (1 issue)

**25. PWA: manifest.webmanifest + иконки (192/512)**
- Milestone: `M7 PWA`
- Labels: `type:feature`, `area:pwa`, `priority:P2`
- Описание:
```
Цель: минимальная PWA-обвязка (манифест + иконки).

Acceptance criteria:
- Манифест отдается корректно.
- Иконки доступны.
- start_url корректный.

Checklist:
- [ ] Добавить manifest.
- [ ] Добавить иконки.
- [ ] Подключить в layout.
```

---

### M8 — Tests (4 issues)

**26. Test: AvtoradioPlaylistParser (HTML fixture → tracks)**
- Milestone: `M8 Tests`
- Labels: `type:test`, `area:parser`, `priority:P1`, `station:avtoradio`
- Описание:
```
Цель: тест парсера без сети на HTML-фикстуре.

Acceptance criteria:
- Фикстура HTML лежит в spec/fixtures.
- Тест проверяет минимум 2 трека (время/артист/название).

Checklist:
- [ ] Добавить fixture.
- [ ] Написать spec.
```

**27. Test: МСК→UTC конвертация played_at**
- Milestone: `M8 Tests`
- Labels: `type:test`, `area:parser`, `priority:P1`
- Описание:
```
Цель: зафиксировать timezone-конвертацию тестом.

Acceptance criteria:
- Тест проверяет смещение МСК->UTC (-3 часа).

Checklist:
- [ ] Unit test конвертации.
```

**28. Test: Unique index защита (DB-level) для detections**
- Milestone: `M8 Tests`
- Labels: `type:test`, `area:db`, `priority:P1`
- Описание:
```
Цель: тест на уникальность после добавления unique index.

Acceptance criteria:
- Попытка создать дубль падает на DB уровне (ошибка уникальности).

Checklist:
- [ ] Spec/тест на уникальность.
```

**29. Test: Trial tune_in списание на GET /api/tracks/:id/where_now**
- Milestone: `M8 Tests`
- Labels: `type:test`, `area:api`, `priority:P1`
- Описание:
```
Цель: зафиксировать логику trial-limits на where_now.

Acceptance criteria:
- Запрос создаёт TuneInAttempt и уменьшает остаток.
- При превышении лимита guest/auth получает отказ.
- Paid проходит без ограничений.

Checklist:
- [ ] Тест guest/auth/paid.
- [ ] Проверка попыток за день.
```

---

### M9 — Stations inventory (2 issues)

**30. Inventory: 9 станций — источники плейлистов (URL/тип/антибот) + оценка сложности**
- Milestone: `M9 Stations inventory`
- Labels: `type:docs`, `area:parser`, `priority:P2`
- Описание:
```
Цель: собрать таблицу источников по 9 станциям.

Acceptance criteria:
- docs/stations_inventory.md с таблицей по всем 9 станциям:
  URL, формат (HTML/JSON/API), нужен ли JS, антибот, частота обновления, сложность (easy/medium/hard).
- Отметка: берём в MVP или откладываем.

Checklist:
- [ ] Заполнить таблицу.
- [ ] Принять решение по каждой станции.
```

**31. Parser architecture: базовый интерфейс парсеров + 2-я простая станция**
- Milestone: `M9 Stations inventory`
- Labels: `type:feature`, `area:parser`, `priority:P2`
- Описание:
```
Цель: масштабируемая архитектура парсеров после Авторадио.

Acceptance criteria:
- Есть базовый контракт (fetch/parse/to_detections).
- Реализован второй парсер для "easy" станции из инвентаризации.
- Есть тест парсера.

Checklist:
- [ ] Добавить базовый интерфейс.
- [ ] Выбрать станцию №2.
- [ ] Реализовать парсер и тест.
```

---

## ✅ Проверка результата

После создания всех issues:

1. **Проверьте список issues:**
   ```bash
   gh issue list
   ```

2. **Проверьте распределение по milestone:**
   ```bash
   gh issue list --milestone "M0 Bootstrap"
   gh issue list --milestone "M1 Avtoradio ingest"
   # и т.д.
   ```

3. **Убедитесь, что все 31 issue созданы**

---

## 📝 Примечания

- M0–M8 уже реализованы — эти issues нужны для отслеживания истории разработки
- M9 — активная задача для текущей разработки
- При закрытии issues указывайте в PR: `Closes #<номер>`
