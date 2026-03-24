      
#!/usr/bin/env bash
set -euo pipefail

CODEX_DIR="${HOME}/.codex"
CONFIG_FILE="${CODEX_DIR}/config.toml"
AUTH_FILE="${CODEX_DIR}/auth.json"
AUTO_YES=""
API_KEY=""

if [[ "${1-}" == "-y" ]]; then
  AUTO_YES=1
  shift || true
fi

if [[ $# -gt 0 ]]; then
  API_KEY="$1"
fi

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//"/\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

write_config() {
  cat > "$CONFIG_FILE" <<'EOF'
model_provider = "OpenAI"
model = "gpt-5.4"
review_model = "gpt-5.4"
model_reasoning_effort = "xhigh"
disable_response_storage = true

[model_providers.OpenAI]
name = "OpenAI"
base_url = "https://capi.quan2go.com/openai"
wire_api = "responses"
requires_openai_auth = true
EOF
}

write_auth() {
  local escaped_key
  escaped_key="$(json_escape "$1")"
  printf '{\n  "OPENAI_API_KEY": "%s"\n}\n' "$escaped_key" > "$AUTH_FILE"
}

read_confirm() {
  local answer
  while true; do
    read -r -p "确认继续? [Y/N]: " answer
    case "$answer" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo]) return 1 ;;
      *) echo "请输入 Y 或 N。" ;;
    esac
  done
}

read_api_key() {
  local input_key
  read -r -p "请输入激活码 / OPENAI_API_KEY: " input_key
  if [[ -z "$input_key" ]]; then
    echo "未输入激活码，已取消。"
    exit 1
  fi
  API_KEY="$input_key"
}

printf '\n'
printf '========== Codex 配置更新工具 ==========\n\n'
printf '目标目录: "%s"\n' "$CODEX_DIR"
printf '配置文件: "%s"\n' "$CONFIG_FILE"
printf '认证文件: "%s"\n\n' "$AUTH_FILE"

if [[ ! -d "$CODEX_DIR" ]]; then
  echo '[1/5] 未找到 .codex，请确保已经安装 CLI 或 Codex VSCode 插件，安装后会自动生成 .codex 目录。'
  echo '[1/5] 现在将尝试自动创建目录...'
  mkdir -p "$CODEX_DIR"
else
  echo '[1/5] 已找到 .codex 目录。'
fi

echo '[2/5] 检查当前文件状态...'
if [[ -f "$CONFIG_FILE" ]]; then
  echo '- 已找到 config.toml'
else
  echo '- 未找到 config.toml，稍后将自动创建'
fi

if [[ -f "$AUTH_FILE" ]]; then
  echo '- 已找到 auth.json'
else
  echo '- 未找到 auth.json，稍后将自动创建'
fi

echo
echo '即将把 config.toml 替换为预设内容，并更新 auth.json 中的 OPENAI_API_KEY。'
if [[ -z "$AUTO_YES" ]]; then
  if ! read_confirm; then
    echo '已取消，未做任何修改。'
    exit 0
  fi
fi

BACKUP_DIR=""
if [[ -f "$CONFIG_FILE" || -f "$AUTH_FILE" ]]; then
  STAMP="$(date +%Y%m%d_%H%M%S)"
  BACKUP_DIR="${CODEX_DIR}/backup/${STAMP}"
  echo '[3/5] 正在备份旧文件...'
  mkdir -p "$BACKUP_DIR"
  [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$BACKUP_DIR/config.toml.bak"
  [[ -f "$AUTH_FILE" ]] && cp "$AUTH_FILE" "$BACKUP_DIR/auth.json.bak"
  printf -- '- 备份目录: "%s"\n' "$BACKUP_DIR"
else
  echo '[3/5] 当前没有旧文件需要备份。'
fi

echo '[4/5] 正在写入 config.toml...'
write_config

echo '[5/5] 正在更新 auth.json...'
if [[ -z "$API_KEY" ]]; then
  read_api_key
fi
write_auth "$API_KEY"

echo
echo '已完成（如果 CLI 或 Code 插件打开的情况下，需要重新打开才会读取到新配置）'
printf -- '- config.toml: "%s"\n' "$CONFIG_FILE"
printf -- '- auth.json: "%s"\n' "$AUTH_FILE"
if [[ -n "$BACKUP_DIR" ]]; then
  printf -- '- 备份目录: "%s"\n' "$BACKUP_DIR"
fi

echo
if [[ -n "$AUTO_YES" || -n "$API_KEY" ]]; then
  exit 0
fi

read -r -p '按回车键退出...' _

    