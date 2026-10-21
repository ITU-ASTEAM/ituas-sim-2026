# 🌊 ITU-ASTEAM Çalışma Ortamı Kurulumu

Bu klasördeki bash scriptleri, **ITU-ASTEAM** bünyesinde geliştirilen Gazebo simülasyon ortamını ve gerekli bağımlılıkları **Ubuntu 24.04** üzerine otomatik olarak kurar.

> **Not:** Bu kurulum kişisel bilgisayarlar (masaüstü / dizüstü) için hazırlanmıştır. Jetson gibi gömülü cihazlarda tam verim almak için farklı ve genellikle daha karmaşık bir kurulum gerekir.

## 📦 Kurulan Yazılımlar

| Kategori | Yazılımlar |
|---|---|
| ROS 2 | ROS 2 **Jazzy** (desktop), RViz2, rqt, colcon, rosdep |
| Simülasyon | **Gazebo Harmonic** (8.x) + `ros_gz` köprüsü |
| Görüntü işleme | OpenCV 4.6 (C++ ve Python), `cv_bridge`, Pillow, GStreamer |
| Nokta bulutu | PCL, `pcl_ros` |
| Kinematik | Orocos KDL, Eigen |
| Donanım | pyserial, seri port erişimi (`dialout` grubu) |
| GPU (isteğe bağlı) | Önerilen NVIDIA sürücüsü (`--nvidia` ile) |

Kurulum ayrıca:
- `~/ros2_ws` çalışma alanını oluşturur,
- ROS ortamını `~/.bashrc` dosyasına ekler (her terminalde otomatik yüklenir),
- Türkçe sistemlerde RViz/Gazebo'da ondalık virgül sorununu önlemek için `LC_NUMERIC=en_US.UTF-8` ayarlar (sistem dili değişmez).

## ✅ Gereksinimler

- Ubuntu **24.04 LTS** (Noble)
- İnternet bağlantısı ve `sudo` yetkisi
- Yaklaşık **10 GB** boş disk alanı

## 🚀 Kurulum

Scriptleri **normal kullanıcıyla** çalıştırın (`sudo` ile değil); gerektiğinde şifre sorulur.

```bash
# NVIDIA ekran kartı varsa (önerilen):
bash robotik_kurulum.sh --nvidia

# NVIDIA kartı yoksa veya sürücü zaten kuruluysa:
bash robotik_kurulum.sh
```

Kurulum bittikten sonra:

1. Yeni bir terminal açın (veya `source ~/.bashrc` çalıştırın).
2. `--nvidia` kullandıysanız bilgisayarı yeniden başlatın: `sudo reboot`
3. Seri port (Arduino vb.) erişimi için oturumu kapatıp tekrar açın.

> **Secure Boot uyarısı:** NVIDIA sürücüsü kurulduktan sonra açılışta mavi bir **MOK** ekranı çıkarsa *Enroll MOK* seçeneğini seçip kurulumda belirlediğiniz şifreyi girin. Bu adım atlanırsa sürücü çalışmaz.

Script tekrar çalıştırılabilir; kurulu olan bileşenleri atlar. Tüm çıktı `~/robotik_kurulum_<tarih>.log` dosyasına kaydedilir.

### Kurulumu test etme

```bash
gz sim shapes.sdf                       # Gazebo açılmalı
ros2 run demo_nodes_cpp talker          # ROS 2 mesaj yayınlamalı
```

### Ek paketler

Navigation2, MoveIt, ros2_control ve slam_toolbox varsayılan olarak kurulmaz. İhtiyaç varsa `robotik_kurulum.sh` dosyasının başındaki `ROS_PAKETLERI` listesinde ilgili satırların başındaki `#` işaretini kaldırın.

## 🔍 Sistemi Tarama

