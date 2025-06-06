#!/bin/bash

# Инициализируем переменные для флагов
FORMAT_ALL=false
AUTO_PUSH=false
GO_FILE=""

# Парсинг аргументов командной строки
for arg in "$@"; do
  case "$arg" in
    --all|-a)
      FORMAT_ALL=true
      ;;
    --push)
      AUTO_PUSH=true
      ;;
    *.go) # Если аргумент заканчивается на .go, это имя файла
      GO_FILE="$arg"
      ;;
    *)
      echo "Неизвестный аргумент: $arg"
      echo "Использование: $0 [--all|-a] [--push] [filename.go]"
      exit 1
      ;;
  esac
done

# Проверка, если не указан ни файл, ни флаг --all
if [ -z "$GO_FILE" ] && [ "$FORMAT_ALL" = false ]; then
  echo "Использование: $0 [--all|-a] [--push] [filename.go]"
  echo "  <filename.go> - форматировать указанный файл Go."
  echo "  --all, -a     - форматировать все файлы Go в текущей директории."
  echo "  --push        - выполнить git commit и git push после форматирования."
  exit 1
fi

# Определяем, какие файлы форматировать
FILES_TO_FORMAT=""
if [ "$FORMAT_ALL" = true ]; then
  echo "Форматирование всех файлов Go в текущей директории..."
  FILES_TO_FORMAT=$(find . -name "*.go" -type f) # Находим все .go файлы
else
  # Если флаг --all не установлен, то ожидаем имя файла
  if [ -z "$GO_FILE" ]; then
    echo "Ошибка: Укажите имя файла Go или используйте флаг --all."
    exit 1
  fi
  if [ ! -f "$GO_FILE" ]; then
    echo "Ошибка: Файл '$GO_FILE' не найден."
    exit 1
  fi
  FILES_TO_FORMAT="$GO_FILE"
fi

# Форматирование файлов
for file in $FILES_TO_FORMAT; do
  echo "Форматирование '$file' с go fmt..."
  go fmt "$file"
  echo "Запись форматированного '$file' с gofmt -w..."
  gofmt -w "$file"
done

echo "Форматирование завершено."

# Логика для Git, если установлен флаг --push
if [ "$AUTO_PUSH" = true ]; then
  echo "Выполнение Git операций..."

  # Проверяем, есть ли изменения после форматирования
  if ! git diff --quiet; then
    echo "Обнаружены изменения после форматирования."
    git status
    git add $FILES_TO_FORMAT # Добавляем только те файлы, которые форматировали
    COMMIT_MESSAGE="Formatted Go files"
    if [ "$FORMAT_ALL" = true ]; then
      COMMIT_MESSAGE="Formatted all Go files"
    elif [ -n "$GO_FILE" ]; then
      COMMIT_MESSAGE="Formatted $GO_FILE"
    fi
    git commit -m "$COMMIT_MESSAGE"
    git push
    echo "Git операции завершены."
  else
    echo "Изменений после форматирования не обнаружено. Пропуск Git операций."
  fi
else
  echo "Используйте 'git status', 'git add', 'git commit' и 'git push' вручную при необходимости."
fi

echo "Скрипт завершил работу."
