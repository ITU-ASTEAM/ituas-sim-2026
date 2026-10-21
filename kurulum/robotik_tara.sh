#!/usr/bin/env bash
# Sistemdeki robotik / simülasyon / görüntü işleme yazılımlarını listeler.
# Kullanım: bash robotik_tara.sh

B=$'\e[1;36m'; G=$'\e[32m'; Y=$'\e[33m'; N=$'\e[0m'
baslik() { echo; echo "${B}=== $1 ===${N}"; }
var()    { printf "  ${G}✔${N} %-28s %s\n" "$1" "$2"; }

# Komut varsa sürümüyle göster
komut() { # $1=isim $2=komut $3=sürüm komutu
  if command -v "$2" >/dev/null 2>&1; then
    v=$(eval "$3" 2>/dev/null | head -n1)
    var "$1" "${v:-($(command -v "$2"))}"
  fi
}

# Python modülü varsa sürümüyle göster
pymod() { # $1=isim $2=modül
  v=$(python3 -c "import $2 as m; print(getattr(m,'__version__','kurulu'))" 2>/dev/null) && var "$1 (python)" "$v"
}

# dpkg paketlerini desene göre listele
dpaket() { # $1=desen (sadece kurulu paketler, paket adına göre)
  command -v dpkg-query >/dev/null || return 0
  dpkg-query -W -f='${db:Status-Abbrev}\t${Package}\t${Version}\n' 2>/dev/null | \
    awk -F'\t' -v re="$1" '$1 ~ /^ii/ && $2 ~ re {print $2"\t"$3}' | \
    while IFS=$'\t' read -r p v; do var "$p" "$v"; done
}