`robotik_tara.sh`, bilgisayarda kurulu robotik yazılımlarını sürümleriyle listeler. Daha önce benzer yazılımlar kullandıysanız kurulumdan **önce** neyin zaten kurulu olduğunu görmek, kurulumdan **sonra** da her şeyin doğru kurulduğunu kontrol etmek için kullanabilirsiniz.

```bash
bash robotik_tara.sh
```

Kurulumdan sonra çıktı aşağıdakine benzer olmalıdır (sürüm numaraları ve paket sayısı farklılık gösterebilir):

```text
=== ROS / ROS 2 ===
  ✔ ROS dağıtımı: jazzy          /opt/ros/jazzy/
  ✔ Aktif ROS_DISTRO             jazzy
  ✔ ros2 CLI                     ok
  ✔ colcon                       colcon-core 0.21.3: up-to-date
  ✔ rosdep                       0.27.0
  ✔ Toplam ros-* paketi          330 adet
  -- Önemli ROS paketleri --
  ✔ ros-jazzy-cv-bridge          4.1.0-1noble.20260911.143610
  ✔ ros-jazzy-desktop            0.11.0-1noble.20261006.040109
  ✔ ros-jazzy-ros-base           0.11.0-1noble.20261006.035407
  ✔ ros-jazzy-ros-gz             1.0.24-1noble.20261006.041805
  ✔ ros-jazzy-rviz2              14.1.24-1noble.20260915.204213
  ✔ ros-jazzy-vision-opencv      4.1.0-1noble.20260911.145215
  -- ROS çalışma alanları (~ altında) --
  ✔ Workspace                    /home/kullanici/ros2_ws (0 paket)

=== Simülatörler ===
  ✔ Gazebo (gz sim)              8.15.0

=== Görüntü İşleme / Bilgisayarlı Görü ===
  ✔ OpenCV (C++)                 4.6.0
  ✔ OpenCV (python)              4.6.0
  ✔ Pillow (python)              10.2.0
  ✔ GStreamer                    gst-launch-1.0 version 1.24.2
  ✔ libopencv-dev                4.6.0+dfsg-13.1ubuntu1
  ✔ libpcl-common1.14            1.14.0+dfsg-1
  ✔ libpcl-dev                   1.14.0+dfsg-1

=== Yapay Zeka / Hızlandırma ===
  ✔ NVIDIA sürücü                NVIDIA GeForce RTX 3050 Ti Laptop GPU, 580.178.04

=== Kinematik / Kontrol / Planlama ===
  ✔ libeigen3-dev                3.4.0-4build0.1
  ✔ liborocos-kdl-dev            1.5.1-4build1
  ✔ liborocos-kdl1.5             1.5.1-4build1

=== Gömülü / Donanım / İletişim ===
  ✔ pyserial (python)            3.5

=== Snap / Flatpak ===

=== Görselleştirme / Araçlar ===
  ✔ RViz2                        kurulu
  ✔ rqt                          kurulu

Tarama tamamlandı.
```

Bilgisayarınızda kendi kurduğunuz başka yazılımlar varsa (örneğin Flatpak ile Arduino IDE veya KiCad), bunlar da ilgili bölümde listelenir.

## 🛠️ Sorun Giderme

| Belirti | Çözüm |
|---|---|
| `NVIDIA sürücü ✘ kurulu ama çalışmıyor` | Bilgisayarı yeniden başlatın. Secure Boot açıksa MOK kaydını yapın (yukarıya bakın). |
| `ros2: command not found` | Yeni terminal açın veya `source ~/.bashrc` çalıştırın. |
| Gazebo çok yavaş / siyah ekran | `nvidia-smi` ile sürücünün çalıştığını kontrol edin. |
| Seri porta erişim reddedildi | Oturumu kapatıp açın; `groups` çıktısında `dialout` görünmeli. |
| `Bu script Ubuntu 24.04 (noble) içindir` | Script yalnızca Ubuntu 24.04'te çalışır. |

Kurulum sırasında bir hata olursa log dosyasını (`~/robotik_kurulum_*.log`) ekip ile paylaşın.
