# ПОЛНАЯ ХРОНИКА РАБОТЫ С ORANGE PI 4 PRO
**Дата начала:** 17 августа 2026  
**Дата завершения:** 18 августа 2026  
**Продолжительность:** ~24 часа активной работы  
**Итог:** полностью рабочая система с NPU-инференсом и локальным AI-ассистентом

---

## МЕТАИНФОРМАЦИЯ
### Железо
**Устройство:** Orange Pi 4 Pro  
**Производитель:** Shenzhen Xunlong Software Co., Ltd  
**SoC:** Allwinner A733  
**Архитектура:** ARM64 (AArch64)  
**CPU:** 8-ядерный гибридный
- 2× ARM Cortex-A76 @ 1.8 GHz (производительные ядра)
- 6× ARM Cortex-A55 @ 1.8 GHz (энергоэффективные ядра)
**NPU (Neural Processing Unit):** Vivante VIP9000
- Производительность: 3 TOPS INT8
- Чип-идентификатор (CID): `0x1000003b`
- Количество ядер: 1
- Частота: ~1.0 GHz
**RAM:** 4 ГБ LPDDR4  
**Хранилище:** microSD 64 ГБ (класс A1/A2)  
**Сеть:**
- Ethernet: 1× Gigabit (чип Realtek RTL8211F)
- Wi-Fi: 802.11ac 2×2 MIMO (2.4 + 5 GHz)
- Bluetooth 5.0
**Видео:**
- GPU: Imagination BXM-4-64
- HDMI 2.0 (4K@60Hz)

### Программное обеспечение
**Операционная система:** Armbian 26.11 rolling  
**База:** Debian Trixie (testing)  
**Ядро Linux:** 6.6.98-vendor-sun60iw2  
**Менеджер пакетов:** APT (Advanced Package Tool)  
**Графическая среда:** XFCE 4.18  
**Display Manager:** LightDM 1.32.0  
**X-сервер:** Xorg (xserver-xorg)
**Ключевые версии ПО:**
- Python: 3.11+
- GCC: 13.x
- VIPLite: 2.0.3.2-AW-2024-08-30
- Ollama: 0.32.14
- Firefox ESR: 115.x

---

## ЭТАП 1: ДИАГНОСТИКА СЛОМАННОЙ СИСТЕМЫ (17 августа 2026, вечер)
### Исходное состояние
Плата была загружена с частично установленной системой. Предположительно, во время выполнения `apt upgrade` или `apt install xfce4` произошло прерывание (обрыв питания или потеря сети), что привело к повреждению файловой системы и пакетной базы.

### Обнаруженные проблемы
**1. Повреждённые Python-пакеты**
При попытке установки пакетов появлялись ошибки:
```text
Setting up python3-psutil ...
SyntaxError: source code string cannot contain null bytes
Setting up python3-urllib3 ...
SyntaxError: source code string cannot contain null bytes
```
**Причина:** .py-файлы в `/usr/lib/python3/dist-packages/` содержали нулевые байты (`\x00`), что делало их невалидными для Python-интерпретатора.  
**Следствие:** Post-install скрипты пакетов падали, что блокировало цепочку зависимостей: `terminator → xfce4-helpers → xfce4-settings → xfce4 → xfce4-session → lightdm`

**2. Сбой NetworkManager**
```bash
sudo systemctl status NetworkManager --no-pager
```
Вывод показывал: `Process: 1968 ExecStart=/usr/sbin/NetworkManager --no-daemon (code=killed, signal=SEGV)`  
**Причина:** Сегфолт (segmentation fault) — бинарный файл NetworkManager или его зависимости были повреждены на диске.  
**Следствие:** Нет автоматического управления сетью, DHCP не работал, подключение к интернету было невозможно.

**3. Неработающий LightDM**  
LightDM (графический менеджер входа) находился в цикле перезапусков и не мог запустить графическую среду.

**4. Отсутствие DHCP-клиента**  
В минимальном образе Armbian DHCP-клиент не был установлен по умолчанию, что усугубляло проблему с сетью.

### Диагностика
```bash
systemctl --failed
journalctl -u NetworkManager --no-pager | tail -30
cat /var/log/apt/history.log | tail -40
dpkg --audit
apt-get check
```

### Вывод диагностики
Система была **необратимо повреждена** на уровне бинарных файлов, исходных файлов Python и цепочек зависимостей. Попытка лечения по одному пакету была признана бесперспективной.  
**Решение:** Чистая переустановка системы с нуля.

---

## ЭТАП 2: ЧИСТАЯ ПЕРЕУСТАНОВКА (17 августа 2026, поздний вечер)
### Выбор образа
**Критическое решение:** Использовать образ **Armbian**, а не официальный образ Orange Pi.  
**Причины:**
1. Armbian основан на актуальном Debian (Trixie/testing).
2. Armbian имеет активное сообщество и регулярные обновления.
3. Armbian Minimal образ даёт чистую базу без лишнего софта.
4. Armbian лучше поддерживает современные ядра Linux.

