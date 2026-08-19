#!/usr/bin/env bash
#
# setup-certs.sh — scaffold everything the `passkit` signer needs, minus the
# three steps only a human with an Apple Developer account can do.
#
# Two phases, because the middle bit happens in a browser:
#
#   ./scripts/setup-certs.sh generate
#       → makes certs/pass.key + certs/pass.certSigningRequest with openssl
#         (no Keychain, no .p12 round-trip).
#
#   ... upload the CSR in the Apple portal, download the cert as
#       certs/pass.cer ...
#
#   ./scripts/setup-certs.sh finalize
#       → converts the cert to signerCert.pem, pairs it with signerKey.pem,
#         fetches + converts the WWDR cert, scaffolds backend/templates/*,
#         and seeds backend/.env with SIGNER=passkit.
#
# Everything it writes under certs/ is already gitignored.

set -euo pipefail

# --- locate the backend dir regardless of where we're invoked from ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CERTS_DIR="$BACKEND_DIR/certs"
TEMPLATES_DIR="$BACKEND_DIR/templates"
ENV_FILE="$BACKEND_DIR/.env"
ENV_EXAMPLE="$BACKEND_DIR/.env.example"

# Worldwide Developer Relations intermediate that signs pass certs issued today.
WWDR_URL="https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer"

# Pass types the app emits (storeCard/eventTicket/generic) plus the two other
# values the /pass route accepts, so a hand-set `type` also has a template.
PASS_TYPES="storeCard generic coupon eventTicket boardingPass"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$*"; }
die()   { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }

# ---------------------------------------------------------------------------
# generate: private key + CSR
# ---------------------------------------------------------------------------
cmd_generate() {
  need openssl
  mkdir -p "$CERTS_DIR"

  local key="$CERTS_DIR/pass.key"
  local csr="$CERTS_DIR/pass.certSigningRequest"

  if [[ -f "$key" && "${FORCE:-0}" != "1" ]]; then
    die "$key already exists. Re-run with FORCE=1 to overwrite (invalidates any cert issued from the old key)."
  fi

  local email
  email="$(git -C "$BACKEND_DIR" config user.email 2>/dev/null || true)"
  email="${email:-you@example.com}"

  bold "Generating private key + certificate signing request"
  openssl genrsa -out "$key" 2048 2>/dev/null
  chmod 600 "$key"
  openssl req -new -key "$key" -out "$csr" \
    -subj "/emailAddress=$email/CN=Pass Type ID/C=US"
  ok "wrote $(rel "$key")  (keep this — the cert is worthless without it)"
  ok "wrote $(rel "$csr")"

  echo
  bold "Next — do these in the Apple Developer portal, then run 'finalize':"
  info "1. Identifiers → + → Pass Type IDs → create e.g. pass.com.matthewcuan.wallet"
  info "2. Open it → Create Certificate → upload $(rel "$csr")"
  info "3. Download the resulting cert and save it as $(rel "$CERTS_DIR/pass.cer")"
  info "   (CSR subject email used: $email)"
}

# ---------------------------------------------------------------------------
# finalize: cert → PEMs, WWDR, templates, .env
# ---------------------------------------------------------------------------
cmd_finalize() {
  need openssl
  local key="$CERTS_DIR/pass.key"
  local cer="$CERTS_DIR/pass.cer"
  local signer_cert="$CERTS_DIR/signerCert.pem"
  local signer_key="$CERTS_DIR/signerKey.pem"
  local wwdr="$CERTS_DIR/wwdr.pem"

  [[ -f "$key" ]] || die "no $(rel "$key") — run 'generate' first."
  [[ -f "$cer" ]] || die "no $(rel "$cer") — download the issued cert from Apple to that path first."

  bold "Converting the issued certificate"
  # Apple hands back DER; passkit-generator wants PEM. Handle either input.
  if ! openssl x509 -inform DER -in "$cer" -out "$signer_cert" 2>/dev/null; then
    openssl x509 -inform PEM -in "$cer" -out "$signer_cert" 2>/dev/null \
      || die "could not read $(rel "$cer") as DER or PEM."
  fi
  cp "$key" "$signer_key"
  chmod 600 "$signer_key"
  ok "wrote $(rel "$signer_cert")"
  ok "wrote $(rel "$signer_key")"

  # Catch the #1 real-world failure: cert issued from a different key/CSR.
  local cmod kmod
  cmod="$(openssl x509 -noout -modulus -in "$signer_cert" 2>/dev/null | openssl md5)"
  kmod="$(openssl rsa  -noout -modulus -in "$signer_key"  2>/dev/null | openssl md5)"
  if [[ "$cmod" == "$kmod" ]]; then
    ok "certificate and key match"
  else
    warn "certificate and key DO NOT match — the cert was issued from a different CSR/key."
    warn "signing will fail. Re-run 'generate' and re-issue the cert from the new CSR."
  fi

  bold "Fetching Apple's WWDR intermediate certificate"
  if command -v curl >/dev/null 2>&1 && curl -fsSL "$WWDR_URL" -o "$CERTS_DIR/wwdr.cer" 2>/dev/null; then
    if openssl x509 -inform DER -in "$CERTS_DIR/wwdr.cer" -out "$wwdr" 2>/dev/null; then
      ok "wrote $(rel "$wwdr")"
    else
      cp "$CERTS_DIR/wwdr.cer" "$wwdr"
      warn "WWDR cert wasn't DER; copied as-is to $(rel "$wwdr") — verify it's PEM."
    fi
  else
    warn "couldn't download WWDR cert. Get it from https://www.apple.com/certificateauthority/"
    warn "  and convert: openssl x509 -inform DER -in AppleWWDRCAG4.cer -out $(rel "$wwdr")"
  fi

  cmd_templates
  seed_env

  echo
  bold "Almost there — finish these by hand in $(rel "$ENV_FILE"):"
  info "• PASS_TYPE_IDENTIFIER  — the pass.* id you created (must match exactly)"
  info "• TEAM_IDENTIFIER       — 10-char Team ID from Account → Membership"
  info "Then: npm run dev  → the iOS 'Add to Wallet' flow signs with your cert."
  info "Also drop your PASS_TYPE_IDENTIFIER into entitledPassTypeIdentifiers in the iOS app."
}

