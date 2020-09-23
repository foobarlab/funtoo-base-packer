#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_WINDOW_SYSTEM:-} ]; then
  echo "BUILD_WINDOW_SYSTEM was not set. Skipping ..."
  exit 0
else
  if [ "$BUILD_WINDOW_SYSTEM" = false ]; then
    echo "BUILD_WINDOW_SYSTEM set to FALSE. Skipping ..."
    exit 0
  fi
fi

# ---- console mouse support

sudo emerge -vt sys-libs/gpm
sudo rc-update add gpm default

# ---- set make.conf

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
#VIDEO_CARDS="virtualbox"
VIDEO_CARDS="vmware gallium-vmware"

DATA

# ---- set required USE flags

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
# required for funtoo profile 'X':
>=media-libs/gd-2.2.5-r2 fontconfig jpeg truetype png
>=media-libs/mesa-20.1.6 video_cards_xa

# required for 'lightdm':
>=sys-auth/consolekit-1.2.1 policykit

# required by 'nm-applet':
>=app-crypt/pinentry-1.1.0-r3 gnome-keyring

# required for 'xinit':
>=x11-apps/xinit-1.4.1 -minimal

# required by 'x11-drivers/xf86-video-vmware':
>=x11-libs/libdrm-2.4.101 video_cards_vmware

DATA

# ---- set required licenses

cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-xorg
# required for funtoo profile 'X':
>=media-libs/libpng-1.6.37 libpng2
DATA

# ---- set 'X' profile

sudo epro mix-ins +X +gfxcard-vmware
sudo epro list

# ---- update system

sudo emerge -vtuDN --with-bdeps=y @world
sudo etc-update --verbose --preen
sudo emerge -vt @preserved-rebuild

sudo env-update
source /etc/profile

# ---- install xorg server

sudo emerge -vt \
	x11-base/xorg-x11 \
	x11-apps/xinit \
	x11-drivers/xf86-video-vmware

cat <<'DATA' | sudo tee -a /etc/X11/xorg.conf.d/10video.conf
# set vmware video driver
# see: see: https://forums.virtualbox.org/viewtopic.php?f=3&t=96378
Section "Device"
  BoardName    "VirtualBox Graphics"
  Driver       "vmware"
  Identifier   "Device[0]"
  VendorName   "Oracle Corporation"
EndSection
DATA

cat <<'DATA' | sudo tee -a /etc/X11/xorg.conf.d/30keyboard.conf
# set us-international keyboard
# see: https://blechtog.wordpress.com/2012/05/25/gentoo-config-for-us-international-keyboard-layout/
# see: https://zuttobenkyou.wordpress.com/2011/08/24/xorg-using-the-us-international-altgr-intl-variant-keyboard-layout/
Section "InputClass"
    Identifier "Default Keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "us"
    Option "XkbVariant" "altgr-intl"
EndSection
DATA

sudo gpasswd -a vagrant video

# ---- install display / window manager

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
>=x11-wm/fluxbox-1.3.7 vim-syntax
DATA

sudo emerge -vt \
	x11-misc/lightdm \
	sys-auth/elogind \
	x11-wm/fluxbox \
	x11-themes/fluxbox-styles-fluxmod

# TODO remove 'elogind' when FL-7408 is resolved

sudo sed -i 's/DISPLAYMANAGER=\"xdm\"/DISPLAYMANAGER=\"lightdm\"/g' /etc/conf.d/xdm

# configure lightdm: autologin user 'vagrant'
sudo sed -i 's/#autologin-user=/autologin-user=vagrant/g' /etc/lightdm/lightdm.conf

# ---- fluxbox config

mkdir ~vagrant/.fluxbox || true

cat <<'DATA' | sudo tee -a ~vagrant/.fluxbox/startup
#!/bin/sh
#
# fluxbox startup-script:
#
# Lines starting with a '#' are ignored.

# Change your keymap:
xmodmap "/home/vagrant/.Xmodmap"

# Applications you want to run with fluxbox.
# MAKE SURE THAT APPS THAT KEEP RUNNING HAVE AN ''&'' AT THE END.
#
# unclutter -idle 2 &
# wmnd &
# wmsmixer -w &
# idesk &

# Enable autoscaling client display:
sudo /usr/bin/VBoxClient --vmsvga &

# Initially start a terminal
xterm -fullscreen &

# And last but not least we start fluxbox.
# Because it is the last app you have to run it with ''exec'' before it.

exec fluxbox
# or if you want to keep a log:
# exec fluxbox -log "/home/vagrant/.fluxbox/log"

DATA
sudo chown vagrant:vagrant ~vagrant/.fluxbox/startup

