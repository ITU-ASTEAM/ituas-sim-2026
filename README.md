# ituas-sim-2026

ITU-ASTEAM'in 2026 sezonu simülasyon reposu.

## İçerik

| Klasör | Açıklama |
|---|---|
| [`kurulum/`](kurulum/README.md) | Ubuntu 24.04'e ROS 2 Jazzy, Gazebo Harmonic ve gerekli kütüphaneleri kuran ve kurulu yazılımları tarayan scriptler |

## 📌 Notlar

1. **Kurulum Docker ile yapılmalı.** `kurulum/` altındaki scriptler şu an her şeyi doğrudan bilgisayarın kendisine kuruyor. Hedef, aynı ortamın Docker ile kurulması.
2. **Her kodun kütüphaneleri bağımsız olmalı.** Bir kod, başka bir kodun kurduğu ya da bilgisayara elle kurulmuş bir kütüphaneye güvenmemeli; ihtiyaç duyduğu kütüphaneleri kendisi tanımlamalı.
