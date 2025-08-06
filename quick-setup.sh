#!/bin/bash
# ntfy.sh Hızlı Kurulum ve Kullanım Scripti

set -e

# Renklendirme
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 ntfy.sh Notification Manager Kurulumu${NC}"

# Python gereksinimleri kontrolü
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 gerekli${NC}"
    exit 1
fi

# requests kütüphanesi kontrolü ve kurulumu
if ! python3 -c "import requests" 2>/dev/null; then
    echo -e "${YELLOW}📦 requests kütüphanesi kuruluyor...${NC}"
    pip3 install requests
fi

echo -e "${GREEN}✅ Gereksinimler tamam${NC}"

# Mevcut repository için hızlı kurulum
current_repo=$(basename "$(pwd)")
if [ -d ".git" ]; then
    echo -e "${YELLOW}📁 Mevcut repository: $current_repo${NC}"
    echo -e "${GREEN}Repository ekleniyor...${NC}"
    python3 ntfy-manager.py add-repo "$current_repo"
else
    echo -e "${YELLOW}⚠️  Git repository değil, manuel setup gerekli${NC}"
fi

echo -e "${GREEN}🎉 Kurulum tamamlandı!${NC}"
echo ""
echo -e "${YELLOW}📖 Hızlı Kullanım:${NC}"
echo "• Repository ekle: ./ntfy-manager.py add-repo my-project"
echo "• Event aç/kapat: ./ntfy-manager.py toggle my-project build"
echo "• Bildirim gönder: ./ntfy-manager.py send my-project deploy 'Deploy successful!'"
echo "• Bildirimleri görüntüle: ./ntfy-manager.py view"
echo "• Repository'leri listele: ./ntfy-manager.py list"
echo ""
echo -e "${GREEN}📱 ntfy.sh uygulamasını indirin:${NC}"
echo "• Android: https://play.google.com/store/apps/details?id=io.heckel.ntfy"
echo "• iOS: https://apps.apple.com/us/app/ntfy/id1625396347"
echo "• Web: https://ntfy.sh/app"