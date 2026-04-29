#!/bin/bash
set -euo pipefail

TEMPLATE_=""
FILE_=""
INPUT_FORMAT_="text"
OUTPUT_FORMAT_="text"
RESULT_=""
WORD_=""
OUTPUT_="output"
OTHERS_="none"
HELP_="none"
ADD_="none"
DELETE_="none"
RECURSIVE_="false"
SEPARATOR_=""
TMP_DIR=""
SAVE_EMPTY_="none"
CONTENT_="none"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--template)
      TEMPLATE_="$2"
      shift 2
      ;;
    -f|--file)
      FILE_="$2"
      shift 2
      ;;
    -if|--input-format)
      INPUT_FORMAT_="$2"
      shift 2
      ;;
    -of|--output-format)
      OUTPUT_FORMAT_="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_="$2"
      shift 2
      ;;
    -h|--help)
      HELP_="true"
      shift
      ;;
    -a|--add)
      ADD_="true"
      shift
      ;;
    -Da|--delete-add)
      ADD_="true"
      DELETE_="true"
      shift
      ;;
    -r|--recursive)
      RECURSIVE_="true"
      shift
      ;;
    -s|--separator)
      SEPARATOR_="$2"
      shift 2
      ;;
    -Se|--save-empty)
      SAVE_EMPTY_="true"
      shift 2
      ;;
    -c|--content)
      CONTENT_="true"
      INPUT_FORMAT_="files"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
      esac
done

if [[ "$HELP_" == "true" ]]; then
  echo -e "\n[Usage]:\n ./main.sh [options]\n"
  echo -e "[Description]:\n  tool for filtering and sorting text files line by line and files by name (guide in GUIDE.md)\n"
  echo "[Options]:"
  echo "  -t, --template <file>            choose sorting template (examples in /lists)"
  echo "  -f, --file <file>                specify file/directory with files for sorting"
  echo "  -if, --input-format <text/files> choose type for input (default: text)"
  echo "  -of, --output-format <text/files choose type for results (default: text)"
  echo "  -h, --help                       show this help"
  echo "  -a, --add                        adding results to an existing directory (recommended same format)"
  echo "  -Da, --delete-add                delete exists files in add-mode & files output before copying"
  echo "  -r, --recursive                  recursive sorting all files/text in choosed directory"
  echo "  -s, --separator <char>           select a word separator in input text"
  echo "  -Se, --save-empty                dont delete empty lines in output"
  echo "  -c, --content                    sorting input files by content (need -if and -of files)"
  exit 0
fi

remove_first() {
  local path_="${1%/}"
  if [[ -z "$path_" ]]; then
    RESULT_=""
  elif [[ "$path_" != */* ]]; then
    RESULT_=""
  else
    RESULT_="${path_%/*}"
  fi
}

get_last_word() {
  local path_="${1%/}"
  if [[ -z "$path_" ]]; then
    WORD_=""
  elif [[ "$path_" != */* ]]; then
    WORD_="$path_"
  else
    WORD_="${path_##*/}"
  fi
}

if [[ -z "$FILE_" && ! -t 0 ]]; then
  INPUT_FORMAT_="text"
  TMP_DIR="/tmp/prhook_$$"
  mkdir -p "$TMP_DIR" 2>/dev/null
  trap 'rm -rf "$TMP_DIR"' EXIT
  temp_input_=$(mktemp -p "$TMP_DIR" priorhook_XXXXXXXX)
  cat > "$temp_input_"
  FILE_="$temp_input_"
fi

get_last_word "$FILE_"
[[ "$INPUT_FORMAT_" != "files" && "$INPUT_FORMAT_" != "text" ]] && echo "Error: input format not exists" && exit 1
[[ "$OUTPUT_FORMAT_" != "files" && "$OUTPUT_FORMAT_" != "text" ]] && echo "Error: output formats are not exists" && exit 1

[[ ! -e "$FILE_" ]] && echo "Error: file $FILE_ not found" && exit 1
[[ ! -f "$TEMPLATE_" ]] && echo "Error: template file $TEMPLATE_ not found" && exit 1
[[ "$INPUT_FORMAT_" == "files" && ! -d "$FILE_" ]] && echo "Error: --if files requires a directory" && exit 1
[[ "$INPUT_FORMAT_" == "text" && ! -f "$FILE_" ]]&& echo "Error: --if text requires a txt file" && exit 1

[[ "$ADD_" == "true" ]] && WORD_=""
[[ "$OUTPUT_" == "output" ]] && rm -rf "$OUTPUT_/$WORD_" && mkdir -p "$OUTPUT_/$WORD_" && echo "Warning: output directory not selected, using output/$WORD_"
[[ "$CONTENT_" == "true" && "$INPUT_FORMAT_" == "text" || "$OUTPUT_FORMAT_" == "text" ]] && echo "Warning: flag -c needs a files input and output, changing format" && INPUT_FORMAT_="files" && OUTPUT_FORMAT_="files"

lengh_=$(wc -l < "$TEMPLATE_" 2>/dev/null)
iterations_=$(($lengh_ / 2))
place_=0
[[ $iterations_ -eq 0 ]] && echo "Warning: template is empty, no sort"

