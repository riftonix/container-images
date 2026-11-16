#!/bin/sh
set -eu

fail() {
  printf 'smoke-test: %s\n' "$*" >&2
  exit 1
}

expect_output() {
  pattern=$1
  shift
  output=$("$@" 2>&1) || fail "command failed: $*"
  case $output in
    *"$pattern"*) ;;
    *) fail "unexpected output from '$*', expected '$pattern'" ;;
  esac
}

for dir in /workspace /tools /tools/bin "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" /tmp; do
  probe="$dir/.smoke-test.$$"
  : >"$probe" || fail "directory is not writable: $dir"
  rm -f "$probe"
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Keep caches and logs written by the checks out of the image.
export HOME="$work/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export npm_config_cache="$XDG_CACHE_HOME/npm"
export UV_PYTHON_DOWNLOADS=never
mkdir -p "$HOME"

for cmd in opencode bash git ssh curl rg jq unzip xz make python3 uv uvx ruff node npm npx kubectl tini; do
  command -v "$cmd" >/dev/null 2>&1 || fail "missing executable: $cmd"
done

expect_output "GNU coreutils" ls --version
expect_output "GNU findutils" find --version
expect_output "GNU grep" grep --version
expect_output "GNU sed" sed --version
expect_output "GNU Awk" awk --version
expect_output "GNU tar" tar --version
expect_output "Free Software Foundation" gzip --version
expect_output "GNU diffutils" diff --version
expect_output "GNU patch" patch --version
expect_output "GNU Make" make --version
expect_output "procps-ng" ps --version
expect_output "XZ Utils" xz --version
expect_output "UnZip" unzip -v

opencode --version >/dev/null
bash --version >/dev/null
git --version >/dev/null
ssh -V 2>/dev/null
curl --version >/dev/null
rg --version >/dev/null
jq --version >/dev/null
python3 --version >/dev/null
uv --version >/dev/null
uvx --version >/dev/null
ruff --version >/dev/null
node --version >/dev/null
npm --version >/dev/null
npx --version >/dev/null
kubectl version --client >/dev/null
tini --version >/dev/null

python3 -m venv --without-pip "$work/venv"
"$work/venv/bin/python" -c 'import ssl, sqlite3; ssl.create_default_context(); sqlite3.connect(":memory:").execute("select 1")'
uv venv --quiet --python python3 "$work/uv-venv"

git init --quiet "$work/repo"
git -C "$work/repo" -c user.name=smoke -c user.email=smoke@localhost commit --quiet --allow-empty -m smoke

printf 'smoke-test: ok\n'
