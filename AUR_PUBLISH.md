# Публикация в AUR (Arch User Repository)

Это пошаговое руководство по публикации пакета ncalayer в AUR.

## Предварительные требования

### 1. Создать аккаунт AUR

1. Перейдите на https://aur.archlinux.org/register
2. Зарегистрируйте аккаунт
3. Подтвердите email

### 2. Настроить SSH ключ

```bash
# Сгенерировать SSH ключ (если нет)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Скопировать публичный ключ
cat ~/.ssh/id_ed25519.pub
```

4. Перейдите в https://aur.archlinux.org/account/
5. Нажмите "My Account"
6. В разделе "SSH Public Key" вставьте ваш публичный ключ
7. Сохраните

### 3. Настроить Git

```bash
git config --global user.name "ZhymabekRoman"
git config --global user.email "robanokssamit@yandex.kz"
```

## Подготовка пакета

### 1. Создать первый релиз на GitHub

```bash
cd /home/olge/SOFT/git/NCALayer-Linux

# Закоммитить все изменения
git add .
git commit -m "Prepare for AUR publication"
git push

# Создать релиз
git tag v1.0.0
git push origin v1.0.0
```

Это запустит GitHub Actions и создаст релиз с пакетами.

### 2. Скачать релиз и вычислить SHA256

```bash
# Скачать архив с GitHub
wget https://github.com/ZhymabekRoman/NCALayer-Linux/archive/v1.0.0.tar.gz

# Вычислить SHA256
sha256sum v1.0.0.tar.gz
# Вывод: abc123def456... v1.0.0.tar.gz
```

### 3. Обновить PKGBUILD

Откройте `pkg/PKGBUILD` и обновите:

```bash
# Заменить 'SKIP' на реальный SHA256
sha256sums=('abc123def456...')  # Вставьте SHA256 из предыдущего шага
```

**ВАЖНО:** Для AUR нельзя использовать `sha256sums=('SKIP')` - это безопасность AUR.

### 4. Проверить PKGBUILD локально

```bash
cd pkg/
makepkg -si

# Проверить, что пакет собирается и устанавливается
# Если всё работает, удалить тестовый пакет:
sudo pacman -R ncalayer
```

## Публикация в AUR

### 1. Клонировать AUR репозиторий

```bash
# Клонировать пустой AUR репозиторий
git clone ssh://aur@aur.archlinux.org/ncalayer.git aur-ncalayer
cd aur-ncalayer
```

**Примечание:** При первом клонировании репозиторий будет пустым - это нормально.

### 2. Скопировать файлы пакета

```bash
# Скопировать PKGBUILD
cp ../NCALayer-Linux/pkg/PKGBUILD .

# Скопировать .install файл
cp ../NCALayer-Linux/pkg/ncalayer.install .

# Убедиться, что SHA256 обновлён (НЕ 'SKIP')
grep sha256sums PKGBUILD
```

### 3. Сгенерировать .SRCINFO

```bash
# Сгенерировать метаданные для AUR
makepkg --printsrcinfo > .SRCINFO

# Проверить содержимое
cat .SRCINFO
```

`.SRCINFO` содержит метаданные пакета в формате, который понимает AUR.

### 4. Закоммитить и отправить в AUR

```bash
# Добавить файлы
git add PKGBUILD ncalayer.install .SRCINFO

# Создать коммит
git commit -m "Initial commit: ncalayer 1.0.0

NCALayer digital signature application for Kazakhstan PKI

Features:
- Digital signature support for Kazakhstan NCA
- Certificate installer for browsers
- Smart card support
- System Java 8 dependency"

# Отправить в AUR
git push origin master
```

### 5. Проверить публикацию

Откройте в браузере: https://aur.archlinux.org/packages/ncalayer

Вы должны увидеть ваш пакет!

## Обновление пакета в AUR

Когда выходит новая версия:

### 1. Создать новый релиз

```bash
cd /home/olge/SOFT/git/NCALayer-Linux

# Обновить версию и закоммитить изменения
git add .
git commit -m "Release v1.1.0"
git push

# Создать тег
git tag v1.1.0
git push origin v1.1.0
```

### 2. Обновить PKGBUILD в AUR репозитории

```bash
cd aur-ncalayer

# Скачать новый релиз
wget https://github.com/ZhymabekRoman/NCALayer-Linux/archive/v1.1.0.tar.gz

# Вычислить новый SHA256
sha256sum v1.1.0.tar.gz

# Обновить PKGBUILD
vim PKGBUILD
```

Измените:
```bash
pkgver=1.1.0
pkgrel=1
sha256sums=('новый_sha256...')
```

**ВАЖНО:** При обновлении версии `pkgrel` сбрасывается в 1.

### 3. Обновить .SRCINFO и отправить

```bash
# Пересоздать .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Проверить изменения
git diff

# Закоммитить
git add PKGBUILD .SRCINFO
git commit -m "Update to v1.1.0

Changes:
- Новая функция X
- Исправлен баг Y
- Обновлены зависимости"

# Отправить
git push origin master
```

## Обновление pkgrel (без изменения версии)

Если нужно обновить только PKGBUILD без изменения версии программы:

