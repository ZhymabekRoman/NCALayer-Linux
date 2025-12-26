# Сборка из исходников / Building from Source

Этот документ описывает процесс сборки пакетов NCALayer для различных дистрибутивов Linux.

This document describes the process of building NCALayer packages for various Linux distributions.

## Быстрый старт / Quick Start

### Сборка AppImage

```bash
git clone https://github.com/ZhymabekRoman/NCALayer-Linux.git
cd NCALayer-Linux
make appimage
```

Это загрузит официальный архив ncalayer.zip с сайта НУЦ РК, проверит контрольные суммы, извлечёт все необходимые файлы и создаст AppImage.

This will download the official ncalayer.zip archive from NCA RK website, verify checksums, extract all necessary files, and create an AppImage.

### Сборка пакетов для дистрибутивов / Building Distribution Packages

**Arch Linux:**
```bash
make pkg-arch
# или / or
cd pkg && makepkg -cf
```

**Debian/Ubuntu:**
```bash
make pkg-deb
# или / or
dpkg-buildpackage -us -uc -b
```

**Fedora/RHEL/CentOS:**
```bash
make pkg-rpm
# или / or
rpmbuild -ba pkg/ncalayer.spec
```

## Требования для сборки / Build Requirements

### Все дистрибутивы / All Distributions
- `make`
- `wget` или `curl` или `aria2c`
- `unzip`
- `git` (для клонирования репозитория)

### Arch Linux
Дополнительно:
- `base-devel`
- `jre8-openjdk` (для тестирования)

### Debian/Ubuntu
Дополнительно:
- `build-essential`
- `debhelper` (>= 13)
- `devscripts`
- `openjdk-8-jre` (для тестирования)

### Fedora/RHEL/CentOS
Дополнительно:
- `rpm-build`
- `rpmdevtools`
- `java-1.8.0-openjdk` (для тестирования)

## Структура проекта / Project Structure

```
NCALayer-Linux/
├── Makefile                      # Система сборки / Build system
├── .github/workflows/            # GitHub Actions CI/CD
│   ├── ci.yml                    # Непрерывная интеграция / Continuous integration
│   └── package.yml               # Сборка пакетов / Package building
├── debian/                       # Метаданные пакета Debian/Ubuntu
│   ├── control                   # Зависимости и описание
│   ├── rules                     # Инструкции сборки
│   ├── changelog                 # История версий
│   ├── copyright                 # Лицензия
│   └── postinst                  # Пост-установочный скрипт
├── pkg/                          # Пакеты для других дистрибутивов
│   ├── PKGBUILD                  # Arch Linux
│   ├── ncalayer.spec             # Fedora/RHEL/CentOS
│   └── launcher.sh               # Универсальный скрипт запуска
├── AppRun.template               # Шаблон запуска AppImage
├── ncalayer.desktop.template     # Шаблон desktop-файла
└── install-certs.sh.template     # Шаблон установщика сертификатов
```

## Детали процесса сборки / Build Process Details

### Этапы сборки / Build Stages

1. **Загрузка** (`make download`)
   - Загружается `ncalayer.zip` с https://ncl.pki.gov.kz/
   - Размер: ~102 МБ

2. **Проверка** (`make verify`)
   - Проверяются контрольные суммы MD5 и SHA1
   - Гарантирует целостность загруженного файла

3. **Извлечение** (`make extract`)
   - Распаковывается архив
   - Извлекаются: `ncalayer.sh`, `additions/`, документация

4. **Извлечение JAR** (`make extract-jar`)
   - Из `ncalayer.sh` извлекается встроенный JAR-файл
   - Используется динамическое определение смещения через поиск сигнатуры PK
   - Размер JAR: ~11 МБ

5. **Генерация установщика сертификатов** (`make install-certs.sh`)
   - Создаётся автономный скрипт с встроенными сертификатами
   - Сертификаты кодируются в base64 и встраиваются в скрипт

6. **Сборка структуры AppImage** (`make build-appimage`)
   - Создаётся структура директорий AppImage
   - Копируются: JAR, JRE, сертификаты, иконка
   - Устанавливается `AppRun` и `.desktop` файл

