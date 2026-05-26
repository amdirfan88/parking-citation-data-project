mkdir -p data/chunks

LIMIT=50000
OFFSET=$(cat offset.txt 2>/dev/null || echo 0)

while true; do
  FILE="data/chunks/parking_${OFFSET}.csv"
  TEMP="${FILE}.tmp"

  if [ -s "$FILE" ]; then
    OFFSET=$((OFFSET + LIMIT))
    echo "$OFFSET" > offset.txt
    continue
  fi

  if ! curl -fL --retry 10 --retry-all-errors --connect-timeout 30 \
    "https://data.lacity.org/resource/4f5p-udkv.csv?\$limit=$LIMIT&\$offset=$OFFSET" \
    -o "$TEMP"; then
    echo "$OFFSET" > offset.txt
    echo "failed at offset $OFFSET"
    rm -f "$TEMP"
    break
  fi

  mv "$TEMP" "$FILE"
  echo $((OFFSET + LIMIT)) > offset.txt

  if [ "$(tail -n +2 "$FILE" | wc -l | tr -d ' ')" -lt "$LIMIT" ]; then
    rm -f offset.txt
    break
  fi

  OFFSET=$((OFFSET + LIMIT))
done