#!/bin/bash
# Basit ntfy.sh kurulum scripti - sadece workflow kopyalar

set -e

# Renklendirme
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parametreleri kontrol et
if [ $# -ne 2 ]; then
    echo -e "${RED}❌ Kullanım: $0 <repo-name> <target-directory>${NC}"
    echo -e "${YELLOW}Örnek: $0 mvp-api /path/to/mvp-api${NC}"
    exit 1
fi

REPO_NAME="$1"
TARGET_DIR="$2"

echo -e "${BLUE}🔧 Basit ntfy.sh kurulumu - Sadece workflow${NC}"
echo -e "${YELLOW}📁 Repository: $REPO_NAME${NC}"
echo -e "${YELLOW}📂 Target: $TARGET_DIR${NC}"

# Target directory kontrolü
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}❌ Target directory bulunamadı: $TARGET_DIR${NC}"
    exit 1
fi

# Git repository kontrolü
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo -e "${RED}❌ Target directory bir git repository değil${NC}"
    exit 1
fi

# Repository'nin merkezi config'de kayıtlı olup olmadığını kontrol et
if [ -f "ntfy-manager.json" ]; then
    echo -e "${YELLOW}🔍 Repository kontrolü yapılıyor...${NC}"
    if uv run python -c "
import json
with open('ntfy-manager.json', 'r') as f:
    config = json.load(f)
if '$REPO_NAME' not in config['repositories']:
    print('❌ $REPO_NAME merkezi config''de kayıtlı değil')
    print('Önce ekleyin: uv run python ./ntfy-manager.py add-repo $REPO_NAME --private')
    exit(1)
else:
    print('✅ Repository merkezi config''de bulundu')
    exit(0)
" 2>/dev/null; then
        echo -e "${GREEN}✅ Kontrol başarılı${NC}"
    else
        echo -e "${RED}❌ Repository kontrolü başarısız${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ ntfy-manager.json bulunamadı${NC}"
    exit 1
fi

# Workflow directory oluştur
echo -e "${YELLOW}⚡ GitHub Actions workflow kopyalanıyor...${NC}"
mkdir -p "$TARGET_DIR/.github/workflows"

# Centralized workflow'u kopyala
cp ntfy-centralized-workflow.yml "$TARGET_DIR/.github/workflows/ntfy-notifications.yml"

echo -e "${GREEN}🎉 Kurulum tamamlandı!${NC}"
echo ""
echo -e "${YELLOW}📖 Sonraki adımlar:${NC}"
echo "1. Target repository'ye gidin: cd $TARGET_DIR"
echo "2. Workflow dosyasını commit edin:"
echo "   git add .github/workflows/ntfy-notifications.yml"
echo "   git commit -m 'Add ntfy.sh notification workflow'"
echo "   git push"
echo "3. GitHub Actions'da workflow'un çalışmasını bekleyin"
echo ""
echo -e "${BLUE}🔔 Bildirimler şu topic'e gelecek:${NC}"
uv run python ./ntfy-manager.py list | grep "$REPO_NAME" || echo "Config dosyasını kontrol edin"
echo ""
echo -e "${GREEN}✨ Avantajlar:${NC}"
echo "• Repository'ye Python dosyası kopyalamadık"
echo "• Tüm ntfy dosyaları merkezi repository'de kalıyor"
echo "• Workflow otomatik olarak merkezi config'i kullanacak"
echo "• Güncelleme sadece merkezi repository'de yapılır"