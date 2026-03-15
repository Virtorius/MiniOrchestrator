# Тестирование n8n Mini Orchestrator + Worker

## 📋 Обзор

В этой папке находятся скрипты для автоматического тестирования workflow.

### Тестовые кейсы

| № | Кейс | Описание | Ожидаемый результат |
|---|------|----------|---------------------|
| 1 | **Success** | Все параметры присутствуют | `status: success`, 3 варианта |
| 2 | **Missing Data** | Нет параметров в сообщении | `status: missing_data`, список полей |
| 3 | **Error** | Ошибка БД (эмуляция) | `status: error`, сообщение об ошибке |

---

## 🚀 Быстрый старт

### Требования

1. **n8n запущен** и доступен (по умолчанию `http://localhost:5678`)
2. **PostgreSQL подключен** и таблица `session_state` существует
3. **Workflow импортированы** и активированы
4. **Bash** (Git Bash на Windows) или Linux/Mac terminal
5. **curl** установлен
6. **Python 3** для валидации JSON

### Предварительная проверка

```bash
# Проверка доступности n8n
curl http://localhost:5678

# Проверка workflow (должен вернуть 404 для несуществующего webhook)
curl http://localhost:5678/webhook/search-request
```

---

## 📁 Файлы тестов

```
tests/
├── 01_test_success.sh       # Тест успешного поиска
├── 02_test_missing_data.sh  # Тест недостающих данных
├── 03_test_error.sh         # Тест ошибки (требует эмуляции)
├── run_all_tests.sh         # Запуск всех тестов
└── README_tests.md          # Эта документация
```

---

## 🧪 Запуск тестов

### Вариант 1: Запуск всех тестов

```bash
# Перейдите в папку tests
cd tests

# Запустите все тесты
./run_all_tests.sh
```

**На Windows (Git Bash):**
```bash
cd tests
bash run_all_tests.sh
```

### Вариант 2: Запуск отдельного теста

```bash
# Тест #1: Success
./01_test_success.sh

# Тест #2: Missing Data
./02_test_missing_data.sh

# Тест #3: Error (требует эмуляции ошибки БД)
./03_test_error.sh
```

### Вариант 3: С переменными окружения

```bash
# Если n8n на другом порту или хосте
N8N_URL=http://192.168.1.100:5678 ./01_test_success.sh

# Или экспортируйте переменную
export N8N_URL=http://localhost:5678
./run_all_tests.sh
```

---

## 📊 Расшифровка результатов

### Успешный тест
```
✅ PASS: Все проверки пройдены
  - HTTP статус: 200
  - status: success
  - Найдено вариантов: 3
  - session_id: sess_1234567890_abc123
```

### Неуспешный тест
```
❌ FAIL: status != 'success' (получено: 'error')
```

### Пропущенный тест
```
Тест пропущен
```

---

## 🔧 Детали тестовых кейсов

### Тест #1: Success

**Входные данные:**
```json
{
  "user_id": "10001",
  "message": "Найди варианты на завтра в 19:00 на двоих в центре"
}
```

**Проверки:**
- ✅ HTTP статус = 200
- ✅ `status` = "success"
- ✅ `results` не пуст (1-3 элемента)
- ✅ `session_id` присутствует

**Ожидаемый ответ:**
```json
{
  "status": "success",
  "intent": "search_options",
  "session_id": "sess_...",
  "results": [...],
  "results_count": 3,
  "search_params": {...}
}
```

---

### Тест #2: Missing Data

**Входные данные:**
```json
{
  "user_id": "10002",
  "message": "Найди варианты"
}
```

**Проверки:**
- ✅ HTTP статус = 200
- ✅ `status` = "missing_data"
- ✅ `missing_fields` не пуст
- ✅ `message` присутствует
- ✅ `session_id` присутствует

**Ожидаемый ответ:**
```json
{
  "status": "missing_data",
  "intent": "search_options",
  "missing_fields": ["date", "time", "guests", "location"],
  "message": "Недостаточно данных для поиска...",
  "session_id": "sess_..."
}
```

