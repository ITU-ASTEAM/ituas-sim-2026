#!/usr/bin/env bash
# =====================================================================
#  Ubuntu 24.04 (Noble) robotik ortam kurulumu
#  ROS 2 Jazzy (desktop) + Gazebo Harmonic (ros_gz) + OpenCV + PCL
#  + KDL + GStreamer + RViz2/rqt + colcon/rosdep + pyserial
#
#  Kullanım:  bash robotik_kurulum.sh            # standart kurulum
#             bash robotik_kurulum.sh --nvidia   # + önerilen NVIDIA sürücüsü
#
#  Script tekrar çalıştırılabilir; kurulu olanları atlar.
# =====================================================================
set -euo pipefail

# ---------------- Paket listeleri (buradan düzenleyebilirsin) --------
ROS_DISTRO_ADI="jazzy"

ROS_PAKETLERI=(
  ros-dev-tools                      # colcon, rosdep, vcstool
  "ros-${ROS_DISTRO_ADI}-desktop"      # ROS 2 + RViz2 + rqt + demolar
  "ros-${ROS_DISTRO_ADI}-ros-gz"       # Gazebo Harmonic + ROS köprüsü
  "ros-${ROS_DISTRO_ADI}-vision-opencv"  # cv_bridge, image_geometry
  "ros-${ROS_DISTRO_ADI}-pcl-ros"      # PCL <-> ROS
  # İstersen aç:
  # ros-${ROS_DISTRO_ADI}-navigation2 ros-${ROS_DISTRO_ADI}-nav2-bringup
  # ros-${ROS_DISTRO_ADI}-moveit
  # ros-${ROS_DISTRO_ADI}-ros2-control ros-${ROS_DISTRO_ADI}-ros2-controllers
  # ros-${ROS_DISTRO_ADI}-slam-toolbox
)

SISTEM_PAKETLERI=(
  build-essential cmake git curl wget
  python3-pip python3-venv
  # Görüntü işleme
  libopencv-dev python3-opencv python3-pil
  # Nokta bulutu
  libpcl-dev pcl-tools
  # Kinematik
  liborocos-kdl-dev libeigen3-dev
  # GStreamer (kamera / video akışı)
  gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good
  gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
  # Seri port
  python3-serial
)

WORKSPACE="$HOME/ros2_ws"
# ---------------------------------------------------------------------

NVIDIA=0
for a in "$@"; do
  case "$a" in
    --nvidia) NVIDIA=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "Bilinmeyen seçenek: $a  (yardım: --help)"; exit 1 ;;
  esac
done

