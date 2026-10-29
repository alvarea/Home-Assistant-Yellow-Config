# Prepara gh para la sesión: lo instala si falta (no persiste entre sesiones), lo pone
# en el PATH y exporta GH_TOKEN si la sesión no trae ya uno válido.
#
# Uso (al inicio de CADA bloque de shell que use gh o tools/homy-*.sh — cada bloque
# puede ser un proceso nuevo):   source tools/homy-gh.sh
#
# Idempotente: si gh ya está instalado en esta sesión, solo exporta (instantáneo).
# GH_PROJECT_TOKEN no hace falta exportarlo: tools/homy-*.sh lo leen de CLAUDE.local.md.
# Detecta OS/arquitectura: Linux publica .tar.gz, macOS .zip.

_hg_d="${TMPDIR:-/tmp}/ghcli"
_hg_bin=$(ls -d "$_hg_d"/gh_*/bin 2>/dev/null | head -1)
if [ -z "$_hg_bin" ]; then
  _hg_os=$(uname -s); _hg_arch=$(uname -m)
  [ "$_hg_arch" = "x86_64" ] && _hg_arch=amd64
  [ "$_hg_arch" = "aarch64" ] && _hg_arch=arm64
  if [ "$_hg_os" = "Darwin" ]; then _hg_pat="macOS_${_hg_arch}\.zip"; else _hg_pat="linux_${_hg_arch}\.tar\.gz"; fi
  mkdir -p "$_hg_d"
  _hg_url=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep -o "\"browser_download_url\": *\"[^\"]*${_hg_pat}\"" | head -1 | cut -d'"' -f4)
  if [ -n "$_hg_url" ] && curl -sL "$_hg_url" -o "$_hg_d/gh.archive"; then
    if [ "$_hg_os" = "Darwin" ]; then unzip -qo "$_hg_d/gh.archive" -d "$_hg_d"; else tar -xzf "$_hg_d/gh.archive" -C "$_hg_d"; fi
  fi
  _hg_bin=$(ls -d "$_hg_d"/gh_*/bin 2>/dev/null | head -1)
fi
if [ -z "$_hg_bin" ]; then
  echo "homy-gh: ERROR, no se pudo instalar gh" >&2
else
  case ":$PATH:" in *":$_hg_bin:"*) ;; *) export PATH="$_hg_bin:$PATH" ;; esac
  if ! gh auth status >/dev/null 2>&1; then
    _hg_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    export GH_TOKEN=$(grep '^GH_TOKEN=' "$_hg_root/CLAUDE.local.md" 2>/dev/null | cut -d= -f2)
  fi
  if gh auth status >/dev/null 2>&1; then echo "homy-gh: OK ($(gh --version | head -1 | cut -d' ' -f3))"; else echo "homy-gh: ERROR, gh sin autenticar (¿falta GH_TOKEN en CLAUDE.local.md?)" >&2; fi
fi
unset _hg_d _hg_bin _hg_os _hg_arch _hg_pat _hg_url _hg_root
