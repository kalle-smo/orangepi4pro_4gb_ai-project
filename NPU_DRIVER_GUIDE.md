 РАБОТА С NPU VIVANTE VIP9000 (18 августа 2026, день)
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