B=$'\e[1;36m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'
adim() { echo; echo "${B}==> $*${N}"; }
ok()   { echo "  ${G}✔${N} $*"; }
uyar() { echo "  ${Y}!${N} $*"; }
hata() { echo "${R}✘ $*${N}" >&2; exit 1; }
apt_kur() { sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"; }

trap 'echo "${R}✘ Hata: satır $LINENO. Ayrıntı için log: $LOG${N}" >&2' ERR

# ---------------- 0. Ön kontroller -----------------------------------
[ "$(id -u)" -ne 0 ] || hata "Scripti root olarak değil, normal kullanıcınla çalıştır (gerekince sudo şifresi sorar)."
# shellcheck disable=SC1091
. /etc/os-release
[ "${VERSION_CODENAME:-}" = "noble" ] || hata "Bu script Ubuntu 24.04 (noble) içindir. Bulunan: ${PRETTY_NAME:-bilinmiyor}"

LOG="$HOME/robotik_kurulum_$(date +%Y%m%d_%H%M).log"
exec > >(tee -a "$LOG") 2>&1
echo "Log dosyası: $LOG"
sudo -v   # şifreyi baştan bir kez sor

# ---------------- 1. Locale ------------------------------------------
adim "1/8 Locale (UTF-8) ayarı"
sudo apt-get update
apt_kur locales
if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf-\?8$'; then
  sudo locale-gen en_US.UTF-8
fi
ok "en_US.UTF-8 hazır (sistem dilin değişmez; sadece sayı biçimi için kullanılacak)"

# ---------------- 2. Depolar -----------------------------------------
adim "2/8 Ubuntu universe ve ROS 2 apt deposu"
apt_kur software-properties-common curl
sudo add-apt-repository -y universe
if dpkg-query -W -f='${Status}' ros2-apt-source 2>/dev/null | grep -q "install ok installed"; then
  ok "ROS 2 deposu zaten ekli"
else
  ROS_APT_SOURCE_VERSION=$(curl -fsSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
                           | grep -F '"tag_name"' | awk -F'"' '{print $4}')
  [ -n "$ROS_APT_SOURCE_VERSION" ] || hata "ros-apt-source sürümü alınamadı (internet / GitHub erişimini kontrol et)."
  TMP_DEB=$(mktemp --suffix=.deb)
  curl -fL -o "$TMP_DEB" \
    "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${UBUNTU_CODENAME:-$VERSION_CODENAME}_all.deb"
  sudo dpkg -i "$TMP_DEB"
  rm -f "$TMP_DEB"
  ok "ROS 2 deposu eklendi ($ROS_APT_SOURCE_VERSION)"
fi

# ---------------- 3. Sistem güncelleme -------------------------------
adim "3/8 Paket listesi ve sistem güncellemesi"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y   # ROS dokümanı kurulumdan önce önerir
ok "Sistem güncel"

# ---------------- 4. Sistem kütüphaneleri ----------------------------
adim "4/8 Görüntü işleme, PCL, KDL, GStreamer ve geliştirme araçları"
apt_kur "${SISTEM_PAKETLERI[@]}"
ok "Sistem kütüphaneleri kuruldu"

# ---------------- 5. ROS 2 + Gazebo ----------------------------------
adim "5/8 ROS 2 ${ROS_DISTRO_ADI^} + Gazebo Harmonic (uzun sürebilir)"
apt_kur "${ROS_PAKETLERI[@]}"
ok "ROS 2 ve Gazebo kuruldu"

# ---------------- 6. rosdep ------------------------------------------
adim "6/8 rosdep"
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
  sudo rosdep init
fi
rosdep update
ok "rosdep hazır"

# ---------------- 7. Çalışma alanı, .bashrc, izinler -----------------
adim "7/8 Çalışma alanı, ortam değişkenleri ve seri port izni"
mkdir -p "$WORKSPACE/src"
ok "Çalışma alanı: $WORKSPACE"

BASHRC="$HOME/.bashrc"
if ! grep -q '# >>> robotik ortam >>>' "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" <<EOF

# >>> robotik ortam >>>
source /opt/ros/${ROS_DISTRO_ADI}/setup.bash
[ -f "$WORKSPACE/install/setup.bash" ] && source "$WORKSPACE/install/setup.bash"
[ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash ] && source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash
# Türkçe sayı biçimi (ondalık virgül) RViz/Gazebo/URDF'de sorun çıkarabilir:
export LC_NUMERIC=en_US.UTF-8
# <<< robotik ortam <<<
EOF
  ok ".bashrc güncellendi"
else
  ok ".bashrc zaten ayarlı"
fi

if id -nG "$USER" | grep -qw dialout; then
  ok "$USER zaten dialout grubunda"
else
  sudo usermod -aG dialout "$USER"
  ok "$USER dialout grubuna eklendi (Arduino / seri port erişimi; oturumu yeniden açınca geçerli)"
fi

# ---------------- 8. NVIDIA (isteğe bağlı) ---------------------------
adim "8/8 NVIDIA sürücüsü"
NV_KART=0
if command -v lspci >/dev/null && lspci | grep -qi 'vga.*nvidia\|3d.*nvidia'; then NV_KART=1; fi
if [ "$NVIDIA" -eq 1 ]; then
  if [ "$NV_KART" -eq 1 ]; then
    apt_kur ubuntu-drivers-common
    sudo ubuntu-drivers install
    ok "Önerilen NVIDIA sürücüsü kuruldu, yeniden başlatma gerekli"
    uyar "Secure Boot açıksa açılışta 'MOK' ekranında anahtarı onaylaman gerekebilir."
  else
    uyar "NVIDIA ekran kartı bulunamadı, sürücü kurulmadı."
  fi
elif [ "$NV_KART" -eq 1 ]; then
  uyar "NVIDIA kart var. Sürücü için scripti --nvidia ile tekrar çalıştırabilirsin."
else
  ok "Atlandı"
fi

# ---------------- Doğrulama ------------------------------------------
adim "Doğrulama"
set +u   # ROS setup dosyaları tanımsız değişken kullanır
# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO_ADI}/setup.bash"
set -u
kontrol() { # $1=isim, kalan=komut
  local ad="$1"; shift
  local v
  if v=$("$@" 2>/dev/null | head -n1) && [ -n "$v" ]; then ok "$(printf '%-16s %s' "$ad" "$v")"
  else uyar "$ad bulunamadı"; fi
}
kontrol "ROS 2"         printenv ROS_DISTRO
kontrol "Gazebo"        gz sim --versions
kontrol "OpenCV C++"    pkg-config --modversion opencv4
kontrol "OpenCV Python" python3 -c "import cv2; print(cv2.__version__)"
kontrol "PCL"           pkg-config --modversion pcl_common
kontrol "KDL"           pkg-config --modversion orocos-kdl
kontrol "GStreamer"     gst-launch-1.0 --version
kontrol "pyserial"      python3 -c "import serial; print(serial.__version__)"
kontrol "colcon"        bash -c "command -v colcon"
kontrol "RViz2"         bash -c "command -v rviz2"

echo
echo "${G}Kurulum tamamlandı.${N}"
echo "  • Yeni bir terminal aç (veya: source ~/.bashrc)"
echo "  • Test:  gz sim shapes.sdf      |  ros2 run demo_nodes_cpp talker"
if [ "$NVIDIA" -eq 1 ] && [ "$NV_KART" -eq 1 ]; then
  echo "  • NVIDIA sürücüsü için bilgisayarı yeniden başlat: sudo reboot"
fi
echo "  • Log: $LOG"
