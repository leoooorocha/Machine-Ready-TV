#!/usr/bin/env bash

set -Euo pipefail

DECKY_INSTALLER_URL="https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh"

REPO_URL="https://github.com/leoooorocha/Machine-Ready-TV.git"
ZIP_URL="https://github.com/leoooorocha/Machine-Ready-TV/archive/refs/heads/main.zip"
REPO_BRANCH="main"

WORKDIR="/tmp/machine-ready"
REPODIR="${WORKDIR}/Machine-Ready-TV"
ZIPFILE="${WORKDIR}/Machine-Ready-TV.zip"
ZIPDIR="${WORKDIR}/Machine-Ready-TV-main"

HOMEBREW_DIR="${HOME}/homebrew"
THEMES_DIR="${HOMEBREW_DIR}/themes"

SOURCE=""
REPO_ACTION=""
REPO_COMMIT=""

NEW_INSTALLED_COUNT=0
UPDATED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "🔹 ${BLUE}$1${NC}"; }
success() { echo -e "   ${GREEN}✔${NC} $1"; }
warn()    { echo -e "   ${YELLOW}⚠️  $1${NC}"; }
fail()    { echo -e "   ${RED}✖  $1${NC}"; }

cleanup() {
    rm -f "$ZIPFILE" 2>/dev/null || true
}

trap cleanup EXIT

check_internet() {
    echo
    info "Checking internet connection..."

    if ping -c1 github.com >/dev/null 2>&1; then
        success "Internet connection OK."
        return 0
    fi

    warn "No internet connection detected."
    warn "Will continue with any locally cached repository."
    return 1
}

install_decky() {
    if [[ -d "$HOMEBREW_DIR" ]]; then
        success "Decky Loader already installed."
        return 0
    fi

    echo
    info "Decky Loader not detected."

    if ! ping -c1 github.com >/dev/null 2>&1; then
        warn "Cannot install Decky without internet."
        warn "Themes will be staged; install Decky manually if needed."
        return 1
    fi

    local TMP_INSTALLER="/tmp/install_decky.sh"
    echo
    info "Downloading official Decky installer..."

    if ! curl -fsSL "$DECKY_INSTALLER_URL" -o "$TMP_INSTALLER"; then
        warn "Could not download Decky installer."
        return 1
    fi

    chmod +x "$TMP_INSTALLER"
    echo
    info "Running Decky installer..."

    if ! bash "$TMP_INSTALLER"; then
        rm -f "$TMP_INSTALLER"
        warn "Decky installation failed."
        return 1
    fi

    rm -f "$TMP_INSTALLER"

    if [[ ! -d "$HOMEBREW_DIR" ]]; then
        warn "Decky installation did not create ${HOMEBREW_DIR}."
        return 1
    fi

    success "Decky Loader installed."
    return 0
}

ensure_themes_dir() {
    if [[ -d "$THEMES_DIR" ]]; then
        return 0
    fi

    if [[ ! -d "$HOMEBREW_DIR" ]]; then
        warn "CSS Loader themes directory not found (${THEMES_DIR})."
        warn "Install Decky Loader and the CSS Loader plugin, then rerun."
        mkdir -p "$THEMES_DIR" 2>/dev/null || true
        return 1
    fi

    if ! mkdir -p "$THEMES_DIR" 2>/dev/null; then
        fail "Could not create themes directory: ${THEMES_DIR}"
        return 1
    fi

    success "Created themes directory: ${THEMES_DIR}"
    return 0
}

report_repo_commit() {
    local DIR="$1"

    if [[ -d "$DIR/.git" ]] && command -v git >/dev/null 2>&1; then
        REPO_COMMIT="$(git -C "$DIR" log -1 --format='%h (%ci) %s' 2>/dev/null || true)"
    fi

    if [[ -z "$REPO_COMMIT" && -f "$DIR/README.md" ]]; then
        REPO_COMMIT="ZIP archive (no git metadata)"
    fi

    if [[ -n "$REPO_COMMIT" ]]; then
        echo
        info "Repository version: ${REPO_COMMIT}"
    fi
}