# ---------------------------------------------------------------------------
# templates: one dir per pass type with a minimal pass.json + placeholder art
# ---------------------------------------------------------------------------
cmd_templates() {
  bold "Scaffolding pass templates"
  local made=0 art_ok=1
  for type in $PASS_TYPES; do
    local dir="$TEMPLATES_DIR/$type"
    if [[ -d "$dir" && "${FORCE:-0}" != "1" ]]; then
      info "$type — exists, leaving it (FORCE=1 to overwrite)"
      continue
    fi
    mkdir -p "$dir"
    write_pass_json "$type" "$dir/pass.json"

    # icon (required) + logo, at 1x/2x/3x. Dimensions per Apple's guidelines.
    while read -r name w h; do
      [[ -z "$name" ]] && continue
      make_png "$dir/$name" "$w" "$h" || art_ok=0
    done <<'EOF'
icon.png 29 29
icon@2x.png 58 58
icon@3x.png 87 87
logo.png 160 50
logo@2x.png 320 100
logo@3x.png 480 150
EOF
    ok "$type"
    made=$((made + 1))
  done

  if [[ "$art_ok" != "1" ]]; then
    warn "couldn't generate placeholder art (need ImageMagick or macOS 'sips')."
    warn "each template dir still needs: icon.png/@2x/@3x (29/58/87px square),"
    warn "  logo.png/@2x/@3x (160x50 / 320x100 / 480x150)."
  elif [[ "$made" -gt 0 ]]; then
    info "placeholder icon/logo art written — replace with real branding before shipping."
  fi
}

# minimal, valid pass.json. Runtime fields (identifiers, colors, barcode,
# serialNumber, logoText, description, organizationName) are injected by the
# signer, so the template only carries formatVersion + the style dictionary.
write_pass_json() {
  local type="$1" out="$2"
  cat > "$out" <<EOF
{
  "formatVersion": 1,
  "$type": {
    "primaryFields": [],
    "secondaryFields": [],
    "auxiliaryFields": [],
    "backFields": []
  }
}
EOF
}

# make_png OUT W H — coral placeholder via ImageMagick, else a resized seed via
# sips (present on every Mac), else fail so the caller can warn.
make_png() {
  local out="$1" w="$2" h="$3"
  if command -v magick >/dev/null 2>&1; then
    magick -size "${w}x${h}" "xc:#C24A2C" "$out" 2>/dev/null && return 0
  fi
  if command -v convert >/dev/null 2>&1; then
    convert -size "${w}x${h}" "xc:#C24A2C" "$out" 2>/dev/null && return 0
  fi
  if command -v sips >/dev/null 2>&1; then
    local seed="$CERTS_DIR/.seed.png"
    [[ -f "$seed" ]] || write_seed_png "$seed" || return 1
    sips -z "$h" "$w" "$seed" --out "$out" >/dev/null 2>&1 && return 0
  fi
  return 1
}

# a 1x1 PNG to seed sips upscaling; guarded so a bad decode just degrades to
# the manual-art warning rather than aborting the run.
write_seed_png() {
  local out="$1"
  local b64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
  if command -v base64 >/dev/null 2>&1; then
    printf '%s' "$b64" | base64 --decode > "$out" 2>/dev/null && return 0
    printf '%s' "$b64" | base64 -d      > "$out" 2>/dev/null && return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# .env seeding — safe: never clobbers an existing .env
# ---------------------------------------------------------------------------
seed_env() {
  if [[ -f "$ENV_FILE" ]]; then
    info "$(rel "$ENV_FILE") exists — not touching it. Ensure SIGNER=passkit and the identifiers are set."
    return 0
  fi
  [[ -f "$ENV_EXAMPLE" ]] || { warn "no .env.example to copy from."; return 0; }
  # copy the example, then flip SIGNER=mock → passkit portably (temp + mv).
  local tmp="$ENV_FILE.tmp"
  sed 's/^SIGNER=.*/SIGNER=passkit/' "$ENV_EXAMPLE" > "$tmp" && mv "$tmp" "$ENV_FILE"
  ok "wrote $(rel "$ENV_FILE") from .env.example (SIGNER=passkit; cert paths already point at ./certs)"
}

# path relative to the repo/backend for tidy output
rel() { printf '%s' "${1#"$BACKEND_DIR"/}"; }

usage() {
  cat <<EOF
setup-certs.sh — provision the passkit signer

usage: ./scripts/setup-certs.sh <command>

  generate    make certs/pass.key + certs/pass.certSigningRequest (phase 1)
  finalize    convert the issued cert, fetch WWDR, scaffold templates + .env (phase 2)
  templates   (re)scaffold backend/templates/* only

env: FORCE=1  overwrite an existing key or existing template dirs

Between 'generate' and 'finalize' you upload the CSR to the Apple Developer
portal and save the issued certificate to certs/pass.cer.
EOF
}

case "${1:-}" in
  generate)  cmd_generate ;;
  finalize)  cmd_finalize ;;
  templates) cmd_templates ;;
  ""|-h|--help|help) usage ;;
  *) die "unknown command '$1' (try: generate | finalize | templates)" ;;
esac
