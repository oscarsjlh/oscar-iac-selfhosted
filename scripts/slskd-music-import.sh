#!/usr/bin/env bash
#
# slskd-music-import.sh
#
# Move downloaded mp3 files from the slskd download folder into the music
# library on the NAS. The script checks the tags of each file first.
#
# Flow for each mp3 file:
#   1. Read the tags (album artist / artist, album, title) with ffprobe.
#   2. If tags are missing, try to infer them from the folder name and
#      the file name (patterns like "Artist - 2021 - Album" or
#      "01 - Title.mp3").
#   3. If artist, album or title is still missing, move the file to the
#      quarantine folder for manual review.
#   4. If the same track (same artist + album + title) already exists in
#      the library, delete the source file. The library copy is kept.
#   5. If the destination file name exists but the title tag is
#      different, this is a name collision: quarantine the source file.
#   6. Otherwise move the file to <DEST>/<Artist>/<Album>/.
#
# Only mp3 files are processed. All other files stay in the source folder.
#
# Usage:
#   slskd-music-import.sh [options]
#
# Options:
#   --dry-run          Show the actions, but do not change anything.
#   --write-tags       Write inferred tags into the mp3 file (mid3v2)
#                      before the move. Default: off.
#   --src DIR          Source folder.
#                      Default: /mnt/main/downloads/slskd/music
#   --dest DIR         Library folder.
#                      Default: /mnt/nas/media/music
#   --quarantine DIR   Quarantine folder.
#                      Default: /mnt/main/downloads/slskd/quarantine
#   -h, --help         Show this help.

set -euo pipefail

# --- Defaults ---------------------------------------------------------------

SRC_DIR="/mnt/main/downloads/slskd/music"
DEST_DIR="/mnt/nas/media/music"
QUAR_DIR="/mnt/main/downloads/slskd/quarantine"
DRY_RUN=false
WRITE_TAGS=false

# --- Counters ---------------------------------------------------------------

COUNT_MOVED=0
COUNT_DUPLICATE=0
COUNT_QUARANTINE=0
COUNT_COLLISION=0

# --- Functions --------------------------------------------------------------

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

usage() {
  sed -n '2,/^set -/p' "$0" | sed 's/^# \{0,1\}//; /^set -/d'
}

# Read one tag with ffprobe. Prints the first value or nothing.
get_tag() {
  local file="$1" key="$2"
  ffprobe -v error \
    -show_entries "format_tags=${key}" \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file" 2>/dev/null | head -n 1
}

# Remove characters that are not safe in folder names and trim spaces.
sanitize() {
  sed -E 's#[/:*?"<>|]##g; s/^[[:space:]]+//; s/[[:space:]]+$//'
}

# Tag value is empty or a known placeholder.
tag_missing() {
  local value="$1"
  [[ -z "${value// /}" ]] && return 0
  case "${value,,}" in
    "unknown artist"|"unknown album"|"unknown title"|"unknown") return 0 ;;
  esac
  return 1
}

# Infer artist and album from a folder name.
# Prints two lines: artist, album (each can be empty).
infer_from_folder() {
  local folder="$1"
  local name artist="" album=""
  name="$(basename "$folder")"

  if [[ "$name" == *" - "* ]]; then
    # "Artist - 2021 - Album" or "Artist - Album"
    artist="${name%% - *}"
    album="${name#* - }"
    # Drop a leading year field: "2021 - Album" -> "Album"
    if [[ "$album" =~ ^[0-9]{4}\ -\  ]]; then
      album="${album#* - }"
    fi
  else
    album="$name"
  fi

  # Remove up to two trailing "(...)" or "[...]" groups from the album,
  # for example "Album (320) [2021]" -> "Album".
  local i
  for i in 1 2; do
    album="$(sed -E 's/[[:space:]]*(\([^)]*\)|\[[^]]*\])[[:space:]]*$//' <<<"$album")"
  done

  printf '%s\n%s\n' "$artist" "$album"
}

# Infer artist and title from a file name.
# Prints two lines: artist (can be empty), title.
infer_from_filename() {
  local filename="$1"
  local base artist="" title
  base="${filename%.*}"

  # Remove a leading track number: "01 - ", "01. ", "01 ", "01_"
  base="$(sed -E 's/^[0-9]{1,3}([ ._-]+|$)//' <<<"$base")"

  if [[ "$base" == *" - "* ]]; then
    artist="${base%% - *}"
    title="${base##* - }"
  else
    title="$base"
  fi

  printf '%s\n%s\n' "$artist" "$title"
}

# Returns 0 if a file with the same title tag exists in the folder.
title_exists_in_dir() {
  local dir="$1" want="$2"
  local f t
  while IFS= read -r -d '' f; do
    t="$(get_tag "$f" title)"
    if [[ -n "$t" && "${t,,}" == "${want,,}" ]]; then
      return 0
    fi
  done < <(find "$dir" -maxdepth 1 -type f -iname '*.mp3' -print0)
  return 1
}

# Move a file into the quarantine folder. Keeps the relative path.
quarantine() {
  local file="$1" reason="$2"
  local rel target
  rel="${file#"$SRC_DIR"/}"
  target="$QUAR_DIR/$rel"
  log "QUARANTINE ($reason): $rel"
  if ! $DRY_RUN; then
    mkdir -p "$(dirname "$target")"
    mv -- "$file" "$target"
  fi
}