download_repo() {
    mkdir -p "$WORKDIR"
    SOURCE=""
    REPO_ACTION=""

    if command -v git >/dev/null 2>&1; then
        if [[ -d "$REPODIR/.git" ]]; then
            echo
            info "Updating Machine Ready repository..."
            local LOCAL_HASH REMOTE_HASH PULL_OK=0

            git -C "$REPODIR" remote set-url origin "$REPO_URL" 2>/dev/null || true

            if git -C "$REPODIR" fetch origin "$REPO_BRANCH" 2>/dev/null; then
                LOCAL_HASH="$(git -C "$REPODIR" rev-parse HEAD 2>/dev/null || echo "")"
                REMOTE_HASH="$(git -C "$REPODIR" rev-parse "origin/${REPO_BRANCH}" 2>/dev/null || echo "")"

                if [[ -n "$LOCAL_HASH" && -n "$REMOTE_HASH" && "$LOCAL_HASH" == "$REMOTE_HASH" ]]; then
                    REPO_ACTION="already_current"
                    success "Repository already current."
                    SOURCE="$REPODIR"
                elif git -C "$REPODIR" pull --ff-only origin "$REPO_BRANCH" 2>/dev/null; then
                    REPO_ACTION="updated"
                    success "Repository updated."
                    SOURCE="$REPODIR"
                else
                    warn "Could not fast-forward repository; using local copy."
                    REPO_ACTION="failed"
                    SOURCE="$REPODIR"
                fi
            else
                warn "Could not fetch repository updates; using local copy."
                REPO_ACTION="failed"
                SOURCE="$REPODIR"
            fi
        else
            echo
            info "Cloning Machine Ready repository..."
            rm -rf "$REPODIR" 2>/dev/null || true

            if git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" "$REPODIR" 2>/dev/null; then
                REPO_ACTION="cloned"
                success "Repository cloned."
                SOURCE="$REPODIR"
            else
                warn "Git clone failed."
            fi
        fi
    else
        warn "Git not available."
    fi

    if [[ -z "$SOURCE" ]]; then
        if ! ping -c1 github.com >/dev/null 2>&1; then
            fail "Cannot download repository without internet."
            return 1
        fi

        warn "Falling back to ZIP download."
        echo
        info "Downloading ZIP archive..."

        if ! curl -fsSL "$ZIP_URL" -o "$ZIPFILE"; then
            fail "Could not download repository archive."
            return 1
        fi

        if ! unzip -oq "$ZIPFILE" -d "$WORKDIR"; then
            fail "Could not extract repository archive."
            return 1
        fi

        if [[ ! -d "$ZIPDIR" ]]; then
            fail "Extracted archive layout not recognised."
            return 1
        fi

        REPO_ACTION="downloaded"
        success "Repository downloaded."
        SOURCE="$ZIPDIR"
    fi

    report_repo_commit "$SOURCE"
    return 0
}

find_named_subdir() {
    local BASE="$1"
    shift
    local NAME DIR

    for NAME in "$@"; do
        DIR="${BASE}/${NAME}"
        if [[ -d "$DIR" ]]; then
            echo "$DIR"
            return 0
        fi
    done

    return 1
}

should_skip_repo_dir() {
    local NAME="$1"

    case "$NAME" in
        .git|.github|docs|images|screenshots|Profiles|profiles|Themes|themes|scripts|Scripts|[Rr][Ee][Aa][Dd][Mm][Ee]*)
            return 0
            ;;
    esac

    return 1
}

