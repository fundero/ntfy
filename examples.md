# ntfy.sh Notification Manager - Kullanım Örnekleri

## 🚀 Hızlı Başlangıç

```bash
# Kurulumu çalıştır
./quick-setup.sh

# Mevcut repository'yi ekle (git dizinindeyken)
./ntfy-manager.py send auto build "Build completed successfully!"
```

## 📝 Temel Komutlar

### Repository Yönetimi

```bash
# Yeni repository ekle
./ntfy-manager.py add-repo my-project

# Özel topic ile repository ekle
./ntfy-manager.py add-repo my-project --topic custom-topic-name

# Repository'leri listele
./ntfy-manager.py list
```

### Event Yönetimi

```bash
# Event'i aç/kapat (toggle)
./ntfy-manager.py toggle my-project build

# Event'i açık olarak ayarla
./ntfy-manager.py toggle my-project deploy --enable

# Event'i kapalı olarak ayarla
./ntfy-manager.py toggle my-project test --disable
```

### Bildirim Gönderme

```bash
# Basit bildirim
./ntfy-manager.py send my-project build "Build successful!"

# Öncelikli bildirim
./ntfy-manager.py send my-project error "Critical error occurred!" --priority urgent

# Mevcut git repository'den otomatik
./ntfy-manager.py send auto deploy "Deployment completed"
```

### Bildirimleri Görüntüleme

```bash
# Tüm bildirimleri görüntüle
./ntfy-manager.py view

# Belirli repository'nin bildirimlerini görüntüle
./ntfy-manager.py view --repo my-project

# Canlı takip (yeni bildirimler geldiğinde göster)
./ntfy-manager.py view --follow
```

## 🎯 Pratik Senaryolar

### CI/CD Pipeline Entegrasyonu

```bash
# GitHub Actions / GitLab CI için
./ntfy-manager.py send auto build "✅ Tests passed"
./ntfy-manager.py send auto deploy "🚀 Deployed to production"
./ntfy-manager.py send auto error "❌ Pipeline failed" --priority high
```

### Git Hooks

```bash
# .git/hooks/post-commit
#!/bin/bash
cd /path/to/ntfy-manager
./ntfy-manager.py send auto commit "New commit: $(git log -1 --pretty=format:'%s')"

# .git/hooks/post-push
#!/bin/bash
cd /path/to/ntfy-manager
./ntfy-manager.py send auto push "Code pushed to $(git branch --show-current)"
```

### Cron Jobs

```bash
# Daily backup notification
0 2 * * * cd /path/to/ntfy-manager && ./ntfy-manager.py send backup-project backup "Daily backup completed"

# System monitoring
*/5 * * * * cd /path/to/ntfy-manager && ./ntfy-manager.py send monitoring health "System check: OK"
```

### Build Scripts

```bash
#!/bin/bash
# build.sh

echo "Building project..."
if npm run build; then
    ./ntfy-manager.py send auto build "✅ Build successful"
else
    ./ntfy-manager.py send auto build "❌ Build failed" --priority high
fi
```

## ⚙️ Gelişmiş Konfigürasyon

### Özel Event'ler Ekleme

Event'ler otomatik oluşturulur, manuel eklemek için JSON'u düzenleyin:

```json
{
  "repositories": {
    "my-project": {
      "events": {
        "security-scan": {
          "enabled": true,
          "priority": "high",
          "title": "Security Scan"
        },
        "performance-test": {
          "enabled": false,
          "priority": "low",
          "title": "Performance Test"
        }
      }
    }
  }
}
```

### ntfy.sh Mobile App Ayarları

1. Uygulamayı indirin ve açın
2. Topic'lerinizi subscribe edin (örn: `dev-my-project`)
3. Bildirim ayarlarını yapılandırın:
   - Öncelik seviyelerine göre ses/titreşim
   - Özel ringtone'lar
   - Sessiz saatler

### Batch İşlemler

```bash
# Birden fazla repository için toplu bildirim
for repo in project1 project2 project3; do
    ./ntfy-manager.py send $repo deploy "Batch deployment completed"
done

# Tüm build event'lerini kapatma
./ntfy-manager.py list | grep -E "^\🔗" | cut -d' ' -f2 | while read repo; do
    ./ntfy-manager.py toggle $repo build --disable
done
```

## 🔒 Güvenlik

### Auth Token Kullanımı

1. ntfy.sh hesabınızda token oluşturun
2. `ntfy-manager.json` dosyasında ayarlayın:

```json
{
  "global_settings": {
    "auth_token": "tk_your_token_here"
  }
}
```

### Self-hosted ntfy Server

```json
{
  "default_server": "your-ntfy-server.com",
  "global_settings": {
    "auth_token": "your_auth_token"
  }
}
```

## 🐛 Troubleshooting

### Yaygın Sorunlar

```bash
# requests kütüphanesi eksik
pip3 install requests

# Permission denied
chmod +x ntfy-manager.py

# Config dosyası bulunamadı
ls -la ntfy-manager.json

# Network bağlantısı test
curl -d "Test message" ntfy.sh/test-topic
```