**Конкретный образ:**
- **Название:** Armbian 26.11 rolling for Orange Pi 4 Pro
- **База:** Debian Trixie (testing)
- **Вариант:** Minimal (без графической среды)
- **Архитектура:** ARM64 (aarch64)
- **Ядро:** 6.6.98-vendor-sun60iw2 (вендорское ядро от Allwinner)

**URL загрузки:** `https://www.armbian.com/orangepi4pro/` или GitHub releases Armbian.

### Проверка контрольной суммы
**Критический шаг:** Проверка SHA256 хеша скачанного файла для исключения битых образов.
```bash
# Linux/macOS
sha256sum Armbian_*.img.xz

# Windows PowerShell
Get-FileHash Armbian_*.img.xz -Algorithm SHA256
```

### Запись образа на microSD
**Инструмент:** balenaEtcher или Raspberry Pi Imager.  
**Альтернатива (Linux/macOS):**
```bash
xz -d Armbian_*.img.xz
sudo dd if=Armbian_*.img of=/dev/sdX bs=4M status=progress
sync
```

---

## ЭТАП 3: FIRSTLOGIN И БАЗОВАЯ НАСТРОЙКА (17 августа 2026, ночь)
### Firstlogin-мастер Armbian
1. **Смена пароля root:** Использовать сложный пароль (12+ символов).
2. **Выбор shell:** `1) bash`
3. **Создание обычного пользователя:** Ввести удобное имя (например, `<имя_пользователя>`).
4. **Выбор локали:** `8) ru_RU.UTF-8`
5. **Выбор системной локали по умолчанию:** `2) en_US.UTF-8` (для стабильности консоли и логов).
6. **Выбор таймзоны:** `8) Europe` → `34) Moscow`
7. **Подключение к Wi-Fi:** Выбрать `<Название_WiFi_сети>` и ввести пароль.

### Первая проверка системы
```bash
uname -a
ls -l /dev/vipcore
lsmod | grep vipcore
dmesg | grep -i "VIPLite\|vipcore"
```

### Проблема SSH после переустановки
При попытке подключиться по SSH с ПК возникает предупреждение `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`.  
**Причина:** После переустановки SSH-сервер сгенерировал новые ключи.  
**Решение:**
```bash
ssh-keygen -f '/home/<имя_пользователя>/.ssh/known_hosts' -R '<IP_АДРЕС>'
ssh <имя_пользователя>@<IP_АДРЕС>
# Ответить 'yes' на запрос доверия новому ключу
```

---

## ЭТАП 4: НАСТРОЙКА ГРАФИЧЕСКОЙ СРЕДЫ (18 августа 2026, утро)
### Проблема с LightDM
Ошибка: `Failed to start lightdm.service`.  
В логе `/var/log/lightdm/lightdm.log`: `XServer 0: Can't launch X server X, not found in path`.  
**Причина:** X-сервер (Xorg) не был установлен из-за флага `--no-install-recommends`.

### Решение: Установка Xorg и XFCE
```bash
sudo apt update
sudo apt install -y xserver-xorg
sudo apt install -y xfce4 xfce4-terminal lightdm lightdm-gtk-greeter
sudo systemctl set-default graphical.target
sudo reboot
```

### Стилизация XFCE (опционально)
**Вариант 1: Стиль macOS (WhiteSur)**
```bash
sudo apt install -y git sassc fonts-inter plank xfce4-whiskermenu-plugin xfce4-docklike-plugin
cd /tmp
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-gtk-theme && ./install.sh -c dark && cd ..
cd WhiteSur-icon-theme && ./install.sh && cd ..

xfconf-query -c xsettings -p /Net/ThemeName -s WhiteSur-dark
xfconf-query -c xsettings -p /Net/IconThemeName -s WhiteSur
xfconf-query -c xsettings -p /Gtk/FontName -s "Inter 11"
```
*(Далее настройка панели и Plank через графический интерфейс или автозагрузку `~/.config/autostart/plank.desktop`)*

---

## ЭТАП 5: РАБОТА С NPU VIVANTE VIP9000 (18 августа 2026, день)
### Архитектура NPU Vivante VIP9000
- **Ядро:** `vipcore` (устройство `/dev/vipcore`, major 199, minor 0, права 666)
- **Userspace:** `libVIPhal.so`, `libNBGlinker.so`
- **Формат моделей:** NBG (Network Binary Graph), жёстко привязан к CID чипа `0x1000003b`.

### Проблема: Отсутствие userspace-библиотек
В Armbian драйвер загружается, но библиотеки отсутствуют:
```bash
ldconfig -p | grep -iE "viphal|nbg" # Пусто
```

### Решение: Извлечение библиотек из официального образа
1. Скачать официальный образ Orange Pi 4 Pro на ПК.
2. Распаковать `.img.xz` и смонтировать `.img` файл (или открыть через 7-Zip на Windows).
3. Извлечь из `/usr/lib/` монтированного образа:
   - `libVIPhal.so`
   - `libNBGlinker.so`
   - (Опционально) `libopencv_core.so.407`, `libopencv_imgcodecs.so.407`, `libopencv_imgproc.so.407`
