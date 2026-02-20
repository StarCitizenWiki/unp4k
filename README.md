# unp4k [![Release](https://github.com/dolkensp/unp4k/actions/workflows/release.yaml/badge.svg)](https://github.com/dolkensp/unp4k/actions/workflows/release.yaml)

These tools open, decrypt, and extract data from Star Citizen `.p4k` files.

## Platform support

| Tool | Windows | Linux | macOS |
| --- | --- | --- | --- |
| `unp4k` | Supported | Supported | Supported |
| `unforge.cli` | Supported | Supported | Supported |
| `unp4k.fs` | Supported | Not supported | Not supported |

`unp4k.fs` uses Dokan, so it remains Windows-only.

## Prerequisites

- .NET SDK 8.0 or newer (10.0 recommended for publish artifacts).
- For Linux/macOS runtime extraction of ZSTD-compressed entries:
  - Linux: install `libzstd` (`sudo apt-get install -y libzstd1` on Debian/Ubuntu).
  - macOS: install `zstd` (`brew install zstd`).

## Quickstart

1. Windows GUI style: drag `Data.p4k` from the `StarCitizen\LIVE` folder onto `unp4k.exe`.
2. CLI: run `unp4k <path-to-Data.p4k> [filter]`.

Example:

```bash
unp4k /path/to/Data.p4k "*.xml"
```

The filter does not fully support wildcards. `*.ext` works for extension filtering, but broader glob behavior is limited.

## Build

```bash
dotnet restore
dotnet build src/unp4k/unp4k.csproj -c Release -f net10.0
dotnet build src/unforge.cli/unforge.cli.csproj -c Release -f net10.0
```

## Publish (self-contained)

Examples:

```bash
dotnet publish src/unp4k/unp4k.csproj -c Release -f net10.0 -r win-x64
dotnet publish src/unp4k/unp4k.csproj -c Release -f net10.0 -r linux-x64
dotnet publish src/unp4k/unp4k.csproj -c Release -f net10.0 -r osx-arm64

dotnet publish src/unforge.cli/unforge.cli.csproj -c Release -f net10.0 -r win-x64
dotnet publish src/unforge.cli/unforge.cli.csproj -c Release -f net10.0 -r linux-x64
dotnet publish src/unforge.cli/unforge.cli.csproj -c Release -f net10.0 -r osx-arm64
```

`unp4k.fs` publish remains Windows-only:

```bash
dotnet publish src/unp4k.fs/unp4k.fs.csproj -c Release -f net10.0 -r win-x64
```

## Build with Docker (Linux/macOS binaries)

Build the local builder image:

```bash
docker build --no-cache -f Dockerfile.build -t unp4k-builder .
```

Run the build and write artifacts to `./artifacts`:

```bash
mkdir -p artifacts
docker run --rm -v "$PWD/artifacts:/artifacts" unp4k-builder
```

Override target RIDs if needed:

```bash
docker run --rm \
  -e RIDS="linux-x64 osx-arm64" \
  -v "$PWD/artifacts:/artifacts" \
  unp4k-builder
```

# unp4k.fs - Virtual Filesystem

`unp4k.fs` mounts a `.p4k` or `.dcb` file as a read-only virtual drive using [Dokan](https://github.com/dokan-dev/dokany), letting you browse and read Star Citizen game assets directly in Windows Explorer without extracting anything to disk.

**Prerequisites:** [Dokan](https://github.com/dokan-dev/dokany/releases) must be installed.

## Usage:

```
unp4k.fs.exe [path-to-file] [mount-point]
```

- `path-to-file` — path to a `.p4k` or `.dcb` file. Defaults to `Data.p4k` in the current directory.
- `mount-point` — drive letter or empty directory to mount to (e.g. `S:` or `C:\sc-data`). Defaults to `<filename>.unp4k` next to the input file.

**Examples:**

```
unp4k.fs.exe
unp4k.fs.exe "D:\Roberts Space Industries\StarCitizen\LIVE\Data.p4k"
unp4k.fs.exe "D:\Roberts Space Industries\StarCitizen\LIVE\Data.p4k" S:
unp4k.fs.exe game.dcb X:\virtual
```

Once mounted, CryXML files are served as standard XML and DataForge records are extracted as XML on demand. Press `Q` or `Esc` to unmount and exit.

## Interactive options (while mounted):

| Key | Option | Default | Range |
|-----|--------|---------|-------|
| `1` | Max reference depth — how deeply nested DataForge references are followed | 1 | 1–1000 |
| `2` | Max pointer depth — recursion safety limit for DataForge structures | library default | 10–1000 |
| `3` | Max nodes — node count safety limit per DataForge record | library default | 1000–1000000 |

# File Format Overview:

`p4k` files used by Star Citizen are Zip archives.

Star Citizen uses multiple archive modes, including STORE, DEFLATE, and custom ZSTD handling.

Some archive data is additionally encrypted; these tools use the known CryEngine-compatible key to decrypt supported entries.

Inside `.p4k`, XML files are often stored as CryXML rather than raw XML.

`unforge.cli` can deserialize CryXML and DataForge (`.dcb`) formats into XML output.