7. **Упаковка AppImage** (`make appimage`)
   - Используется `appimagetool` для создания финального AppImage
   - Сжатие: 265 МБ → 103 МБ (сжатие ~61%)

### Сборка пакетов дистрибутивов / Distribution Package Building

#### Arch Linux (PKGBUILD)

PKGBUILD выполняет следующие шаги:

1. **prepare()**: Загружает и извлекает ncalayer.zip
2. **package()**: Устанавливает файлы в `$pkgdir`:
   - `/usr/share/ncalayer/ncalayer.jar` - основное приложение
   - `/usr/share/ncalayer/cert/` - сертификаты НУЦ
   - `/usr/bin/ncalayer` - скрипт запуска
   - `/usr/bin/ncalayer-install-certs` - установщик сертификатов
   - `/usr/share/applications/ncalayer.desktop` - desktop-файл
   - `/usr/share/icons/` - иконка приложения

**Зависимости времени выполнения:**
- `java-runtime=8` - Java 8 JRE
- `nss` - для certutil
- `pcsclite` (опционально) - поддержка смарт-карт

#### Debian/Ubuntu (debian/rules)

Использует debhelper для автоматизации:

1. **override_dh_auto_build**: Запускает `make download verify extract extract-jar install-certs.sh`
2. **override_dh_auto_install**: Устанавливает файлы в `debian/ncalayer/usr/...`
3. **override_dh_auto_clean**: Очищает временные файлы

**Зависимости:**
- Build: `debhelper-compat (= 13), wget, unzip`
- Runtime: `openjdk-8-jre | java8-runtime, libnss3-tools`

#### Fedora/RHEL (RPM spec)

Spec-файл определяет:

1. **%prep**: Распаковка исходников (`%autosetup`)
2. **%build**: Загрузка и извлечение ncalayer
3. **%install**: Установка в `%{buildroot}` с использованием RPM-макросов
4. **%files**: Список файлов в пакете
5. **%post**: Пост-установочное сообщение

**Макросы:**
- `%{_bindir}` → `/usr/bin`
- `%{_datadir}` → `/usr/share`
- `%{_docdir}` → `/usr/share/doc`

## CI/CD с GitHub Actions

### Рабочий процесс CI (ci.yml)

Запускается при каждом коммите или pull request:
- Проверяет возможность загрузки и извлечения
- Проверяет контрольные суммы
- Загружает артефакты для проверки

### Рабочий процесс сборки пакетов (package.yml)

Запускается при создании git-тега (например, `v1.0.0`):

1. **build-arch** (контейнер archlinux:latest, 15 мин)
   - Создаёт непривилегированного пользователя `builder`
   - Собирает с помощью `makepkg`
   - Загружает `*.pkg.tar.zst`

2. **build-deb** (ubuntu-latest, 15 мин)
   - Обновляет `debian/changelog` версией из тега
   - Собирает с помощью `dpkg-buildpackage`
   - Загружает `*.deb`

3. **build-rpm** (контейнер fedora:latest, 15 мин)
   - Настраивает дерево сборки RPM
   - Обновляет версию в `.spec`
   - Собирает с помощью `rpmbuild`
   - Загружает `*.rpm`

4. **build-appimage** (ubuntu-latest, 15 мин)
   - Использует существующую цель Makefile
   - Загружает `NCALayer-*.AppImage`

5. **create-release** (зависит от всех вышеперечисленных)
   - Скачивает все артефакты
   - Создаёт GitHub Release
   - Прикрепляет все пакеты с инструкциями по установке

### Триггер релиза / Triggering a Release

