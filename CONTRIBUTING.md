# Contributing to n8n Mini Orchestrator + Worker

Спасибо за интерес к проекту! Этот документ описывает правила внесения изменений.

## 📋 Содержание

- [Как сообщить об ошибке](#как-сообщить-об-ошибке)
- [Как предложить функцию](#как-предложить-функцию)
- [Внесение изменений](#внесение-изменений)
- [Стандарты кода](#стандарты-кода)
- [Pull Request Process](#pull-request-process)

---

## Как сообщить об ошибке

1. Проверьте существующие [Issues](../../issues) — возможно, проблема уже известна
2. Создайте новый [Bug Report](../../issues/new?template=bug_report.md)
3. Укажите:
   - Версию n8n
   - Шаги для воспроизведения
   - Ожидаемое и фактическое поведение
   - Логи ошибок из n8n

---

## Как предложить функцию

1. Проверьте существующие [Issues](../../issues)
2. Создайте [Feature Request](../../issues/new?template=feature_request.md)
3. Опишите:
   - Какую проблему решает функция
   - Предлагаемое решение
   - Альтернативные варианты

---

## Внесение изменений

### Для контрибьюторов

1. **Fork** репозиторий
2. **Clone** вашу копию:
   ```bash
   git clone https://github.com/YOUR_USERNAME/n8n-mini-orchestrator.git
   ```
3. **Создайте ветку**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Внесите изменения**
5. **Проверьте** workflow в n8n
6. **Закоммитьте**:
   ```bash
   git commit -m "feat: add your feature description"
   ```
7. **Push** в вашу ветку:
   ```bash
   git push origin feature/your-feature-name
   ```
8. **Создайте Pull Request**

---

## Стандарты кода

### Workflow файлы

- **Naming convention:** `orchestrator_*`, `search_worker_*`
- **Node names:** понятные имена, префиксы `orch-`, `worker-`
- **Notes:** добавляйте описания к нодам
- **Connections:** без пересечений, читаемая структура

### JavaScript код в Code нодах

```javascript
// ✅ Хорошо: понятные имена, комментарии
const inputData = $input.first()?.json ?? {};
const sessionId = `sess_${Date.now()}_${randomString()}`;

// ❌ Плохо: магические числа, нет пояснений
const x = $input.first().json;
const id = 'sess_' + Date.now();
```

### SQL запросы

```sql
-- ✅ Хорошо: форматирование, комментарии
SELECT id, name, area, capacity
FROM options_catalog
WHERE is_active = TRUE
  AND area ILIKE $1
ORDER BY rating DESC;

-- ❌ Плохо: одна строка
SELECT id,name,area,capacity FROM options_catalog WHERE is_active=TRUE AND area ILIKE $1 ORDER BY rating DESC;
```

### Документация

- **README.md:** обязательное обновление при изменениях
- **CHANGELOG.md:** запись о новых функциях/исправлениях
- **ARCHITECTURE.md:** обновление при изменении архитектуры

---

## Pull Request Process

1. **Тестирование:** проверьте все 3 тестовых кейса
   ```bash
   cd tests
   ./run_all_tests.sh
   ```
2. **Обновите документацию:** README, CHANGELOG
3. **Проверьте .gitignore:** нет ли чувствительных данных
4. **Создайте PR** с описанием изменений
5. **Code Review:** дождитесь проверки
6. **Merge:** после approval

---

## Коммиты

Используйте [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` новая функция
- `fix:` исправление ошибки
- `docs:` документация
- `style:` форматирование
- `refactor:` рефакторинг
- `test:` тесты
- `chore:` сборка, зависимости

**Примеры:**
```bash
feat: add AI-powered parameter extraction
fix: correct session status update in database
docs: update README with test instructions
```

---

## Вопросы?

- [Discussions](../../discussions) — для общих вопросов
- [Issues](../../issues) — для багов и фич

---

## Лицензия

Проект распространяется под [MIT License](../LICENSE).
