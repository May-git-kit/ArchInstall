#!/bin/bash 
# ======================================================================================
# MASTER ARCH LINUX SETUP: ZEN 4 (V4) 
# TARGET CPU: AMD Ryzen 7 8845HS (AVX-512 Supported) 
# STRATEGY: Enable CachyOS V4 Repos -> Install Kernel -> Install Paru -> Install Apps 
# ======================================================================================

# ⚠️ CONFIGURATION: CHANGE THIS TO YOUR USERNAME ⚠️ 
USERNAME="mayank" 

echo "💿 Installing Software Stack (V4 Optimized)..."
 
# switch to user for paru commands (safer)
su - $USERNAME <<EOF
    
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