if [[ "$INPUT_FORMAT_" == "files" ]]; then
  if [[ "$OUTPUT_FORMAT_" == "files" ]]; then
    if [[ "$RECURSIVE_" != "true" ]]; then
      case "$DELETE_" in
        true) cp "$FILE_"/* "$OUTPUT_/$WORD_/" ;;
        *) cp -n "$FILE_"/* "$OUTPUT_/$WORD_/" ;;
      esac
    else
      find "$FILE_" -type f > "$TMP_DIR/files.txt"
      while IFS= read -r string_; do
        case "$DELETE_" in
          true) cp "$string_" "$OUTPUT_/$WORD_/" ;;
          *) cp -n "$string_" "$OUTPUT_/$WORD_/" ;;
        esac
      done < "$TMP_DIR/files.txt"
      rm "$TMP_DIR/files.txt"
    fi
  fi
  case "$ADD_" in
    true) find "$FILE_" -maxdepth 1 -type f -printf "%f\n" | grep -v "/" | tr '/' '|' >> "$OUTPUT_/output.txt" && sort -u "$OUTPUT_/output.txt" -o "$OUTPUT_/output.txt" ;;
    *) find "$FILE_" -maxdepth 1 -type f -printf "%f\n" | grep -v "/" | tr '/' '|'> "$OUTPUT_/$WORD_/output.txt" ;;
  esac
elif [[ "$INPUT_FORMAT_" == "text" ]]; then
  if [[ "$RECURSIVE_" != "true" ]]; then
    case "$ADD_" in
      true) cat "$FILE_" >> "$OUTPUT_/output.txt" && sort -u "$OUTPUT_/output.txt" -o "$OUTPUT_/output.txt" ;;
      *) cp "$FILE_" "$OUTPUT_/$WORD_/output.txt" ;;
    esac
  else
    find "$FILE_" -type f > "$TMP_DIR/files.txt"
    while IFS= read -r string_; do
      cat "$string_" >> "$OUTPUT_/$WORD_/output.txt"
    done < "$TMP_DIR/files.txt"
    sort -u "$OUTPUT_/$WORD_/output.txt" -o "$OUTPUT_/$WORD_/output.txt"
    rm "$TMP_DIR/files.txt"
  fi
  [[ "$SEPARATOR_" != "" ]] && sed -Ei "s/${SEPARATOR_}/\n/g" "$OUTPUT_/$WORD_/output.txt"
  if [[ "$OUTPUT_FORMAT_" == "files" ]]; then
    while IFS= read -r string_; do
      touch "$OUTPUT_/$WORD_/$(echo "$string_" | tr '/' '|')" 2>/dev/null
    done < "$OUTPUT_/$WORD_/output.txt"
  fi
fi
[[ "$SAVE_EMPTY_" != "true" ]] && sed -i "/^$/d" "$OUTPUT_/$WORD_/output.txt"

for ((i=1; i<=iterations_; i++)); do
  filter_=$(sed -n "$((2+place_))p" "$TEMPLATE_" 2>/dev/null)
  template_=$(sed -n "$((1+place_))p" "$TEMPLATE_" 2>/dev/null)
  if [[ "${template_: -1}" == "-" ]]; then
    mode_="v"
    template_=${template_%??}
  else
    mode_="nv"
  fi
  mkdir -p "$OUTPUT_/$WORD_/$template_" 2>/dev/null
  remove_first "$template_"
  if [[ -n "$RESULT_" ]]; then
    RESULT_="${RESULT_}/"
  fi

  if [[ "$CONTENT_" != "true" ]]; then
    PATH_="$"
    if [[ "$mode_" != "v" ]]; then
      case "$ADD_" in
        true) grep -E "$filter_" "$OUTPUT_/${RESULT_}output.txt" >> "$OUTPUT_/$template_/output.txt" && sort -u "$OUTPUT_/$template_/output.txt" -o "$OUTPUT_/$template_/output.txt" ;;
        *) grep -E "$filter_" "$OUTPUT_/$WORD_/${RESULT_}output.txt" > "$OUTPUT_/$WORD_/$template_/output.txt" ;;
      esac
    elif [[ "$mode_" == "v" ]]; then
      case "$ADD_" in
        true) grep -v -E "$filter_" "$OUTPUT_/${RESULT_}output.txt" >> "$OUTPUT_/$template_/output.txt" && sort -u "$OUTPUT_/$template_/output.txt" -o "$OUTPUT_/$template_/output.txt" ;;
        *) grep -v -E "$filter_" "$OUTPUT_/$WORD_/${RESULT_}output.txt" > "$OUTPUT_/$WORD_/$template_/output.txt" ;;
      esac
    fi
  else
    if [[ "$mode_" != "v" ]]; then
      while IFS= read -r string_; do
        if grep -E -q "$filter_" "$OUTPUT_/$WORD_/$string_"; then
          echo "$string_" >> "$OUTPUT_/$WORD_/$template_/output.txt"
        fi
      done < "$OUTPUT_/$WORD_/${RESULT_}output.txt"
    elif [[ "$mode_" == "v" ]]; then
      while IFS= read -r string_; do
        if ! grep -E -q "$filter_" "$OUTPUT_/$WORD_/$string_"; then
          echo "$string_" >> "$OUTPUT_/$WORD_/$template_/output.txt"
        fi
      done < "$OUTPUT_/$WORD_/${RESULT_}output.txt"
    fi
  fi

  if [[ "$OUTPUT_FORMAT_" == "files" ]]; then
    while IFS= read -r string_; do
        ln -s "$OUTPUT_/$WORD_/$(echo "$string_" | tr '/' '|')" "$OUTPUT_/$WORD_/$template_/$(echo "$string_" | tr '/' '|')" 2>/dev/null || true
    done < "$OUTPUT_/$WORD_/$template_/output.txt"
  fi
  [[ "$SAVE_EMPTY_" != "true" ]] && sed -i "/^$/d" "$OUTPUT_/$WORD_/$template_/output.txt"
  ((place_ += 2))
done
[[ "$TMP_DIR" != "" ]] && rm -rf "$TMP_DIR"
