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

# FIXME check build config for compatibility:
# - should BUILD_KERNEL be set to 'true'?
# - should BUILD_HEADLESS be set to 'true'?

# ---- console mouse support

sudo emerge -vt sys-libs/gpm
sudo rc-update add gpm default

# ---- set make.conf

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
# FIXME:
# - virtualbox-video seems not to build!
# - vmware not included in mix-in 'gfxcard-vmware'?
# - 3d acceleration seems not working
# - other stuff, see also FL-7431
#VIDEO_CARDS="virtualbox vmware gallium-vmware xa"
VIDEO_CARDS="vmware gallium-vmware xa"

DATA

# ---- set required USE flags

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
# required for funtoo profile 'X':
media-libs/gd fontconfig jpeg truetype png
#media-libs/mesa -llvm xa gallium-vmware
media-libs/mesa xa gallium-vmware
#media-libs/mesa xa gallium-vmware unwind

# required for 'lightdm':
sys-auth/consolekit policykit

# required for 'xinit':
x11-apps/xinit -minimal

# required by 'x11-drivers/xf86-video-vmware':
x11-libs/libdrm video_cards_vmware

# required for TrueType support:
x11-terms/xterm truetype
x11-libs/libXfont2 truetype

DATA

# ---- set required licenses

cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-xorg
# required for funtoo profile 'X':
>=media-libs/libpng-1.6.37 libpng2
DATA

# TODO try also without llvm? (mesa USE -llvm)
cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-llvm
>=sys-devel/llvm-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/llvm-common-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/clang-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/clang-common-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/compiler-rt-sanitizers-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/compiler-rt-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/libomp-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/llvm-libunwind-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/lld-9.0 Apache-2.0-with-LLVM-exceptions
>=dev-util/lldb-9.0 Apache-2.0-with-LLVM-exceptions
DATA

# ---- set 'X' profile

sudo epro mix-ins +X +gfxcard-vmware
sudo epro list

# ---- prepare system update

# pkg 'rust' gets pulled in by 'X' but needs a significant amount
# of time to compile, therefore we prefer to compile pkg 'rust-bin' instead
sudo emerge -vt dev-lang/rust-bin

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

# TODO remove 'elogind' once FL-7408 is resolved
sudo emerge -vt \
	x11-misc/lightdm \
	sys-auth/elogind \
	x11-wm/fluxbox \
	x11-themes/fluxbox-styles-fluxmod

sudo sed -i 's/DISPLAYMANAGER=\"xdm\"/DISPLAYMANAGER=\"lightdm\"/g' /etc/conf.d/xdm

# configure lightdm: autologin user 'vagrant'
sudo sed -i 's/#user-session=default/user-session=fluxbox/g' /etc/lightdm/lightdm.conf
sudo sed -i 's/#autologin-user=/autologin-user=vagrant/g' /etc/lightdm/lightdm.conf

# ---- fluxbox config

cat <<'DATA' | sudo tee -a ~vagrant/.dmrc
[Desktop]
Session=fluxbox
DATA
sudo chown vagrant:vagrant ~vagrant/.dmrc

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

# TODO customize usermenu

fluxbox-generate_menu -is -ds

#sudo rc-update add xdm default   # enable just for debugging

# ---- install utils

sudo emerge -vt \
	x11-terms/xterm \
	x11-apps/mesa-progs \
	media-gfx/feh

cat <<'DATA' | sudo tee -a ~vagrant/.Xresources
! Default settings for X11
! Enable it at runtime with :
! $ xrdb ~/.Xresources
! or
! $ cat ~/.Xresources | xrdb

 *background: #000000
 *foreground: #ffffff
 *color0:     #000000
 *color1:     #d36265
 *color2:     #aece91
 *color3:     #e7e18c
 *color4:     #7a7ab0
 *color5:     #963c59
 *color6:     #418179
 *color7:     #bebebe
 *color8:     #666666
 *color9:     #ef8171
 *color10:    #e5f779
 *color11:    #fff796
 *color12:    #4186be
 *color13:    #ef9ebe
 *color14:    #71bebe
 *color15:    #ffffff

 xterm*utf8: 1
 xterm*faceName: Terminus
 xterm*faceSize: 10
 xterm*renderFont: true
 
! references:
! see: https://robotmoon.com/256-colors/
! see: https://wiki.archlinux.org/index.php/X_resources
! see: http://futurile.net/2016/06/14/xterm-setup-and-truetype-font-configuration/

DATA
sudo chown vagrant:vagrant ~vagrant/.Xresources

sudo eselect fontconfig enable 10-autohint.conf || true
sudo eselect fontconfig enable 10-no-sub-pixel.conf || true
sudo eselect fontconfig disable 10-scale-bitmap-fonts.conf || true
sudo eselect fontconfig disable 70-no-bitmaps.conf || true
sudo eselect fontconfig enable 70-yes-bitmaps.conf || true
sudo eselect fontconfig enable 75-yes-terminus.conf || true
sudo eselect fontconfig list
