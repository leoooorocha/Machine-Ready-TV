#!/usr/bin/env bash

set -Euo pipefail

REPO_URL="https://github.com/leoooorocha/Machine-Ready-TV.git"
ZIP_URL="https://github.com/leoooorocha/Machine-Ready-TV/archive/refs/heads/main.zip"
REPO_BRANCH="main"

WORKDIR="/tmp/machine-ready-installer"
REPODIR="${WORKDIR}/Machine-Ready-TV"
ZIPFILE="${WORKDIR}/Machine-Ready-TV.zip"
ZIPDIR="${WORKDIR}/Machine-Ready-TV-main"

HOMEBREW_DIR="${HOME}/homebrew"
PLUGINS_DIR="${HOMEBREW_DIR}/plugins"
THEMES_DIR="${HOMEBREW_DIR}/themes"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() {
    echo -e "${BLUE}🔹 $1${NC}"
}

success() {
    echo -e "   ${GREEN}✔ $1${NC}"
}

warn() {
    echo -e "   ${YELLOW}⚠️  $1${NC}"
}

fail() {
    echo -e "   ${RED}✖  $1${NC}"
}

cleanup() {
    rm -rf "$WORKDIR" 2>/dev/null || true
}

trap cleanup EXIT

check_decky_loader() {
    echo
    info "Checking Decky Loader installation..."

    if [[ -d "$HOMEBREW_DIR" ]]; then
        success "Decky Loader detected."
        return 0
    fi

    echo
    fail "Decky Loader is not installed on this system!"
    echo
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "📖 ${CYAN}${BOLD}How to install Decky Loader:${NC}"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo "1. Switch to Desktop Mode on your Steam Deck."
    echo "2. Open your browser and visit: https://decky.xyz/"
    echo "3. Download and run the official Decky Loader installer."
    echo "4. Select the recommended (Release/Stable) install option."
    echo "5. Once finished, return to Gaming Mode and rerun this script."
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo
    exit 1
}

check_css_loader() {
    echo
    info "Checking CSS Loader plugin installation..."

    if [[ -d "${PLUGINS_DIR}/SDH-CssLoader" || -d "${PLUGINS_DIR}/CSSLoader" ]]; then
        success "CSS Loader plugin detected."
        return 0
    fi

    echo
    fail "CSS Loader plugin was not found!"
    echo
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo -e "📖 ${CYAN}${BOLD}How to install CSS Loader via Decky Store:${NC}"
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo "1. Press the Quick Access Button (•••) on your Steam Deck."
    echo "2. Navigate to the Decky Loader menu (plugin icon 🔌)."
    echo "3. Click the Store icon (shopping bag 🛍️ in top-right corner)."
    echo "4. Search for 'CSS Loader' and click 'Install'."
    echo "5. After installation completes, rerun this script."
    echo -e "${BLUE}--------------------------------------------------${NC}"
    echo
    exit 1
}

ensure_themes_dir() {
    mkdir -p "$THEMES_DIR" 2>/dev/null || true
}

fetch_repository() {
    mkdir -p "$WORKDIR"
    local SOURCE_DIR=""

    if command -v git >/dev/null 2>&1; then
        if [[ -d "$REPODIR/.git" ]]; then
            info "Fetching updates from repository..."
            git -C "$REPODIR" remote set-url origin "$REPO_URL" 2>/dev/null || true
            if git -C "$REPODIR" fetch origin "$REPO_BRANCH" 2>/dev/null; then
                git -C "$REPODIR" reset --hard "origin/${REPO_BRANCH}" >/dev/null 2>&1 || true
                SOURCE_DIR="$REPODIR"
            fi
        else
            info "Cloning Machine Ready TV repository..."
            if git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" "$REPODIR" >/dev/null 2>&1; then
                SOURCE_DIR="$REPODIR"
            fi
        fi
    fi

    if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
        info "Downloading repository ZIP package..."
        if curl -fsSL "$ZIP_URL" -o "$ZIPFILE" 2>/dev/null; then
            if unzip -oq "$ZIPFILE" -d "$WORKDIR" 2>/dev/null && [[ -d "$ZIPDIR" ]]; then
                SOURCE_DIR="$ZIPDIR"
            fi
        fi
    fi

    if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
        fail "Could not retrieve repository files. Please check your internet connection."
        exit 1
    fi

    echo "$SOURCE_DIR"
}

is_reserved_repo_dir() {
    local dir_name="$1"
    case "$dir_name" in
        .git|.github|docs|images|screenshots|Profiles|profiles|Themes|themes|scripts|Scripts)
            return 0
            ;;
    esac
    return 1
}

