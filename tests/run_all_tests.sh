#!/bin/bash
# =============================================================================
# n8n Mini Orchestrator + Worker — Запуск всех тестов
# =============================================================================
# Скрипт запускает все тестовые кейсы и выводит сводный результат
# =============================================================================

# Настройки
N8N_URL="${N8N_URL:-http://localhost:5678}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Счётчики
PASSED=0
FAILED=0
SKIPPED=0
TOTAL=0

echo "=============================================="
echo "n8n Mini Orchestrator + Worker"
echo "Запуск всех тестов"
echo "=============================================="
echo ""
echo "${BLUE}N8N_URL:${NC} $N8N_URL"
echo "${BLUE}Дата:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Проверка доступности n8n
echo "${YELLOW}Проверка доступности n8n...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "$N8N_URL" | grep -q "200\|302\|301"; then
  echo "${GREEN}✓ n8n доступен${NC}"
else
  echo "${RED}✗ n8n недоступен по адресу $N8N_URL${NC}"
  echo "${YELLOW}Убедитесь, что n8n запущен и доступен${NC}"
  exit 1
fi
echo ""

# Функция запуска теста
run_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .sh | sed 's/^[0-9]*_test_//')
  
  TOTAL=$((TOTAL + 1))
  
  echo ""
  echo "----------------------------------------------"
  
  if [ ! -f "$test_file" ]; then
    echo "${RED}✗ Файл не найден: $test_file${NC}"
    FAILED=$((FAILED + 1))
    return 1
  fi
  
  # Запуск теста
  bash "$test_file"
  EXIT_CODE=$?
  
  if [ $EXIT_CODE -eq 0 ]; then
    PASSED=$((PASSED + 1))
  elif [ $EXIT_CODE -eq 2 ]; then
    SKIPPED=$((SKIPPED + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  
  return $EXIT_CODE
}

# Запуск тестов
echo "${CYAN}Запуск тестов...${NC}"
echo ""

run_test "$SCRIPT_DIR/01_test_success.sh"
run_test "$SCRIPT_DIR/02_test_missing_data.sh"

# Тест #3 требует подтверждения, спрашиваем заранее
echo ""
echo "----------------------------------------------"
echo "${YELLOW}Тест #3 (ERROR) требует эмуляции ошибки БД${NC}"
read -p "Запустить тест #3? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  run_test "$SCRIPT_DIR/03_test_error.sh"
else
  SKIPPED=$((SKIPPED + 1))
  echo "${YELLOW}Тест #3 пропущен${NC}"
fi

# Вывод результатов
echo ""
echo "=============================================="
echo "РЕЗУЛЬТАТЫ"
echo "=============================================="
echo ""
echo "Всего тестов:  $TOTAL"
echo -e "${GREEN}Пройдено:      $PASSED${NC}"
echo -e "${RED}Не пройдено:   $FAILED${NC}"
echo -e "${YELLOW}Пропущено:     $SKIPPED${NC}"
echo ""

# Проверка сессий в БД (опционально)
echo "----------------------------------------------"
echo "${YELLOW}Проверка сессий в PostgreSQL...${NC}"
echo ""
echo "Выполните SQL запрос для проверки:"
echo ""
echo "SELECT session_id, user_id, status, intent, created_at"
echo "FROM session_state"
echo "ORDER BY created_at DESC"
echo "LIMIT 10;"
echo ""

# Итоговый статус
if [ $FAILED -eq 0 ]; then
  echo "${GREEN}=============================================="
  echo "ВСЕ ТЕСТЫ ПРОЙДЕНЫ ✓"
  echo "==============================================${NC}"
  exit 0
else
  echo "${RED}=============================================="
  echo "ЕСТЬ НЕУДАЧНЫЕ ТЕСТЫ ✗"
  echo "==============================================${NC}"
  exit 1
fi
