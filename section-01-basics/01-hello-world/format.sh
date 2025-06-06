#!/bin/bash

# Инициализируем переменные для флагов
FORMAT_ALL=false
AUTO_PUSH=false
GO_FILE=""
SHOW_HELP=false

# ---
## Parsing Command Line Arguments
# ---

# Парсинг аргументов командной строки
for arg in "$@"; do
  case "$arg" in
    --all|-a)
      FORMAT_ALL=true
      ;;
    --push)
      AUTO_PUSH=true
      ;;
    --help|-h)
      SHOW_HELP=true
      ;;
    *.go) # Если аргумент заканчивается на .go, это имя файла
      GO_FILE="$arg"
      ;;
    *)
      echo "Неизвестный аргумент: $arg"
      echo "Использование: $0 [--all|-a] [--push] [--help|-h] [filename.go]"
      exit 1
      ;;
  esac
done

# ---
## Displaying Help
# ---

# Функция для вывода подсказки
display_help() {
  echo "Использование: $0 [--all|-a] [--push] [--help|-h] [filename.go]"
  echo ""
  echo "Опции:"
  echo "  <filename.go> - Форматировать указанный файл Go."
  echo "  --all, -a     - Форматировать все файлы Go в текущей директории."
  echo "  --push        - Выполнить git commit и git push после форматирования."
  echo "  --help, -h    - Показать эту справку."
  echo ""
  echo "Примеры:"
  echo "  $0 my_awesome_code.go              # Форматировать один файл"
  echo "  $0 --all                          # Форматировать все Go файлы в текущей директории"
  echo "  $0 my_awesome_code.go --push      # Форматировать файл и сразу закоммитить/запушить"
  echo "  $0 -a --push                      # Форматировать все файлы и сразу закоммитить/запушить"
  echo "  $0 --help                         # Показать эту справку"
}

# Если запрошена справка, выводим ее и выходим
if [ "$SHOW_HELP" = true ]; then
  display_help
  exit 0
fi

# ---
## Input Validation
# ---

# Проверка, если не указан ни файл, ни флаг --all (и не запрошена справка)
if [ -z "$GO_FILE" ] && [ "$FORMAT_ALL" = false ]; then
  echo "Ошибка: Укажите имя файла Go или используйте флаг --all."
  display_help # Выводим справку при ошибке использования
  exit 1
fi

# ---
## Determining Files to Format
# ---

# Определяем, какие файлы форматировать
FILES_TO_FORMAT=""
if [ "$FORMAT_ALL" = true ]; then
  echo "Форматирование всех файлов Go в текущей директории..."
  # Используем -print0 и xargs -0 для корректной обработки файлов с пробелами в именах
  FILES_TO_FORMAT=$(find . -name "*.go" -type f -print0 | xargs -0)
else
  # Если флаг --all не установлен, то ожидаем имя файла
  if [ ! -f "$GO_FILE" ]; then
    echo "Ошибка: Файл '$GO_FILE' не найден."
    exit 1
  fi
  FILES_TO_FORMAT="$GO_FILE"
fi

# ---
## Formatting Files
# ---

# Форматирование файлов
for file in $FILES_TO_FORMAT; do
  echo "Форматирование '$file' с go fmt..."
  go fmt "$file"
  echo "Запись форматированного '$file' с gofmt -w..."
  gofmt -w "$file"
done

echo "Форматирование завершено."

# ---
## Git Operations
# ---

# Логика для Git, если установлен флаг --push
if [ "$AUTO_PUSH" = true ]; then
  echo "Выполнение Git операций..."

  # Проверяем, есть ли изменения после форматирования
  if ! git diff --quiet; then
    echo "Обнаружены изменения после форматирования."
    git status
    # Используем `git add -A` или `git add .` для добавления всех изменений,
    # так как `FILES_TO_FORMAT` может быть пустой строкой, если форматировалось много файлов
    # или если find выдал много файлов.
    # Более надежно добавить все изменения в Go-файлах после форматирования.
    git add $FILES_TO_FORMAT # Используем переменную, чтобы добавить только отформатированные файлы
    COMMIT_MESSAGE="Formatted Go files"
    if [ "$FORMAT_ALL" = true ]; then
      COMMIT_MESSAGE="Formatted all Go files"
    elif [ -n "$GO_FILE" ]; then
      COMMIT_MESSAGE="Formatted $GO_FILE"
    fi
    git commit -m "$COMMIT_MESSAGE"

    # Проверяем, есть ли удаленный репозиторий и пушим
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if git remote -v | grep -q 'origin'; then
        echo "Pushing changes to remote..."
        git push
        echo "Git операции завершены."
      else
        echo "Предупреждение: Отсутствует удаленный репозиторий 'origin'. Пропуск git push."
      fi
    else
      echo "Ошибка: Текущая директория не является Git репозиторием. Пропуск git push."
    fi
  else
    echo "Изменений после форматирования не обнаружено. Пропуск Git операций."
  fi
else
  echo "Используйте 'git status', 'git add', 'git commit' и 'git push' вручную при необходимости."
fi

echo "Скрипт завершил работу."