```bash
cd aur-ncalayer

# Изменить только pkgrel
vim PKGBUILD
# pkgver=1.0.0
# pkgrel=2  ← Увеличить

# Обновить .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Закоммитить
git add PKGBUILD .SRCINFO
git commit -m "Fix PKGBUILD: add missing dependency"
git push origin master
```

## Распространённые проблемы

### Проблема: "Permission denied (publickey)"

**Решение:**
```bash
# Проверить SSH ключ
ssh-add -l

# Если ключ не добавлен:
ssh-add ~/.ssh/id_ed25519

# Проверить подключение к AUR
ssh aur@aur.archlinux.org
# Должно вывести: "Hi ZhymabekRoman! You've successfully authenticated..."
```

### Проблема: "error: failed to push some refs"

**Решение:**
```bash
# Возможно, кто-то обновил пакет перед вами
git pull --rebase origin master
git push origin master
```

### Проблема: Пакет не появляется в AUR

**Причины:**
1. Имя пакета уже занято (проверьте: https://aur.archlinux.org/packages/)
2. `.SRCINFO` не обновлён (`makepkg --printsrcinfo > .SRCINFO`)
3. Не закоммичен `.SRCINFO` (`git add .SRCINFO`)

## Поддержка пакета

### Ответы на комментарии

Пользователи могут оставлять комментарии на странице пакета. Проверяйте их регулярно и отвечайте:

https://aur.archlinux.org/packages/ncalayer

### Пометка устаревшим (out-of-date)

Если кто-то пометил ваш пакет как устаревший:
1. Обновите пакет до последней версии
2. Снимите флаг "out-of-date" на странице пакета

### Сироты (orphaned packages)

Если вы больше не можете поддерживать пакет:
1. Перейдите на https://aur.archlinux.org/packages/ncalayer
2. Нажмите "Disown Package"
3. Другой мейнтейнер сможет его забрать

## Автоматизация

### Использование aurpublish

Для упрощения публикации можно использовать `aurpublish`:

```bash
# Установить aurpublish
yay -S aurpublish

# Настроить
cd aur-ncalayer
git config --local alias.aur-push '!aurpublish'

# Теперь можно просто:
git add PKGBUILD .SRCINFO
git aur-push -m "Update to v1.1.0"
```

### Script для автоматического обновления

Создайте `update-aur.sh`:

```bash
#!/bin/bash
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

# Скачать новый релиз
wget "https://github.com/ZhymabekRoman/NCALayer-Linux/archive/v${VERSION}.tar.gz"

# Вычислить SHA256
SHA256=$(sha256sum "v${VERSION}.tar.gz" | cut -d' ' -f1)
echo "SHA256: $SHA256"

# Обновить PKGBUILD
sed -i "s/^pkgver=.*/pkgver=${VERSION}/" PKGBUILD
sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
sed -i "s/^sha256sums=.*/sha256sums=('${SHA256}')/" PKGBUILD

# Обновить .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Показать изменения
git diff

# Удалить архив
rm "v${VERSION}.tar.gz"

echo ""
echo "Готово! Теперь выполните:"
echo "  git add PKGBUILD .SRCINFO"
echo "  git commit -m 'Update to v${VERSION}'"
echo "  git push origin master"
```

Использование:
```bash
chmod +x update-aur.sh
./update-aur.sh 1.1.0
```

## Полезные ссылки

- **AUR Wiki**: https://wiki.archlinux.org/title/AUR_submission_guidelines
- **Arch Packaging Standards**: https://wiki.archlinux.org/title/Arch_package_guidelines
- **PKGBUILD Reference**: https://wiki.archlinux.org/title/PKGBUILD
- **AUR Homepage**: https://aur.archlinux.org/
- **Ваш пакет (после публикации)**: https://aur.archlinux.org/packages/ncalayer

## Чеклист перед публикацией

- [ ] Аккаунт AUR создан и подтверждён
- [ ] SSH ключ добавлен в аккаунт AUR
- [ ] Создан релиз на GitHub (v1.0.0)
- [ ] Вычислен SHA256 релиза
- [ ] `sha256sums` в PKGBUILD обновлён (НЕ 'SKIP')
- [ ] PKGBUILD протестирован локально (`makepkg -si`)
- [ ] Клонирован AUR репозиторий
- [ ] Скопированы PKGBUILD и ncalayer.install
- [ ] Создан .SRCINFO (`makepkg --printsrcinfo > .SRCINFO`)
- [ ] Файлы закоммичены и отправлены в AUR
- [ ] Пакет виден на https://aur.archlinux.org/packages/ncalayer

## Примеры коммитов

**Первая публикация:**
```
Initial commit: ncalayer 1.0.0

NCALayer digital signature application for Kazakhstan PKI
```

**Обновление версии:**
```
Update to v1.1.0

Changes:
- Add automatic certificate installation
- Fix smart card detection
- Update dependencies
```

**Исправление PKGBUILD:**
```
Fix PKGBUILD: add missing optdepends

Added pcsclite as optional dependency for smart card support
```

**Обновление метаданных:**
```
Update maintainer email and homepage URL
```

Удачи с публикацией! 🚀
