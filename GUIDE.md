# prhook — detailed guide

## Default values

- `-if` (input format) defaults to: `text`
- `-of` (output format) defaults to: `text`

## How the script works

1. Receives data (via `stdin` for text or `-f` for files/directories)
2. Sorts according to the template (`-t`)
3. Outputs results to the `output/` folder (or the one specified with `-o`)

## Input and output formats

Specified via `-if` (input format) and `-of` (output format).

### `-if` — what is passed as input

| Value   | Description                              |
| :------ | :--------------------------------------- |
| `text`  | the file is read line by line as text    |
| `files` | the directory is processed by file names |

### `-of` — what is created as output

| Value   | Description                                                                |     |
| :------ | :------------------------------------------------------------------------- | --- |
| `text`  | a root `output.txt` file is created                                        |     |
| `files` | empty files are created (names taken from input lines, `/` replaced with ` | `)  |

### `-r` — recursive processing

| `-if`   | Behavior                                                                 |
| :------ | :----------------------------------------------------------------------- |
| `text`  | reads **all files** in all subdirectories, results are merged and sorted |
| `files` | takes **all files** from all subdirectories                              |

### `-a` — append to existing results

- Does not delete previous results, instead adds new lines to `output.txt`
- In `-of files` mode, **does not replace** existing files

### `-Da` — delete-add
- Same as `-a`, but existing files in `-of files` mode replacing

## Additional flags

| Flag  | Description                                                                                                                  |
| :---- | :--------------------------------------------------------------------------------------------------------------------------- |
| `-Se` | keep empty lines in `output.txt`                                                                                             |
| `-s`  | replace characters with newline (only for `-if text`). Pass in quotes, escape special characters with ``. Example: `-s ". "` |

## Templates (`-t`)

The template file has a strict structure:

- **Odd lines** → folder (category) names
- **Even lines** → filters (regular expressions for `grep -E`)

### Normal templates

Example:

```text
ADMIN
admin|dashboard|console
```

Lines containing `admin`, `dashboard`, or `console` go into the `ADMIN/` folder.

### Exclusion templates

Add `-` after the category name (with a space):

```text
IGNORE_ADMIN -
admin|dashboard
```

Lines **not** containing `admin` or `dashboard` go into `IGNORE_ADMIN/`.

### Nested templates

Use `/` to create subdirectories inside other categories.

*[id668332|*Normal] nested:**

```text
ADMIN
admin|dashboard
ADMIN/API
api|graphql
```

- First `ADMIN/` is created: lines with `admin|dashboard` go there
- Then inside `ADMIN/`, `ADMIN/API/` is created: lines with `api|graphql` go there (taken from the already filtered `ADMIN/` set)

*[id302735416|*Exclusion] nested:**

```text
ADMIN
admin|dashboard
ADMIN/IGNORE_API -
api|graphql
```

Lines from `ADMIN/` that *[id8479617|*do] not** contain `api` or `graphql` go into `ADMIN/IGNORE_API/`.

### Filter syntax

Filters are `grep -E` regular expressions. Example:

```text
admin|env\.|git\.|s[0-9]
```

Matches lines containing:
- `admin`
- `env.` (dot is escaped → literal dot)
- `git.`
- `s` + any digit from 0 to 9

## Full template example

```text
ADMIN
admin|dashboard|console
API
api|graphql|v1
ADMIN/API
admin/api|admin/graphql
IGNORE_DEV -
dev|test|stage
ADMIN/IGNORE_API -
bad|broken
```

## Temporary file cleanup

The script creates a temporary folder `/tmp/prhook_$$` and removes it on exit (even on error or Ctrl+C).