install_item() {
    local SRC="$1"
    local LABEL="${2:-$(basename "$SRC")}"
    local DEST="${THEMES_DIR}/$(basename "$SRC")"

    local LOWER_LABEL
    LOWER_LABEL="$(echo "$LABEL" | tr '[:upper:]' '[:lower:]')"
    if [[ "$LOWER_LABEL" == "scripts" || "$LOWER_LABEL" == readme* ]]; then
        return 0
    fi

    if [[ ! -d "$SRC" ]]; then
        warn "Skipped ${LABEL} (source missing)."
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        return 1
    fi

    if [[ ! -d "$THEMES_DIR" ]]; then
        fail "Skipped ${LABEL} (themes directory unavailable)."
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi

    local IS_NEW=0
    if [[ ! -d "$DEST" ]]; then
        IS_NEW=1
    fi

    mkdir -p "$DEST"

    local SUCCESS_FLAG=0
    local CHANGES=""

    if command -v rsync >/dev/null 2>&1; then
        CHANGES=$(rsync -a --delete -i \
            --exclude='[sS]cripts' \
            --exclude='[rR][eE][aA][dD][mM][eE]*' \
            --exclude='.git*' \
            "$SRC/" "$DEST/" 2>/dev/null)
        SUCCESS_FLAG=1
    else
        rm -rf "$DEST"
        if cp -a "$SRC" "$DEST" 2>/dev/null; then
            rm -rf "$DEST/scripts" "$DEST/Scripts" 2>/dev/null || true
            find "$DEST" -iname "readme*" -delete 2>/dev/null || true
            SUCCESS_FLAG=1
            CHANGES="forced"
        fi
    fi

    if [[ $SUCCESS_FLAG -eq 1 ]]; then
        if [[ $IS_NEW -eq 1 ]]; then
            echo -e "   ${GREEN}[INSTALLED]${NC} ${LABEL}"
            NEW_INSTALLED_COUNT=$((NEW_INSTALLED_COUNT + 1))
        elif [[ -n "$CHANGES" ]]; then
            echo -e "   ${CYAN}[UPDATED]${NC}   ${LABEL}"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
        else
            echo -e "   ${YELLOW}[SKIPPED]${NC}   ${LABEL}"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        fi
        return 0
    fi

    echo -e "   ${RED}[FAILED]${NC}    ${LABEL}"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    return 1
}

