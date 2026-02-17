#!/bin/bash 
# ======================================================================================
# MASTER ARCH LINUX SETUP: ZEN 4 (V4) 
# TARGET CPU: AMD Ryzen 7 8845HS (AVX-512 Supported) 
# STRATEGY: Enable CachyOS V4 Repos -> Install Kernel -> Install Paru -> Install Apps 
# ======================================================================================

# ⚠️ CONFIGURATION: CHANGE THIS TO YOUR USERNAME ⚠️ 
USERNAME="mayank" 

echo "🚀 Starting High-Performance Setup for User: $USERNAME" 

# ========================================== 
# 1. OPTIMIZE REPOSITORIES (V4 / AVX-512) 
# ========================================== 
echo "🔧 Configuring CachyOS V4 Repositories..." 

# 1.1 Install Keys & Mirrorlists 
# We download the specific 'v4-mirrorlist' required for Zen 4 CPUs. 
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com 
pacman-key --lsign-key F3B607488DB35A47 
pacman -U 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' --noconfirm 
pacman -U 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-22-1-any.pkg.tar.zst' --noconfirm 
pacman -U 'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v4-mirrorlist-22-1-any.pkg.tar.zst' --noconfirm 

# 1.2 Overwrite pacman.conf with V4 Hierarchy 
echo "🔧 Configuring Pacman Repositories..." 
sudo tee /etc/pacman.conf <<EOF
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#XferCommand = /usr/bin/aria2c --allow-overwrite=true --continue=true --file-allocation=none --log-level=error --max-connection-per-server=5 --min-split-size=1M --no-conf --remote-time=true --summary-interval=60 --timeout=5 -d / -o %o %u
#CleanMethod = KeepInstalled
#UseDelta    = 0.7 
Architecture = x86_64 x86_64_v3 x86_64_v4

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# UI & Net 
Color 
CheckSpace 
VerbosePkgLists 
ParallelDownloads = 10
ILoveCandy
#UseSyslog
#NoProgressBar
DisableDownloadTimeout
DownloadUser = alpm
#DisableSandbox

# Security 
# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

# NOTE: You must run \`pacman-key --init\` before first using pacman; the local
# keyring can then be populated with the keys of all official Arch Linux
# packagers with \`pacman-key --populate archlinux\`.

# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have \$repo replaced by the name of the current repo
#   - URLs will have \$arch replaced by the name of the architecture
#
# Repository entries are of the format:
#        [repo-name]
#        Server = ServerName
#        Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# cachyos repos