get_theme_sources() {
    local source_root="$1"
    local themes_root=""

    if [[ -d "${source_root}/Themes" ]]; then
        themes_root="${source_root}/Themes"
    elif [[ -d "${source_root}/themes" ]]; then
        themes_root="${source_root}/themes"
    fi

    if [[ -n "$themes_root" ]]; then
        find "$themes_root" -mindepth 1 -maxdepth 1 -type d ! -name ".*" 2>/dev/null | sort
    else
        local d
        for d in "$source_root"/*; do
            if [[ -d "$d" ]]; then
                local bname
                bname="$(basename "$d")"
                if ! is_reserved_repo_dir "$bname"; then
                    echo "$d"
                fi
            fi
        done
    fi
}

theme_folders_are_equal() {
    local src_folder="$1"
    local dest_folder="$2"

    if [[ ! -d "$dest_folder" ]]; then
        return 1
    fi

    if diff -r \
        -x "config.json" \
        -x "[Rr][Ee][Aa][Dd][Mm][Ee]*" \
        -x ".git*" \
        "$src_folder" "$dest_folder" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_status_and_sync() {
    local source_dir="$1"

    local theme_sources=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && theme_sources+=("$line")
    done < <(get_theme_sources "$source_dir")

    if [[ ${#theme_sources[@]} -eq 0 ]]; then
        fail "No themes found in repository!"
        exit 1
    fi

    local installed_themes_count=0
    local missing_themes=()
    local outdated_themes=()

    for theme_src in "${theme_sources[@]}"; do
        local theme_name
        theme_name="$(basename "$theme_src")"
        local theme_dest="${THEMES_DIR}/${theme_name}"

        if [[ -d "$theme_dest" ]]; then
            installed_themes_count=$((installed_themes_count + 1))
            if ! theme_folders_are_equal "$theme_src" "$theme_dest"; then
                outdated_themes+=("$theme_src")
            fi
        else
            missing_themes+=("$theme_src")
        fi
    done

    if [[ $installed_themes_count -eq 0 ]]; then
        info "Clean installation mode detected."
        return 0
    fi

    info "Checking installed themes and files..."

    if [[ ${#missing_themes[@]} -eq 0 && ${#outdated_themes[@]} -eq 0 ]]; then
        echo
        success "Everything is already up to date! Local themes match the latest repository version."
        return 2
    elif [[ ${#missing_themes[@]} -gt 0 && ${#outdated_themes[@]} -eq 0 ]]; then
        echo
        info "You are on the latest repository update, but some themes/files are missing locally."
        info "Installing missing themes only..."
        return 0
    else
        echo
        info "Theme update detected. Updating files..."
        return 0
    fi
}

sync_folder() {
    local src="$1"
    local dest="$2"

    mkdir -p "$dest"

    if command -v rsync >/dev/null 2>&1; then
        rsync -a \
            --exclude='config.json' \
            --exclude='[rR][eE][aA][dD][mM][eE]*' \
            --exclude='[sS]cripts' \
            --exclude='.git*' \
            "$src/" "$dest/" 2>/dev/null
    else
        find "$src" -mindepth 1 -maxdepth 1 \
            ! -name "[rR][eE][aA][dD][mM][eE]*" \
            ! -name "config.json" \
            ! -name "scripts" ! -name "Scripts" \
            -exec cp -rf {} "$dest/" \; 2>/dev/null
    fi

    find "$dest" -iname "readme*" -delete 2>/dev/null || true
}

install_all_themes() {
    local source_dir="$1"

    echo
    info "Installing themes to ${THEMES_DIR}..."

    local theme_sources=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && theme_sources+=("$line")
    done < <(get_theme_sources "$source_dir")

    for theme_src in "${theme_sources[@]}"; do
        local theme_name
        theme_name="$(basename "$theme_src")"
        local theme_dest="${THEMES_DIR}/${theme_name}"

        sync_folder "$theme_src" "$theme_dest"
        success "Theme synchronized: ${theme_name}"
    done

    echo
    success "All themes installed successfully!"
}

prompt_and_install_profiles() {
    local source_dir="$1"
    local profiles_src=""

    if [[ -d "${source_dir}/Profiles" ]]; then
        profiles_src="${source_dir}/Profiles"
    elif [[ -d "${source_dir}/profiles" ]]; then
        profiles_src="${source_dir}/profiles"
    fi

    if [[ -z "$profiles_src" || ! -d "$profiles_src" ]]; then
        return 0
    fi

    echo
    echo -e "${BLUE}--------------------------------------------------${NC}"
    local reply=""
    if [[ -c /dev/tty ]]; then
        read -n 1 -rp "❓ Do you want to install pre-configured profiles? (y/N): " reply < /dev/tty
        echo
    else
        reply="n"
    fi
    echo -e "${BLUE}--------------------------------------------------${NC}"

    if [[ "$reply" =~ ^[Yy]$ ]]; then
        info "Installing pre-configured profiles..."

        for profile_dir in "$profiles_src"/*; do
            if [[ -d "$profile_dir" ]]; then
                local pname
                pname="$(basename "$profile_dir")"
                sync_folder "$profile_dir" "${THEMES_DIR}/${pname}"
                success "Profile installed: ${pname}"
            fi
        done
        success "Profiles installed successfully!"
    else
        info "Skipped profile installation."
    fi
}

main() {
    echo
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${CYAN}${BOLD}🎮 Machine Ready TV - Theme Installer${NC}"
    echo -e "${BLUE}==================================================${NC}"

    check_decky_loader
    check_css_loader
    ensure_themes_dir

    local source_dir
    source_dir="$(fetch_repository)"

    local status_code=0
    check_status_and_sync "$source_dir" || status_code=$?

    if [[ $status_code -eq 2 ]]; then
        prompt_and_install_profiles "$source_dir"
        echo
        echo -e "${GREEN}${BOLD}✨ Done! Everything is already up to date.${NC}"
        echo
        exit 0
    fi

    install_all_themes "$source_dir"
    prompt_and_install_profiles "$source_dir"

    echo
    echo -e "${GREEN}${BOLD}✨ Installation completed successfully!${NC}"
    echo -e "💡 Open the CSS Loader menu on your Steam Deck and click ${CYAN}'Refresh'${NC} to reload the list."
    echo
}

main "$@"