install_from_directory() {
    local ROOT="$1"
    local KIND="$2"

    [[ -d "$ROOT" ]] || return 0

    local DIRS=()
    local DIR NAME

    while IFS= read -r -d '' DIR; do
        DIRS+=("$DIR")
    done < <(
        find "$ROOT" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -print0 2>/dev/null | sort -z
    )

    if [[ ${#DIRS[@]} -eq 0 ]]; then
        echo
        warn "No ${KIND} found in $(basename "$ROOT")."
        return 0
    fi

    local ICON="📦"
    if [[ "$KIND" == "themes" ]]; then
        ICON="🎨"
    fi

    echo
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "${CYAN}${ICON} Processing ${KIND} (${#DIRS[@]} items)${NC}"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo

    for DIR in "${DIRS[@]}"; do
        NAME="$(basename "$DIR")"
        install_item "$DIR" "$NAME" || true
    done
}

install_machine_ready() {
    if [[ -z "$SOURCE" || ! -d "$SOURCE" ]]; then
        fail "No repository source available to install from."
        return 1
    fi

    NEW_INSTALLED_COUNT=0
    UPDATED_COUNT=0
    FAILED_COUNT=0
    SKIPPED_COUNT=0

    local PROFILES_ROOT THEMES_ROOT
    PROFILES_ROOT="$(find_named_subdir "$SOURCE" Profiles profiles || true)"
    THEMES_ROOT="$(find_named_subdir "$SOURCE" Themes themes || true)"

    if [[ -n "$PROFILES_ROOT" ]]; then
        install_from_directory "$PROFILES_ROOT" "profiles"
    fi

    if [[ -n "$THEMES_ROOT" ]]; then
        install_from_directory "$THEMES_ROOT" "themes"
    fi

    if [[ -z "$THEMES_ROOT" ]]; then
        local ROOT_DIRS=()
        local DIR NAME

        while IFS= read -r -d '' DIR; do
            NAME="$(basename "$DIR")"
            should_skip_repo_dir "$NAME" && continue
            ROOT_DIRS+=("$DIR")
        done < <(
            find "$SOURCE" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -print0 2>/dev/null | sort -z
        )

        if [[ ${#ROOT_DIRS[@]} -gt 0 ]]; then
            echo
            echo -e "${BLUE}--------------------------------------------------${NC}"
            echo -e "${CYAN}🎨 Processing themes (${#ROOT_DIRS[@]} items)${NC}"
            echo -e "${BLUE}--------------------------------------------------${NC}"
            echo
            for DIR in "${ROOT_DIRS[@]}"; do
                install_item "$DIR" "$(basename "$DIR")" || true
            done
        fi
    fi

    echo

    local TOTAL_PROCESSED=$((NEW_INSTALLED_COUNT + UPDATED_COUNT + SKIPPED_COUNT))

    if [[ $TOTAL_PROCESSED -eq 0 && $FAILED_COUNT -eq 0 ]]; then
        warn "No installable themes or profiles were discovered."
        warn "The repository layout may have changed."
        return 1
    fi

    if [[ $FAILED_COUNT -eq 0 ]]; then
        success "Done. Processed ${TOTAL_PROCESSED} item(s)."
    else
        warn "Done with errors. Installed: ${NEW_INSTALLED_COUNT}, Updated: ${UPDATED_COUNT}, Failed: ${FAILED_COUNT}, Skipped: ${SKIPPED_COUNT}."
    fi

    return 0
}

print_companion_notes() {
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "${CYAN}⚙️  Post-Installation & Dependencies${NC}"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo
    echo -e "💡 ${YELLOW}Highly recommended to use SteamGridDB for square capsules and matching recent capsules.${NC}"
    echo
    echo "Whether you installed automatically or manually, you need to configure CSS Loader:"
    echo
    echo -e "${YELLOW}1. Open the CSS Loader Theme Store and install the following dependencies:${NC}"
    echo "   • Animated PSP Waves Background (only for PSP OLED profile)"
    echo "   • Avatar Customization Suite"
    echo "   • Better Blur"
    echo "   • Centered Game Text"
    echo "   • Clean Library Capsule"
    echo "   • Focus Highlight Color"
    echo "   • Game Cover Shine Animation Color"
    echo "   • Main Menu Hide Tabs (Hide the Store)"
    echo "   • No Friend Playing Icon"
    echo "   • No Hero Gradient"
    echo "   • No Home Tabs"
    echo "   • Proper Hero Scaling (only for Back 2 Basic profile)"
    echo "   • QAM Hide Tabs"
    echo "   • Top Bar Padding"
    echo "   • Volume Tweaker"
    echo
    echo -e "${YELLOW}2. Click the Settings ⚙️ button on the top-right of CSS Loader.${NC}"
    echo
    echo -e "${YELLOW}3. Navigate to Settings ➜ Enable Nav Patch, and toggle it On.${NC}"
    echo -e "   💡 ${CYAN}Some themes require Nav Patch to force Steam to ignore hidden elements.${NC}"
    echo
    echo -e "${YELLOW}4. Go back to QAM CSS Loader, scroll down to the very bottom and click Refresh.${NC}"
    echo
    echo -e "${YELLOW}5. Select and apply your preferred Machine Ready profile.${NC}"
    echo
}

finish() {
    echo
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${CYAN}📊 Installation Summary${NC}"
    echo -e "${BLUE}==================================================${NC}"
    echo

    case "$REPO_ACTION" in
        cloned)          echo "Repository: cloned" ;;
        updated)         echo "Repository: updated" ;;
        already_current) echo "Repository: already current" ;;
        downloaded)      echo "Repository: downloaded (ZIP)" ;;
        failed)          echo "Repository: update failed (used local copy)" ;;
        *)               echo "Repository: unknown status" ;;
    esac

    if [[ -n "$REPO_COMMIT" ]]; then
        echo "Version: ${REPO_COMMIT}"
    fi

    echo
    echo "Themes directory:"
    echo "    ${THEMES_DIR}"
    echo
    echo "Status breakdown:"
    echo -e "  - ${GREEN}Installed:${NC}   ${NEW_INSTALLED_COUNT}"
    echo -e "  - ${CYAN}Updated:  ${NC}   ${UPDATED_COUNT}"
    echo -e "  - ${YELLOW}Skipped:  ${NC}   ${SKIPPED_COUNT}"
    echo -e "  - ${RED}Failed:   ${NC}   ${FAILED_COUNT}"
    echo

    print_companion_notes
}

main() {
    echo
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${CYAN}🎮 Machine Ready Theme Installer${NC}"
    echo -e "${BLUE}==================================================${NC}"

    check_internet || true
    install_decky || true

    if ! ensure_themes_dir; then
        warn "Continuing; theme installation may fail until CSS Loader is available."
    fi

    if ! download_repo; then
        fail "Could not obtain Machine Ready repository."
        finish
        return 1
    fi

    install_machine_ready || true
    finish
}

main "$@"
