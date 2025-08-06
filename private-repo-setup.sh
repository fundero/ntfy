#!/bin/bash
# Private Repository için ntfy.sh Kurulum Scripti

set -e

# Renklendirme
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔒 Private Repository ntfy.sh Setup${NC}"

# Git repository kontrolü
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Bu dizin bir git repository değil${NC}"
    exit 1
fi

# Repository bilgilerini al
REPO_PATH=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_PATH")
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")

echo -e "${YELLOW}📁 Repository: $REPO_NAME${NC}"

# Private repository tespiti
IS_PRIVATE=false
if [[ "$REMOTE_URL" == *"github.com"* ]]; then
    # GitHub private repo kontrolü
    if gh repo view "$REPO_NAME" --json visibility --jq '.visibility' 2>/dev/null | grep -q "private"; then
        IS_PRIVATE=true
        echo -e "${YELLOW}🔒 Private GitHub repository tespit edildi${NC}"
    fi
elif [[ "$REMOTE_URL" == *"gitlab"* ]]; then
    echo -e "${YELLOW}🔒 GitLab repository - private olarak işaretleniyor${NC}"
    IS_PRIVATE=true
else
    echo -e "${YELLOW}❓ Repository türü belirsiz - private olarak işaretlensin mi? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        IS_PRIVATE=true
    fi
fi

# ntfy-manager kurulumu
if [ ! -f "ntfy-manager.py" ]; then
    echo -e "${YELLOW}📥 ntfy-manager.py indiriliyor...${NC}"
    # Burada gerçek bir URL'den indirebilirsiniz
    echo -e "${RED}❌ ntfy-manager.py bulunamadı. Önce ntfy-manager'ı kurun.${NC}"
    exit 1
fi

# Repository'yi ekle
echo -e "${GREEN}➕ Repository ekleniyor...${NC}"
if [ "$IS_PRIVATE" = true ]; then
    ./ntfy-manager.py add-repo "$REPO_NAME" --private
    echo -e "${GREEN}✅ Private repository olarak eklendi${NC}"
    echo -e "${YELLOW}📋 Güvenlik: Repo adı hash'lenerek gizlendi${NC}"
else
    ./ntfy-manager.py add-repo "$REPO_NAME"
    echo -e "${GREEN}✅ Public repository olarak eklendi${NC}"
fi

# Event'leri yapılandır
echo -e "${BLUE}⚙️  Event'ler yapılandırılıyor...${NC}"

# Yaygın event'ler için kurulum
echo -e "${YELLOW}📝 Hangi event'leri aktif etmek istiyorsunuz?${NC}"
echo "1) build (varsayılan: açık)"
echo "2) test (varsayılan: kapalı)" 
echo "3) deploy (varsayılan: açık)"
echo "4) error (varsayılan: açık)"
echo "5) push (git push)"
echo "6) pr (pull request)"
echo "7) release"

# Test event'ini aç
echo -e "${GREEN}✅ test event'i açılıyor...${NC}"
./ntfy-manager.py toggle "$REPO_NAME" test --enable

# Push event ekle
./ntfy-manager.py toggle "$REPO_NAME" push --enable
./ntfy-manager.py toggle "$REPO_NAME" pr --enable  
./ntfy-manager.py toggle "$REPO_NAME" release --enable

# GitHub Actions workflow'u kur
if [ -d ".github" ] || [[ "$REMOTE_URL" == *"github.com"* ]]; then
    echo -e "${BLUE}⚡ GitHub Actions workflow'u kuruluyor...${NC}"
    mkdir -p .github/workflows
    
    if [ ! -f ".github/workflows/ntfy-notifications.yml" ]; then
        cp ntfy-notifications.yml .github/workflows/ 2>/dev/null || echo -e "${YELLOW}⚠️  Workflow dosyası manuel olarak kopyalanması gerekiyor${NC}"
    fi
fi

# Test bildirimi gönder
echo -e "${BLUE}📱 Test bildirimi gönderiliyor...${NC}"
./ntfy-manager.py send "$REPO_NAME" test "🎉 ntfy.sh kurulumu tamamlandı!"

echo -e "${GREEN}🎉 Private repository kurulumu tamamlandı!${NC}"
echo ""
echo -e "${YELLOW}📖 Sonraki adımlar:${NC}"
echo "1. ntfy.sh mobile uygulamasını indirin"
echo "2. Repository'nizi listeleyin: ./ntfy-manager.py list"
echo "3. Topic'inizi subscribe edin (gizli topic adını görmek için list komutu)"
echo "4. Bildirimlerinizi test edin: ./ntfy-manager.py send $REPO_NAME build 'Test mesajı'"
echo ""
echo -e "${BLUE}🔒 Güvenlik Notu: Private repository'ler için:${NC}"
echo "• Topic adları hash'lenir"
echo "• Bildirim başlıklarında gerçek repo adı gösterilmez"
echo "• Hassas bilgiler mesajlarda paylaşılmamalıdır"