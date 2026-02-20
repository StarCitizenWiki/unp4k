#!/usr/bin/env bash

set -euo pipefail

CONFIGURATION="${CONFIGURATION:-Release}"
FRAMEWORK="${FRAMEWORK:-net10.0}"
RIDS="${RIDS:-linux-x64 linux-arm64 osx-x64 osx-arm64}"
OUTPUT_ROOT="${OUTPUT_ROOT:-/artifacts}"

PROJECTS=(
  "src/unp4k/unp4k.csproj"
  "src/unforge.cli/unforge.cli.csproj"
)

echo "Restoring solution..."
dotnet restore unp4k.sln

mkdir -p "${OUTPUT_ROOT}"

for rid in ${RIDS}; do
  echo "Publishing RID: ${rid}"

  for project in "${PROJECTS[@]}"; do
    project_name="$(basename "$(dirname "${project}")")"
    out_dir="${OUTPUT_ROOT}/${rid}/${project_name}"

    echo "  -> ${project_name} (${FRAMEWORK}, ${CONFIGURATION})"
    dotnet publish "${project}" \
      -c "${CONFIGURATION}" \
      -f "${FRAMEWORK}" \
      -r "${rid}" \
      -o "${out_dir}" \
      --self-contained true \
      /p:PublishSingleFile=true \
      /p:PublishTrimmed=false
  done
done

echo
echo "Publish complete. Artifacts written to ${OUTPUT_ROOT}"
