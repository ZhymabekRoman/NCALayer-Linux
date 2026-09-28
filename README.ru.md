# NCALayer for Linux

[English](README.md) | **Русский**

ВЕСЬ ИСХОДНЫЙ КОД ПРОЕКТА ОТКРЫТ И ПОЛНОСТЬЮ ВОСПРОИЗВОДИМ! НО ТЕМ НЕ МЕНЕЕ Я НЕ НЕСУ ОТВЕТСВТЕННОСТЬ ЗА ЛЮБОЙ ВРЕД ПРИНЕСЕННЫЙ ПРИ ИСПОЛЬЗОВАНИЯ ДАННОГО ПРОЕКТА!

## Причины портирование под линукс:

### Ужастная качество кода установщика, просто посмотрите на это:

```bash
zenity=`whereis -b zenity | grep -i bin |  cut -d' ' -f2`;
```

и
```bash
certutil=`whereis -b certutil | grep -i bin |  cut -d' ' -f2`;
```

Я не совсем профи тут, но малость не кажется что это перебор? Этот говнокод решается одной командой - `which zenity` и `which certutil`

И следущий facepalm установщика - захардкоденный терминал, а именно `gnome-terminal`. are you fucking serious? хотяяя бы xterm использовали бы чтоль, хотя вообще это тоже не совсем правильно, уже большинство дистрибутивов даже его не поставляют по дефолту.

### Более широкая поддержка разных дистрибутивов

На данный момент поддерживаемые дистрибутивы:
 - Debian/Ubuntu
 - Arch Linux (via AUR)
 - Fedora/RedHat/CentOS
 - AppImage (универсальный формат)

## Установка

### 📦 Скачивание готовых пакетов

Скачайте готовые пакеты из [GitHub Releases](https://github.com/ZhymabekRoman/NCALayer-Linux/releases/latest):

- **Arch Linux**: `ncalayer-*.pkg.tar.zst`
- **Debian/Ubuntu**: `ncalayer_*.deb`
- **Fedora** (с встроенной Java): `ncalayer-*fc*.rpm` (~260 МБ)
- **RHEL/CentOS/Rocky** (системная Java): `ncalayer-*el*.rpm` (~12 МБ)
- **AppImage** (универсальный): `NCALayer-x86_64.AppImage`

### Arch Linux

**Из AUR:**
```bash
yay -S ncalayer
# или
paru -S ncalayer
```

**Из скачанного пакета:**
```bash
sudo pacman -U ncalayer-*.pkg.tar.zst
```

### Debian/Ubuntu

```bash
sudo dpkg -i ncalayer_*.deb
sudo apt-get install -f  # Установит зависимости, если нужно
```

### Fedora/RHEL/CentOS

**Fedora** (с встроенной Java 8):
```bash
sudo dnf install ncalayer-*fc*.rpm
```

**Примечание:** Fedora не включает Java в официальные репозитории ([подробнее](https://docs.fedoraproject.org/en-US/quick-docs/installing-java/)). Поэтому для Fedora используется пакет со встроенной Java 8 (~260 МБ).

**RHEL/CentOS/Rocky Linux** (системная Java 8):
```bash
sudo dnf install ncalayer-*el*.rpm
```

### AppImage (универсальный формат)

```bash
chmod +x NCALayer-x86_64.AppImage
./NCALayer-x86_64.AppImage
```

AppImage не требует установки - работает на любом дистрибутиве Linux.

## Запуск приложения

### Пакеты дистрибутивов (deb/rpm/pkg.tar.zst)

После установки запустите:
```bash
ncalayer
```

Или найдите "NCALayer" в меню приложений (раздел "Сеть").

### AppImage

```bash
./NCALayer-x86_64.AppImage
```

## Установка сертификатов НУЦ РК

Сертификаты НУЦ устанавливаются **автоматически** во время установки пакета для всех существующих пользователей системы.

При необходимости переустановить сертификаты вручную:

**Для пакетов дистрибутивов:**
```bash
ncalayer-install-certs
```

**Для AppImage:**
```bash
./NCALayer-x86_64.AppImage --install-certs
```

Сертификаты устанавливаются в Firefox, Chrome, Chromium и другие браузеры, использующие NSS базы данных.

## Системные требования

### Пакеты дистрибутивов

**Debian/Ubuntu и Arch Linux** (размер ~12 МБ):
- **Java 8 JRE** (автоматически устанавливается как зависимость)
- **certutil** (из пакета nss-tools/libnss3-tools)
- Опционально: pcscd и libpcsclite для поддержки смарт-карт

**Fedora/RHEL/CentOS** (размер ~260 МБ):
- **Включает встроенный Java 8 JRE** (не требует установки системной Java)
- **certutil** (из пакета nss-tools)
- Опционально: pcsc-lite для поддержки смарт-карт

### AppImage (размер ~103 МБ)
- Никаких зависимостей (всё включено, в том числе Java 8)
- Работает на любом дистрибутиве Linux с glibc

## Совместимость с новыми версиями Java

NCALayer разработан для Java 8 и лучше всего работает с этой версией. Однако, если у вас установлена более новая версия Java (17+), приложение включает флаг `-Djava.security.manager=allow` для обхода проблемы с устаревшим Security Manager.

**Важно:** Начиная с Java 18, Security Manager отключен по умолчанию, а с JDK 24 - полностью удален ([JEP 411](https://openjdk.org/jeps/411)). При использовании Java 17+ вы можете увидеть предупреждение, но приложение должно работать.

Для лучшей совместимости рекомендуется использовать Java 8. Подробнее о проблеме: https://stackoverflow.com/questions/76151072/error-during-sbt-launcher-java-lang-unsupportedoperationexception-the-security

## Сборка из исходников

Инструкции по сборке пакетов из исходного кода смотрите в [BUILD.md](BUILD.md).

## Лицензия

Packaging and build scripts: MIT License (see [LICENSE](LICENSE))

NCALayer application: Copyright by National Certification Authority of the Republic of Kazakhstan