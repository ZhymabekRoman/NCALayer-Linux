#!/bin/bash
# AUR Publishing Script for NCALayer
set -e

VERSION="${1:-1.0.0}"
AUR_REPO="ssh://aur@aur.archlinux.org/ncalayer.git"
GITHUB_USER="ZhymabekRoman"
GITHUB_REPO="NCALayer-Linux"

echo "=========================================="
echo "Publishing NCALayer v${VERSION} to AUR"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if SSH key is set up for AUR
# -n keeps ssh from consuming piped stdin (e.g. the "yes" confirmation below)
echo "Checking AUR SSH access..."
if ! ssh -n -T aur@aur.archlinux.org 2>&1 | grep -q "Welcome to AUR"; then
    echo -e "${RED}ERROR: Cannot authenticate with AUR via SSH${NC}"
    echo ""
    echo "Please add your SSH public key to AUR:"
    echo "1. Go to https://aur.archlinux.org/"
    echo "2. Log in to your account"
    echo "3. Go to 'My Account'"
    echo "4. Add this SSH key:"
    echo ""
    cat ~/.ssh/id_ed25519.pub
    echo ""
    exit 1
fi
echo -e "${GREEN}✓ AUR SSH authentication successful${NC}"
echo ""

# Step 1: Download and get source tarball checksum
echo "Step 1: Downloading source tarball from GitHub..."
TARBALL_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/tags/v${VERSION}.tar.gz"
TARBALL_FILE="ncalayer-${VERSION}.tar.gz"

if [ -f "$TARBALL_FILE" ]; then
    echo "Tarball already exists, removing old version..."
    rm -f "$TARBALL_FILE"
fi

echo "Downloading: $TARBALL_URL"
wget -q --show-progress "$TARBALL_URL" -O "$TARBALL_FILE"

if [ ! -f "$TARBALL_FILE" ]; then
    echo -e "${RED}ERROR: Failed to download source tarball${NC}"
    echo "URL: $TARBALL_URL"
    exit 1
fi

echo -e "${GREEN}✓ Downloaded successfully${NC}"
echo ""

# Step 2: Calculate SHA256 checksum
echo "Step 2: Calculating SHA256 checksum..."
SOURCE_SHA256=$(sha256sum "$TARBALL_FILE" | cut -d' ' -f1)
echo "SHA256: $SOURCE_SHA256"
echo ""

# Step 3: Clone AUR repository
echo "Step 3: Cloning AUR repository..."
AUR_DIR="aur-ncalayer"

if [ -d "$AUR_DIR" ]; then
    echo "AUR directory exists, updating..."
    cd "$AUR_DIR"
    git pull
    cd ..
else
    git clone "$AUR_REPO" "$AUR_DIR"
fi

cd "$AUR_DIR"
echo -e "${GREEN}✓ AUR repository ready${NC}"
echo ""

# Step 4: Create PKGBUILD
echo "Step 4: Creating PKGBUILD..."

cat > PKGBUILD << 'PKGBUILD_EOF'
# Maintainer: ZhymabekRoman <robanokssamit@yandex.kz>
pkgname=ncalayer
pkgver=VERSION_PLACEHOLDER
pkgrel=1
pkgdesc="NCALayer digital signature application for Kazakhstan PKI"
arch=('x86_64')
url="https://github.com/ZhymabekRoman/NCALayer-Linux"
license=('MIT')
depends=('java-runtime=8' 'nss')
optdepends=('pcsclite: Smart card support')
makedepends=('wget' 'unzip' 'make')
install=ncalayer.install
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/ZhymabekRoman/NCALayer-Linux/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('SHA256_PLACEHOLDER')

prepare() {
    cd "${srcdir}/NCALayer-Linux-${pkgver}"

    # Download ncalayer.zip during prepare phase
    make download
    make verify
    make extract
    make extract-jar
    make install-certs.sh
}

package() {
    cd "${srcdir}/NCALayer-Linux-${pkgver}"

    # Install JAR
    install -Dm644 ncalayer.jar "${pkgdir}/usr/share/${pkgname}/ncalayer.jar"

    # Install certificates
    install -Dm644 additions/cert/root_rsa.cer "${pkgdir}/usr/share/${pkgname}/cert/root_rsa.cer"
    install -Dm644 additions/cert/nca_rsa.cer "${pkgdir}/usr/share/${pkgname}/cert/nca_rsa.cer"

    # Install certificate installer
    install -Dm755 install-certs.sh "${pkgdir}/usr/bin/${pkgname}-install-certs"

    # Install launcher
    install -Dm755 pkg/launcher.sh "${pkgdir}/usr/bin/${pkgname}"

    # Install desktop entry
    sed 's/Exec=ncalayer/Exec=\/usr\/bin\/ncalayer/' ncalayer.desktop.template > ncalayer.desktop
    install -Dm644 ncalayer.desktop "${pkgdir}/usr/share/applications/${pkgname}.desktop"

    # Install icon
    install -Dm644 additions/ncalayer.png "${pkgdir}/usr/share/icons/hicolor/256x256/apps/${pkgname}.png"

    # Install documentation
    install -Dm644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"
    install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
PKGBUILD_EOF

# Replace placeholders
sed -i "s/VERSION_PLACEHOLDER/${VERSION}/" PKGBUILD
sed -i "s/SHA256_PLACEHOLDER/${SOURCE_SHA256}/" PKGBUILD

echo -e "${GREEN}✓ PKGBUILD created${NC}"
echo ""

# Copy .install file
echo "Copying ncalayer.install file..."
cp ../pkg/ncalayer.install .
echo -e "${GREEN}✓ ncalayer.install copied${NC}"
echo ""

# Step 5: Generate .SRCINFO
echo "Step 5: Generating .SRCINFO..."
makepkg --printsrcinfo > .SRCINFO
echo -e "${GREEN}✓ .SRCINFO generated${NC}"
echo ""

# Step 6: Show changes
echo "Step 6: Review changes..."
echo ""
echo "=== PKGBUILD ==="
head -20 PKGBUILD
echo "..."
echo ""
echo "=== .SRCINFO ==="
head -15 .SRCINFO
echo "..."
echo ""

# Step 7: Commit and push
echo "Step 7: Ready to publish to AUR"
echo ""
echo -e "${YELLOW}The following files will be committed:${NC}"
git status --short
echo ""

read -p "Do you want to publish to AUR? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Publishing cancelled${NC}"
    cd ..
    exit 0
fi

echo ""
echo "Committing changes..."
git add PKGBUILD .SRCINFO ncalayer.install
git commit -m "Update to version ${VERSION}

- Package version: ${VERSION}
- Source: https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/tags/v${VERSION}.tar.gz
- SHA256: ${SOURCE_SHA256}
"

echo "Pushing to AUR..."
git push

cd ..

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Successfully published to AUR!${NC}"
echo "=========================================="
echo ""
echo "Package URL: https://aur.archlinux.org/packages/ncalayer"
echo ""
echo "Users can now install with:"
echo "  yay -S ncalayer"
echo "  paru -S ncalayer"
echo ""
echo "Cleanup: rm -rf $AUR_DIR $TARBALL_FILE"
echo ""
