# prhook

A tool for sorting text and files by regex templates with support for recursion, nested categories, and custom delimiters.

## Installation

```bash
git clone https://github.com/amn3zi4/prhook
cd prhook
chmod +x prhook.sh
```

## System-wide install

```bash
cd prhook
sudo make install
```

## Uninstall

```bash
cd prhook
sudo make uninstall
```

## Options

| Flag | Description |
| :--- | :--- |
| `-t, --template` | template file (required) |
| `-f, --file` | input file or directory |
| `-if, --input-format` | `text` or `files` (default: `text`) |
| `-of, --output-format` | `text` or `files` (default: `text`) |
| `-o, --output` | output directory (default: `output`) |
| `-s, --separator` | word separator (e.g. `-s ,`) |
| `-r, --recursive` | recursive directory processing |
| `-a, --add` | add to existing results |
| `-Da, --delete-add` | delete old files before adding |
| `-Se, --save-empty` | keep empty lines |
| `-h, --help` | show help |

## Template format

- Odd lines → category names (folder names)
- Even lines → regex patterns for `grep -E`
- `-` at the end of category → exclusion (`grep -v`)
- `/` for nested folders

### Template example (`templates/critical_endpoints.txt`)

```
ADMIN
admin|dashboard|console
API
api|graphql|v1
IGNORE_ADMIN -
test|dev|stage
```

## Usage examples

### 1) Standard usage

```bash
cat examples/domains.txt | ./prhook.sh -t templates/critical_endpoints.txt
# Results in output/
```

### 2) With custom separator

```bash
./prhook.sh -s "\. " -t templates/apples.txt -f examples/some_text.txt
# Results in output/some_text.txt/
```

### 3) Sort by content

```bash
./prhook.sh -c -f examples/some_files/ -t templates/dates.txt 
#results in output/
```

## Documentation

See [GUIDE.md](GUIDE.md) for details.

## License

MIT © [amn3zi4](https://github.com/amn3zi4)

