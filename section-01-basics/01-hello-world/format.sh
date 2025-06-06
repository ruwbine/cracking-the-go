if [ -z "$1" ]; then
  echo "Usage: $0 <filename.go>"
  exit 1
fi

go_file="$1"

# Check if the file exists
if [ ! -f "$go_file" ]; then
  echo "Error: File '$go_file' not found."
  exit 1
fi

echo "Formatting '$go_file' with go fmt..."
go fmt "$go_file"

echo "Writing formatted '$go_file' with gofmt -w..."
gofmt -w "$go_file"

echo "Done."

git status
git add "$go_file"
git commit -m "Added new solution: $go_file"
git push