cat <<'DATA' | sudo tee -a ~vagrant/.fluxbox/init
session.screen0.tab.placement:  TopLeft
session.screen0.tab.width:  64
session.screen0.clientMenu.usePixmap:   true
session.screen0.toolbar.height: 0
session.screen0.toolbar.alpha:  255
session.screen0.toolbar.onhead: 1
session.screen0.toolbar.placement:  BottomCenter
session.screen0.toolbar.visible:    true
session.screen0.toolbar.widthPercent:   100
session.screen0.toolbar.maxOver:    false
session.screen0.toolbar.layer:  Dock
session.screen0.toolbar.autoHide:   false
session.screen0.toolbar.tools:  prevworkspace, workspacename, nextworkspace, iconbar, systemtray, clock
session.screen0.titlebar.left:  Stick
session.screen0.titlebar.right: Minimize Maximize Close
session.screen0.iconbar.usePixmap:  true
session.screen0.iconbar.iconTextPadding:    10
session.screen0.iconbar.iconWidth:  128
session.screen0.iconbar.mode:   {static groups} (workspace)
session.screen0.iconbar.alignment:  Relative
session.screen0.tabs.usePixmap: true
session.screen0.tabs.maxOver:   false
session.screen0.tabs.intitlebar:    true
session.screen0.slit.layer: Dock
session.screen0.slit.alpha: 255
session.screen0.slit.maxOver:   false
session.screen0.slit.acceptKdeDockapps: true
session.screen0.slit.autoHide:  false
session.screen0.slit.placement: RightBottom
session.screen0.slit.onhead:    0
session.screen0.window.focus.alpha: 255
session.screen0.window.unfocus.alpha:   255
session.screen0.menu.alpha: 255
session.screen0.workspaces: 4
session.screen0.maxDisableMove: false
session.screen0.noFocusWhileTypingDelay:    0
session.screen0.showwindowposition: false
session.screen0.fullMaximization:   false
session.screen0.colPlacementDirection:  TopToBottom
session.screen0.autoRaise:  true
session.screen0.strftimeFormat: %k:%M
session.screen0.tooltipDelay:   500
session.screen0.workspacewarping:   true
session.screen0.focusModel: ClickFocus
session.screen0.rowPlacementDirection:  LeftToRight
session.screen0.clickRaises:    true
session.screen0.focusNewWindows:    true
session.screen0.windowMenu: /home/vagrant/.fluxbox/windowmenu
session.screen0.opaqueMove: true
session.screen0.tabFocusModel:  ClickToTabFocus
session.screen0.allowRemoteActions: false
session.screen0.workspaceNames: Workspace 1,Workspace 2,Workspace 3,Workspace 4,
session.screen0.menuDelay:  200
session.screen0.windowPlacement:    RowMinOverlapPlacement
session.screen0.edgeSnapThreshold:  10
session.screen0.maxIgnoreIncrement: true
session.screen0.defaultDeco:    NORMAL
session.screen0.maxDisableResize:   false
session.appsFile:   /home/vagrant/.fluxbox/apps
session.tabsAttachArea: Window
session.tabPadding: 0
session.keyFile:    ~/.fluxbox/keys
session.colorsPerChannel:   4
session.ignoreBorder:   false
session.cacheLife:  5
session.styleOverlay:   /home/vagrant/.fluxbox/overlay
session.cacheMax:   200
session.menuFile:   ~/.fluxbox/menu
session.doubleClickInterval:    250
session.menuSearch: itemstart
session.configVersion:  13
session.autoRaiseDelay: 250
session.slitlistFile:   /home/vagrant/.fluxbox/slitlist
session.styleFile:  /usr/share/fluxbox/fluxmod/styles/Pillow
session.forcePseudoTransparency:    false

DATA
sudo chown vagrant:vagrant ~vagrant/.fluxbox/init

cat <<'DATA' | sudo tee -a ~vagrant/.fluxbox/overlay
! Prevent styles from setting the background:
background: none

! Override Pillow theme:
toolbar.clock.color:            #444444
!toolbar.alpha:                  255
toolbar.color:                  #444444
toolbar.button.pressed.color:   #444444
window.title.focus.color:       #666666
window.title.unfocus.color:     #666666
window.handle.focus.color:      #444444
window.handle.unfocus.color:    #444444
window.grip.focus.color:        #444444
window.grip.unfocus.color:      #444444
window.label.focus.textColor:   #fefefe
window.label.unfocus.textColor: #fefefe
!window.alpha:                   255
menu.title.color:               #666666
menu.title.textColor:           #fefefe
menu.hilite.color:              #444444
menu.hilite.textColor:          #eeeeee
menu.frame.textColor:           #222222
menu.itemHeight:                14
!menu.alpha:                     255
borderColor:                    #666666

DATA
sudo chown vagrant:vagrant ~vagrant/.fluxbox/overlay

sudo rc-update add xdm default   # FIXME enabled just for debugging

# ---- install utils

sudo emerge -vt \
	x11-terms/xterm \
	x11-apps/mesa-progs \
	media-gfx/feh

cat <<'DATA' | sudo tee -a ~vagrant/.Xresources
! global font
*font: xft:terminus
*boldFont: xft:terminus

! xterm
xterm*background: black
xterm*foreground: lightgray
xterm*font: *-fixed-*-*-*-13-*
DATA
sudo chown vagrant:vagrant ~vagrant/.Xresources

cat <<'DATA' | sudo tee -a ~vagrant/.dmrc
[Desktop]
Session=fluxbox
DATA
sudo chown vagrant:vagrant ~vagrant/.dmrc

fluxbox-generate_menu -is -ds