---

### Тест #3: Error

**Входные данные:**
```json
{
  "user_id": "10003",
  "message": "Найди варианты на завтра в 19:00 на двоих в центре"
}
```

**Требуется эмуляция ошибки:**

**Способ A: Отключить PostgreSQL**
```bash
# Docker
docker stop postgres

# Или через сервис
sudo systemctl stop postgresql
```

**Способ B: Неверные credentials в n8n**
1. Открыть n8n → Credentials
2. Найти PostgreSQL credential
3. Изменить пароль на неверный
4. Сохранить

**Способ C: Изменить workflow**
1. Открыть `workflow_search_worker`
2. В ноде `Query Options Catalog` изменить query на ошибочный
3. Сохранить

**Проверки:**
- ✅ `status` = "error"
- ✅ `message` присутствует

**Ожидаемый ответ:**
```json
{
  "status": "error",
  "intent": "search_options",
  "session_id": "sess_...",
  "message": "Database connection failed",
  "error_type": "orchestrator_error"
}
```

---

## 🗄️ Проверка сессий в БД

После запуска тестов можно проверить созданные сессии:

```sql
-- Последние 10 сессий
SELECT 
  session_id, 
  user_id, 
  status, 
  intent, 
  created_at, 
  updated_at
FROM session_state
ORDER BY created_at DESC
LIMIT 10;

-- Статистика по статусам
SELECT 
  status, 
  COUNT(*) as count
FROM session_state
GROUP BY status;
```

**Ожидаемые данные:**
| session_id | user_id | status | intent |
|------------|---------|--------|--------|
| sess_... | 10001 | completed | search_options |
| sess_... | 10002 | completed | search_options |
| sess_... | 10003 | error | search_options |

---

## ⚠️ Troubleshooting

### Ошибка: "n8n недоступен"

**Решение:**
```bash
# Проверьте, запущен ли n8n
docker ps | grep n8n

# Или проверьте процесс
ps aux | grep n8n

# Запустите n8n если не запущен
docker start n8n
# или
n8n start
```

### Ошибка: "curl: command not found"

**Решение:**
- **Windows:** Установите [Git](https://git-scm.com/) (включает curl)
- **Mac:** `brew install curl`
- **Linux:** `sudo apt install curl`

### Ошибка: "python: command not found"

**Решение:**
- **Windows:** Установите [Python 3](https://www.python.org/)
- **Mac:** `brew install python3`
- **Linux:** `sudo apt install python3`

### Тест #3 не проходит

**Причина:** БД подключена и работает

**Решение:** Следуйте инструкции в секции [Тест #3: Error](#тест-3-error) для эмуляции ошибки

---

## 📈 Интерпретация результатов

| Результат | Значение |
|-----------|----------|
| ✅ Все тесты пройдены | Workflow работают корректно |
| ⚠️ Тест #3 пропущен | Нормально, требует эмуляции ошибки |
| ❌ Тест #1 или #2 не прошёл | Проблема в workflow или БД |

### Возможные проблемы

| Проблема | Причина | Решение |
|----------|---------|---------|
| HTTP 404 | Webhook не найден | Проверьте path в workflow |
| HTTP 500 | Ошибка сервера | Проверьте логи n8n |
| timeout | n8n не отвечает | Увеличьте TIMEOUT в скрипте |
| Пустые results | Нет данных в БД | Заполните `options_catalog` |

---

## 📝 Примечания

1. **Тесты не очищают БД** — сессии накапливаются в `session_state`
2. **Тест #3 требует ручного вмешательства** — эмуляция ошибки
3. **Скрипты используют Python** для парсинга JSON (опционально)
4. **Можно запускать по одному** или все вместе через `run_all_tests.sh`

---

## 📚 Ссылки

- [Основной README](../README.md)
- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [CHANGELOG.md](../CHANGELOG.md)