```bash
# Коммит изменений / Commit changes
git add .
git commit -m "Prepare release v1.0.0"
git push

# Создать и отправить тег / Create and push tag
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions автоматически:
1. Соберёт все 4 формата пакетов
2. Создаст GitHub Release
3. Прикрепит пакеты с инструкциями по установке

## Управление версиями / Version Management

Версия извлекается автоматически из git-тегов:

```makefile
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")
```

Во время CI/CD:
- PKGBUILD: `sed -i "s/^pkgver=.*/pkgver=${VERSION}/"`
- debian/changelog: `dch -v "${VERSION}-1"`
- .spec: `sed -i "s/^Version:.*/Version: ${VERSION}/"`

Не требуется ручное обновление версий в файлах метаданных!

## Размеры пакетов / Package Sizes

| Формат | Размер | Примечания |
|--------|--------|-----------|
| AppImage | ~103 МБ | Включает Java 8 JRE (255 МБ несжатых) |
| .deb | ~12 МБ | Зависит от системной Java |
| .rpm | ~12 МБ | Зависит от системной Java |
| .pkg.tar.zst | ~12 МБ | Зависит от системной Java |

## Отладка сборки / Build Troubleshooting

### Проблема: JAR не извлекается
```bash
make extract-jar
# Проверить, что ncalayer.sh существует и содержит сигнатуру PK
grep -abo "^PK" ncalayer.sh | head -1
```

### Проблема: Не удалось проверить контрольную сумму
```bash
# Проверить вручную
md5sum ncalayer.zip
sha1sum ncalayer.zip
# Сравнить с значениями в Makefile
```

### Проблема: Не удалось найти appimagetool
```bash
# Скачать вручную
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod +x appimagetool
```

### Проблема: Debian build fails (debhelper)
```bash
# Установить необходимые зависимости
sudo apt-get install debhelper devscripts build-essential
```

## Локальное тестирование пакетов / Local Package Testing

### Тест Arch пакета (Docker)
```bash
docker run -it --rm -v $(pwd):/build archlinux:latest bash
cd /build
pacman -Syu --noconfirm
pacman -S --noconfirm base-devel wget unzip jre8-openjdk
useradd -m builder && chown -R builder:builder .
su - builder -c "cd /build && makepkg -cf"
```

### Тест Debian пакета (Docker)
```bash
docker run -it --rm -v $(pwd):/build debian:bookworm bash
cd /build
apt-get update
apt-get install -y build-essential debhelper devscripts wget unzip openjdk-8-jre
dpkg-buildpackage -us -uc -b
```

### Тест RPM пакета (Docker)
```bash
docker run -it --rm -v $(pwd):/build fedora:latest bash
cd /build
dnf install -y rpm-build rpmdevtools make wget unzip java-1.8.0-openjdk
rpmdev-setuptree
rpmbuild -ba pkg/ncalayer.spec
```

## Публикация в AUR / Publishing to AUR

Детальное руководство по публикации пакета в AUR смотрите в [AUR_PUBLISH.md](AUR_PUBLISH.md).

For detailed instructions on publishing to AUR, see [AUR_PUBLISH.md](AUR_PUBLISH.md).

Краткая версия / Quick version:

После успешной первой сборки CI:

1. **Клонировать AUR репозиторий:**
   ```bash
   git clone ssh://aur@aur.archlinux.org/ncalayer.git aur-ncalayer
   cd aur-ncalayer
   ```

2. **Скопировать PKGBUILD:**
   ```bash
   cp ../pkg/PKGBUILD .
   ```

3. **Обновить метаданные:**
   - Добавить информацию о мейнтейнере
   - Заменить `sha256sums=('SKIP')` на реальный хэш
   - Проверить URL источника

4. **Вычислить SHA256:**
   ```bash
   # Скачать релиз с GitHub
   wget https://github.com/ZhymabekRoman/NCALayer-Linux/archive/v1.0.0.tar.gz
   sha256sum v1.0.0.tar.gz
   # Обновить sha256sums в PKGBUILD
   ```

5. **Сгенерировать .SRCINFO:**
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

6. **Закоммитить и отправить:**
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Initial commit: ncalayer 1.0.0"
   git push
   ```

## Очистка / Cleanup

```bash
make clean-all      # Удалить все артефакты сборки
make clean-pkg      # Удалить только пакеты дистрибутивов
make clean-appimage # Удалить только артефакты AppImage
```

## Дополнительные ресурсы / Additional Resources

- [Arch Linux Package Guidelines](https://wiki.archlinux.org/title/PKGBUILD)
- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Fedora RPM Packaging Guide](https://docs.fedoraproject.org/en-US/package-maintainers/Packaging_Tutorial_GNU_Hello/)
- [AppImage Documentation](https://docs.appimage.org/)