# --- Arguments --------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=true ;;
    --write-tags)   WRITE_TAGS=true ;;
    --src)          SRC_DIR="$2"; shift ;;
    --dest)         DEST_DIR="$2"; shift ;;
    --quarantine)   QUAR_DIR="$2"; shift ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# --- Checks -----------------------------------------------------------------

for tool in ffprobe; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Error: $tool not found." >&2; exit 1; }
done
if $WRITE_TAGS && ! command -v mid3v2 >/dev/null 2>&1; then
  echo "Error: mid3v2 not found (needed for --write-tags)." >&2
  exit 1
fi
[[ -d "$SRC_DIR" ]] || { echo "Error: source folder not found: $SRC_DIR" >&2; exit 1; }
[[ -d "$DEST_DIR" ]] || { echo "Error: library folder not found: $DEST_DIR" >&2; exit 1; }

# --- Main loop ----------------------------------------------------------------

$DRY_RUN && log "DRY RUN - no changes will be made."
log "Source:      $SRC_DIR"
log "Library:     $DEST_DIR"
log "Quarantine:  $QUAR_DIR"

while IFS= read -r -d '' FILE; do
  # Safety: never touch files that are already in quarantine.
  [[ "$FILE" == "$QUAR_DIR"* ]] && continue

  REL="${FILE#"$SRC_DIR"/}"
  BASE="$(basename "$FILE")"

  # 1. Read tags. Prefer the album artist for the folder name.
  ARTIST="$(get_tag "$FILE" album_artist)"
  [[ -z "$ARTIST" ]] && ARTIST="$(get_tag "$FILE" artist)"
  ALBUM="$(get_tag "$FILE" album)"
  TITLE="$(get_tag "$FILE" title)"

  INFERRED=false

  # 2. Infer missing tags from the folder and file name.
  if tag_missing "$ARTIST" || tag_missing "$ALBUM"; then
    mapfile -t FOLDER < <(infer_from_folder "$(dirname "$FILE")")
    if tag_missing "$ARTIST" && [[ -n "${FOLDER[0]}" ]]; then
      ARTIST="${FOLDER[0]}"; INFERRED=true
    fi
    if tag_missing "$ALBUM" && [[ -n "${FOLDER[1]}" ]]; then
      ALBUM="${FOLDER[1]}"; INFERRED=true
    fi
  fi
  if tag_missing "$ARTIST" || tag_missing "$TITLE"; then
    mapfile -t NAME < <(infer_from_filename "$BASE")
    if tag_missing "$ARTIST" && [[ -n "${NAME[0]}" ]]; then
      ARTIST="${NAME[0]}"; INFERRED=true
    fi
    if tag_missing "$TITLE" && [[ -n "${NAME[1]}" ]]; then
      TITLE="${NAME[1]}"; INFERRED=true
    fi
  fi

  # 3. Still missing -> quarantine.
  if tag_missing "$ARTIST" || tag_missing "$ALBUM" || tag_missing "$TITLE"; then
    quarantine "$FILE" "missing tags"
    COUNT_QUARANTINE=$((COUNT_QUARANTINE + 1))
    continue
  fi

  SAFE_ARTIST="$(sanitize <<<"$ARTIST")"
  SAFE_ALBUM="$(sanitize <<<"$ALBUM")"
  TARGET_DIR="$DEST_DIR/$SAFE_ARTIST/$SAFE_ALBUM"
  TARGET_FILE="$TARGET_DIR/$BASE"

  # 4/5. Duplicates and collisions.
  if [[ -f "$TARGET_FILE" ]]; then
    EXISTING_TITLE="$(get_tag "$TARGET_FILE" title)"
    if [[ -n "$EXISTING_TITLE" && "${EXISTING_TITLE,,}" == "${TITLE,,}" ]]; then
      log "DUPLICATE: $REL (same as library file ${TARGET_FILE#"$DEST_DIR"/}) - source deleted"
      $DRY_RUN || rm -- "$FILE"
      COUNT_DUPLICATE=$((COUNT_DUPLICATE + 1))
    else
      quarantine "$FILE" "name collision with ${TARGET_FILE#"$DEST_DIR"/}"
      COUNT_COLLISION=$((COUNT_COLLISION + 1))
    fi
    continue
  fi
  if [[ -d "$TARGET_DIR" ]] && title_exists_in_dir "$TARGET_DIR" "$TITLE"; then
    log "DUPLICATE: $REL (title exists in ${SAFE_ARTIST}/${SAFE_ALBUM}) - source deleted"
    $DRY_RUN || rm -- "$FILE"
    COUNT_DUPLICATE=$((COUNT_DUPLICATE + 1))
    continue
  fi

  # 6. Optional: write inferred tags, then move.
  if $WRITE_TAGS && $INFERRED; then
    $DRY_RUN || mid3v2 --artist "$ARTIST" --album "$ALBUM" --song "$TITLE" "$FILE" >/dev/null
    log "TAGGED: $REL (tags written from folder/file name)"
  fi

  log "MOVE: $REL -> ${SAFE_ARTIST}/${SAFE_ALBUM}/"
  if ! $DRY_RUN; then
    mkdir -p "$TARGET_DIR"
    mv -- "$FILE" "$TARGET_FILE"
  fi
  COUNT_MOVED=$((COUNT_MOVED + 1))

done < <(find "$SRC_DIR" -type f -iname '*.mp3' -print0)

# Remove folders that are empty after the move.
if ! $DRY_RUN; then
  find "$SRC_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi

log "Done. moved=$COUNT_MOVED duplicates=$COUNT_DUPLICATE quarantine=$COUNT_QUARANTINE collisions=$COUNT_COLLISION"