baslik "ROS / ROS 2"
for d in /opt/ros/*/; do
  [ -d "$d" ] && var "ROS dağıtımı: $(basename "$d")" "$d"
done
[ -n "$ROS_DISTRO" ] && var "Aktif ROS_DISTRO" "$ROS_DISTRO"
komut "ros2 CLI" ros2 "echo ok"
komut "colcon" colcon "colcon version-check 2>&1 | grep -m1 colcon-core"
komut "rosdep" rosdep "rosdep --version"
komut "catkin (ROS1)" catkin_make "echo kurulu"
if command -v dpkg-query >/dev/null; then
  n=$(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 2>/dev/null | grep -c '^ii *ros-')
  [ "$n" -gt 0 ] && var "Toplam ros-* paketi" "$n adet"
fi
echo "  -- Önemli ROS paketleri --"
dpaket '^ros-[a-z]+-(desktop|ros-base|moveit|navigation2|nav2-bringup|slam-toolbox|cartographer|rtabmap|ros2-control|gazebo-ros|ros-gz|turtlebot3|rviz2|robot-localization|micro-ros|vision-opencv|cv-bridge|image-pipeline|realsense2-camera|zed)$'

echo "  -- ROS çalışma alanları (~ altında) --"
find "$HOME" -maxdepth 3 -type d -name src -path '*_ws/src' 2>/dev/null | \
  while read -r w; do var "Workspace" "$(dirname "$w") ($(find "$w" -name package.xml 2>/dev/null | wc -l) paket)"; done

baslik "Simülatörler"
komut "Gazebo (gz sim)" gz "gz sim --versions 2>/dev/null || gz --version"
komut "Gazebo Classic" gazebo "gazebo --version | grep -m1 -i version"
komut "Ignition Gazebo" ign "ign gazebo --versions"
komut "Webots" webots "webots --version"
komut "CoppeliaSim" coppeliaSim "echo kurulu"
komut "CoppeliaSim" coppeliasim "echo kurulu"
komut "PX4 / jMAVSim" px4 "echo kurulu"
komut "ArduPilot SITL" sim_vehicle.py "echo kurulu"
komut "QGroundControl" QGroundControl "echo kurulu"
ls -d "$HOME"/.local/share/ov/pkg/isaac* "$HOME"/isaac* 2>/dev/null | while read -r d; do var "NVIDIA Isaac Sim" "$d"; done
ls -d "$HOME"/CARLA* /opt/carla* 2>/dev/null | while read -r d; do var "CARLA" "$d"; done
dpaket '^(gz-|ignition-|gazebo[0-9]*$|libgazebo)'
pymod "MuJoCo" mujoco
pymod "PyBullet" pybullet
pymod "Gymnasium" gymnasium

baslik "Görüntü İşleme / Bilgisayarlı Görü"
for pc in opencv4 opencv; do pkg-config --exists $pc 2>/dev/null && { var "OpenCV (C++)" "$(pkg-config --modversion $pc)"; break; }; done
pymod "OpenCV" cv2
pymod "Ultralytics (YOLO)" ultralytics
pymod "MediaPipe" mediapipe
pymod "Open3D" open3d
pymod "scikit-image" skimage
pymod "Pillow" PIL
pymod "dlib" dlib
pymod "pyrealsense2" pyrealsense2
pymod "Kornia" kornia
pymod "Supervision" supervision
pymod "pytesseract" pytesseract
komut "Tesseract OCR" tesseract "tesseract --version"
komut "RealSense Viewer" realsense-viewer "echo kurulu"
komut "ZED SDK" ZED_Explorer "echo kurulu"
[ -d /usr/local/zed ] && var "ZED SDK" "/usr/local/zed"
komut "GStreamer" gst-launch-1.0 "gst-launch-1.0 --version"
dpaket '^(libopencv-dev|libpcl-dev|libpcl-common.*|librealsense2(-dev)?|libopen3d.*|libapriltag.*|libaruco.*)$'

baslik "Yapay Zeka / Hızlandırma"
pymod "PyTorch" torch
pymod "TorchVision" torchvision
pymod "TensorFlow" tensorflow
pymod "ONNX Runtime" onnxruntime
pymod "TensorRT" tensorrt
pymod "OpenVINO" openvino
komut "CUDA (nvcc)" nvcc "nvcc --version | tail -n1"
if command -v nvidia-smi >/dev/null 2>&1; then
  if nv=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null | head -n1) && [ -n "$nv" ]; then
    var "NVIDIA sürücü" "$nv"
  else
    printf "  \e[31m✘\e[0m %-28s %s\n" "NVIDIA sürücü" "kurulu ama çalışmıyor (yeniden başlatma / Secure Boot?)"
  fi
fi
[ -f /etc/nv_tegra_release ] && var "Jetson (L4T)" "$(head -n1 /etc/nv_tegra_release)"

baslik "Kinematik / Kontrol / Planlama"
pymod "Pinocchio" pinocchio
pymod "roboticstoolbox" roboticstoolbox
pymod "spatialmath" spatialmath
pymod "ikpy" ikpy
pymod "CasADi" casadi
pymod "OMPL" ompl
pymod "python-control" control
dpaket '^(libompl-dev|libfcl-dev|liborocos-kdl.*|libeigen3-dev|libceres-dev|libgtsam.*|libg2o.*)$'

baslik "Gömülü / Donanım / İletişim"
komut "Arduino IDE" arduino "echo kurulu"
komut "Arduino CLI" arduino-cli "arduino-cli version"
komut "PlatformIO" pio "pio --version"
komut "ESP-IDF" idf.py "idf.py --version"
komut "STM32CubeIDE" stm32cubeide "echo kurulu"
komut "MAVProxy" mavproxy.py "echo kurulu"
pymod "pymavlink" pymavlink
pymod "MAVSDK" mavsdk
pymod "DroneKit" dronekit
pymod "pyserial" serial
pymod "python-can" can
pymod "Dynamixel SDK" dynamixel_sdk
komut "Mosquitto (MQTT)" mosquitto "mosquitto -h | head -n1"

baslik "Snap / Flatpak"
command -v snap >/dev/null && snap list 2>/dev/null | grep -iE 'ros|gazebo|gz|webots|arduino|qgroundcontrol|foxglove|plotjuggler|blender|freecad|kicad' | awk '{printf "  \033[32m✔\033[0m %-28s %s (snap)\n",$1,$2}'
command -v flatpak >/dev/null && flatpak list --columns=application,version 2>/dev/null | grep -iE 'arduino|freecad|kicad|blender|qgroundcontrol|foxglove' | awk '{printf "  \033[32m✔\033[0m %-28s %s (flatpak)\n",$1,$2}'

baslik "Görselleştirme / Araçlar"
komut "RViz2" rviz2 "echo kurulu"
komut "Foxglove Studio" foxglove-studio "echo kurulu"
komut "PlotJuggler" plotjuggler "echo kurulu"
komut "rqt" rqt "echo kurulu"
komut "FreeCAD" freecad "echo kurulu"
komut "Blender" blender "blender --version"
komut "KiCad" kicad "echo kurulu"
komut "Docker" docker "docker --version"

echo; echo "${Y}Tarama tamamlandı.${N}"