4. Передать на плату:
```bash
scp -r ~/npu <имя_пользователя>@<IP_АДРЕС>:~/
```

### Установка userspace-библиотек на плате
```bash
cd ~/npu
sudo cp -v libVIPhal.so libNBGlinker.so /usr/lib/
sudo cp -v libopencv_*.so.407 /usr/lib/
sudo ldconfig

# Проверка
ldd /usr/lib/libNBGlinker.so
```

### Тест загрузки библиотек
```bash
cat > ~/npu/test_npu.c <<'EOF'
#include <stdio.h>
#include <dlfcn.h>
int main(void){
    void *h1 = dlopen("libVIPhal.so", RTLD_LAZY);
    if(!h1){ printf("FAIL libVIPhal: %s\n", dlerror()); return 1; }
    printf("OK: libVIPhal.so loaded\n");
    dlclose(h1);
    
    void *h2 = dlopen("libNBGlinker.so", RTLD_LAZY);
    if(!h2){ printf("FAIL libNBGlinker: %s\n", dlerror()); return 1; }
    printf("OK: libNBGlinker.so loaded\n");
    dlclose(h2);
    return 0;
}
EOF
gcc ~/npu/test_npu.c -o ~/npu/test_npu -ldl
~/npu/test_npu
```

### Компиляция тестовой утилиты vpm_run
```bash
cd ~
git clone --depth 1 https://github.com/ZIFENG278/ai-sdk.git
cd ~/ai-sdk/examples/vpm_run
gcc vpm_run.c -o vpm_run \
  -I../../viplite-tina/lib/aarch64-none-linux-gnu/v2.0/inc \
  -I../libawnn_viplite \
  -I../libawutils \
  -DSAVE_OUTPUT_TXT_FILE -DSHOW_TOP5 -DNPU_SW_VERSION=2 \
  -lNBGlinker -lVIPhal -lm

sudo mkdir -p /opt/vpm_run
sudo cp vpm_run /opt/vpm_run/
sudo chmod +x /opt/vpm_run/vpm_run
```

### Первый запуск NPU
```bash
mkdir -p ~/npu_test && cd ~/npu_test
cp ~/ai-sdk/examples/vpm_run/operator/sample.txt .
cp ~/ai-sdk/examples/vpm_run/operator/input_0.dat .
cp ~/ai-sdk/examples/vpm_run/operator/v3/network_binary.nb .

/opt/vpm_run/vpm_run -s sample.txt -l 5 -d 0 -b 0 --show_top5 1
```
**Ожидаемый успешный вывод:** `cid=0x1000003b`, `profile inference time=2901us`, `vpm run ret=0`.

### Ошибка с несовместимой моделью
Если использовать модели из папки `v2`, возникнет ошибка:  
`binary target=0x10000016, actually target=0x1000003B`.  
**Решение:** Использовать модели **только из папки `v3`**.

### Репозитории с документацией по NPU
1. **petayyyy/a733_npu_driver** (`https://github.com/petayyyy/a733_npu_driver`) — документация по запуску LLM/VLM, перенос стека с Radxa, замеры производительности.
2. **RiteshKumarRay/Radxa-VIP9000-NPU-Tracking** (`https://github.com/RiteshKumarRay/Radxa-VIP9000-NPU-Tracking`) — примеры кода для детекции и трекинга.
3. **Radxa Model Zoo** (`https://docs.radxa.com/en/cubie/a7s/app-dev/npu-dev/model-zoo/`) — готовые NBG-модели (YOLOv8n, YOLOv8s-pose, ResNet50 V2) под target `0x1000003b`.

### Ограничения NPU Vivante VIP9000
- **✅ Работает:** SmolLM2-135M/360M (int16), MobileCLIP-S0, ResNet50, YOLOv5/v8.
- **❌ Не работает:** Qwen2.5-0.5B, SmolLM2-1.7B и модели >700 МБ в формате NBG (ограничение тулчейна VeriSilicon ACUITY).
- **Рекомендация:** NPU использовать для CV-задач, а для текстовых LLM использовать CPU через Ollama/llama.cpp.

---

## ЭТАП 6: ЛОКАЛЬНЫЙ AI-АССИСТЕНТ ДЛЯ КОДИНГА (18 августа 2026, вечер)
### Постановка задачи
Развернуть локальный AI-ассистент для помощи в программировании, работающий полностью офлайн.  
**Требования:** Автодополнение кода, объяснение функций, рефакторинг, работа без интернета.

### Попытка 1: Компиляция llama.cpp
```bash
cd ~
git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
mkdir build && cd build
sudo apt update
sudo apt install -y cmake build-essential
cmake .. -DGGML_NATIVE=ON -DGGML_OPENMP=ON
make -j$(nproc)
```
*(Дальнейшая настройка Ollama и моделей Qwen 2.5 описана в отдельных скриптах репозитория).*

---
**Автор:** Kalle  
**Лицензия:** GPLv2