[cachyos-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist

[cachyos-core-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist

[cachyos-extra-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[core-testing]
#Include = /etc/pacman.d/mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

#[extra-testing]
#Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs
EOF

# 1.3 Sync DB 
echo "🔄 Syncing V4 Databases..."
pacman -S --noconfirm reflector cachyos-rate-mirrors
sudo reflector --verbose --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sudo cachyos-rate-mirrors
pacman -Syyu

# ========================================== 
# 2. INSTALL KERNEL & BASE 
# ========================================== 
echo "🐧 Installing Optimized Kernel..." 
# 'linux-cachyos' includes EEVDF scheduler tweaks for Ryzen
pacman -S --noconfirm limine-mkinitcpio-hook limine-entry-tool limine-snapper-sync
pacman -S --noconfirm linux-cachyos linux-cachyos-headers
pacman -S --noconfirm scx-tools scx-scheds scx-manager
sudo limine-mkinitcpio
# Ensure base-devel is present 
pacman -S --noconfirm git base-devel sudo nano amd-ucode

# ========================================== 
# 3. INSTALL PARU (AUR HELPER) 
# ========================================== 
echo "📦 Building Paru..." 
# Build Paru as user (can't run makepkg as root) 
if ! command -v paru &> /dev/null; then 
    # Use -m to ensure the user's environment is fully loaded
    su - $USERNAME <<EOF
    cd ~
    rm -rf paru-git
    git clone https://aur.archlinux.org/paru-git.git 
    cd paru-git
    # -s installs dependencies, -i installs the package, --noconfirm skips prompts
    makepkg -si --noconfirm     
    # Cleanup build files
    cd .. 
    rm -rf paru-git
EOF
fi

# ========================================== 
# 4. INSTALL SOFTWARE STACK 
# ========================================== 
echo "💿 Installing Software Stack (V4 Optimized)..."
 
# switch to user for paru commands (safer)
su - $USERNAME <<EOF
    
    echo "💿 Installing Graphics Stack..."
    # Mesa & Vulkan Graphics Stack
    paru -S --noconfirm mesa-git vulkan-radeon libva-mesa-driver mesa-vdpau vulkan-icd-loader
    #paru -S --noconfirm ollama-vulkan lib32-mesa-git lib32-vulkan-radeon lib32-libva-mesa-driver lib32-mesa-vdpau
    
    echo "💿 Installing ffmpeg Stack..."
    # ffmpeg Stack
    paru -S --noconfirm ffmpeg ffmpegthumbnailer
    
    echo "💿 Installing GNOME Apps..."
    # GNOME APPS (gtk based)
    
    paru -S --noconfirm nautilus python-nautilus nautilus-open-any-terminal nautilus-admin bubblewrap
    paru -S --noconfirm gvfs gvfs-mtp gvfs-goa gvfs-google gvfs-onedrive gnome-sushi udiskie
    paru -S --noconfirm gnome-disk-utility gnome-firmware gnome-calculator
    paru -S --noconfirm keypunch resources tangram baobab loupe cine papers snapshot
    
    # KDE APPS (qt based)
	
	echo "💿 Installing Apps..."
	# APPS
	paru -S --noconfirm zen-browser-bin localsend-bin
	paru -S --noconfirm ventoy jamesdsp
	paru -S --noconfirm cameractrls obsidian planify file-roller
	paru -S --noconfirm zathura zathura-pdf-mupdf mupdf-tools 
	paru -S --noconfirm walker-bin elephant czkawka-gui clipse
	#paru -S --noconfirm satty deskreen-bin trash-cli peazip sioyek
	
	echo "💿 Installing System Utilities Apps..."
	# System Utilites APPS
	paru -S --noconfirm networkmanager iwd iwgtk firewalld bluez bluez-utils blueman nmgui-bin
	paru -S --noconfirm brightnessctl power-profiles-daemon fwupd
	paru -S --noconfirm zram-generator btrfs-progs e2fsprogs snapper
	paru -S --noconfirm pamac-aur mission-center qdiskinfo
	paru -S --noconfirm amdgpu_top uv electron
	paru -S --noconfirm btrfs-assistant overskride-bin
	#paru -S --noconfirm virt-manager bauh cups cups-pdf howdy
	
	echo "💿 Installing Cachyos Apps..."
	# Cachyos APPS
	paru -S --noconfirm cachyos-settings cachyos-hooks ananicy-cpp-git cachyos-ananicy-rules-git
	paru -S --noconfirm cachyos-kernel-manager cachyos-sysctl-manager cachyos-dnscrypt-proxy cachyos-snapper-support
	#paru -S --noconfirm wine-cachyos proton-cachyos
    
	echo "💿 Installing Shell and Terminal Stack..."
	# --- SHELL & TERMINAL --- 
	paru -S --noconfirm fish ghostty micro neovim  
	paru -S --noconfirm lazygit yazi atuin stow zellij unrar unzip wget curl man-db
	paru -S --noconfirm fastfetch btop bat battop eza zoxide ripgrep fd sd procs dust tldr
	paru -S --noconfirm gcc cmake pacman-contrib 
	#paru -S --noconfirm rsync yt-dlp starship neovide
	
	echo "💿 Installing Audio Stack..."
	# --- AUDIO --- 
	paru -S --noconfirm pipewire pipewire-alsa pipewire-pulse wireplumber wpctl pwvucontrol helvum mpv-mpris playerctl
	#paru -S --noconfirm gstreamer gst-plugins-base gst-plugin-pipewire gst-plugins-rs gst-libav gst-plugin-gtk4 gst-plugins-bad gst-plugins-ugly
	#paru -S --noconfirm mpv mpv-uosc-git mpv-thumbfast-git mpv-mpris webp-pixbuf-loader lsp-plugins pavucontrol qpwgraph
	#https://github.com/zydezu/ModernX
	
	echo "💿 Installing Themes and Fonts..."
	# --- THEMES & FONTS --- 
	paru -S --noconfirm ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts-emoji ttf-material-symbols-variable-git 
	paru -S --noconfirm ttf-cascadia-code-nerd ttf-meslo-nerd noto-fonts inter-font
	paru -S --noconfirm catppuccin-gtk-theme-mocha papirus-icon-theme bibata-cursor-theme-bin 
	paru -S --noconfirm kvantum qt5-wayland qt6-wayland qt5ct qt6ct adw-gtk3
	
	echo "💿 Installing Hypr Ecosystem..."
	# --- HYPR TOOLS---
	paru -S --noconfirm uwsm libnewt aquamarine hyprland hyprpaper hyprpolkitagent hypridle hyprlock hyprsunset hyprshot hyprpicker hyprcursor  
	paru -S --noconfirm xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xwayland hyprland-qt-support hyprqt6engine hyprshutdown hyprpwcenter hyprgraphics 
	paru -S --noconfirm nwg-look swaync wlogout-git snappy-switcher hyprkcs-git sddm swayosd
	paru -S --noconfirm ironbar wayland-pipewire-idle-inhibit-git
	
EOF

============================================
# 5. Set Shell to Fish
============================================
echo "Making Fish default shell..."
chsh -s /usr/bin/fish $USERNAME

# ==========================================
# 6. ENABLE SYSTEM SERVICES
# ==========================================
echo "🔌 Enabling System Services..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now power-profiles-daemon
sudo systemctl enable --now firewalld
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now snapper-timeline.timer # Btrfs Snapshots
sudo systemctl enable --now snapper-cleanup.timer
sudo systemctl enable --now paccache.timer # Clean cache
sudo systemctl enable --now systemd-timesyncd
sudo systemctl enable --now fwupd
sudo systemctl enable --now reflector.timer
sudo systemctl enable --now dnscrypt-proxy
sudo systemctl enable --now ananicy-cpp
sudo systemctl enable --now cachyos-ksm
sudo systemctl enable --now scx.service
sudo systemctl enable --now cachyos-rate-mirrors.timer
sudo systemctl enable --now swayosd-libinput-backend.service
#sudo systemctl enable --now sddm
#sudo systemctl enable --now libvirtd
#sudo systemctl enable --now cups
sudo systemctl daemon-reload
systemctl --user enable --now pipewire 
systemctl --user enable --now pipewire-pulse 
systemctl --user enable --now wireplumber

echo "✅ Master Setup Complete! Type 'exit' and reboot."
