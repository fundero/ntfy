#!/usr/bin/env python3
"""
ntfy.sh Notification Manager
Pratik repository ve event bazlı bildirim yönetimi
"""

import json
import os
import subprocess
import sys
import argparse
import requests
from pathlib import Path
from typing import Dict, Any, Optional

class NtfyManager:
    def __init__(self, config_path: str = "ntfy-manager.json"):
        self.config_path = config_path
        self.config = self.load_config()
        
    def load_config(self) -> Dict[str, Any]:
        """Konfigürasyon dosyasını yükle"""
        if not os.path.exists(self.config_path):
            print(f"❌ Konfigürasyon dosyası bulunamadı: {self.config_path}")
            sys.exit(1)
        
        with open(self.config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def save_config(self):
        """Konfigürasyonu dosyaya kaydet"""
        with open(self.config_path, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, indent=2, ensure_ascii=False)
    
    def get_current_repo(self) -> Optional[str]:
        """Mevcut git repository adını al"""
        try:
            result = subprocess.run(
                ['git', 'rev-parse', '--show-toplevel'],
                capture_output=True, text=True, check=True
            )
            repo_path = result.stdout.strip()
            return os.path.basename(repo_path)
        except subprocess.CalledProcessError:
            return None
    
    def add_repository(self, repo_name: str, topic: str = None, is_private: bool = False):
        """Yeni repository ekle"""
        if topic is None:
            # Private repo'lar için güvenli topic isimleri
            if is_private:
                import hashlib
                safe_name = hashlib.md5(repo_name.encode()).hexdigest()[:8]
                topic = f"{self.config['default_topic_prefix']}-{safe_name}"
            else:
                topic = f"{self.config['default_topic_prefix']}-{repo_name}"
        
        self.config['repositories'][repo_name] = {
            "topic": topic,
            "is_private": is_private,
            "events": {
                "build": {"enabled": True, "priority": "default", "title": "Build Status"},
                "deploy": {"enabled": True, "priority": "high", "title": "Deployment"},
                "test": {"enabled": False, "priority": "low", "title": "Test Results"},
                "error": {"enabled": True, "priority": "urgent", "title": "Error Alert"}
            }
        }
        self.save_config()
        print(f"✅ Repository '{repo_name}' eklendi (topic: {topic})")
    
    def toggle_event(self, repo_name: str, event: str, enabled: bool = None):
        """Event'i aç/kapat"""
        if repo_name not in self.config['repositories']:
            print(f"❌ Repository '{repo_name}' bulunamadı")
            return
        
        repo_config = self.config['repositories'][repo_name]
        
        if event not in repo_config['events']:
            # Yeni event ekle
            repo_config['events'][event] = {
                "enabled": True if enabled is None else enabled,
                "priority": "default",
                "title": event.title()
            }
        else:
            # Mevcut event'i toggle et
            if enabled is None:
                repo_config['events'][event]['enabled'] = not repo_config['events'][event]['enabled']
            else:
                repo_config['events'][event]['enabled'] = enabled
        
        self.save_config()
        status = "açıldı" if repo_config['events'][event]['enabled'] else "kapatıldı"
        print(f"✅ {repo_name}/{event} {status}")
    
    def send_notification(self, repo_name: str, event: str, message: str, priority: str = None):
        """Bildirim gönder"""
        if repo_name not in self.config['repositories']:
            print(f"❌ Repository '{repo_name}' bulunamadı")
            return False
        
        repo_config = self.config['repositories'][repo_name]
        
        if event not in repo_config['events']:
            print(f"❌ Event '{event}' tanımlanmamış")
            return False
        
        event_config = repo_config['events'][event]
        if not event_config['enabled']:
            print(f"⏭️  {repo_name}/{event} kapalı - bildirim gönderilmedi")
            return False
        
        # Bildirim parametrelerini hazırla
        server = self.config['default_server']
        topic = repo_config['topic']
        title = event_config['title']
        priority = priority or event_config.get('priority', 'default')
        
        url = f"https://{server}/{topic}"
        
        # Private repo için başlığı gizle
        display_name = repo_name
        if repo_config.get('is_private', False):
            display_name = f"Private-{repo_config['topic'].split('-')[-1]}"
        
        headers = {
            'Title': f"{title} - {display_name}",
            'Priority': priority,
            'Tags': event
        }
        
        # Auth token varsa ekle
        auth_token = self.config['global_settings'].get('auth_token')
        if auth_token:
            headers['Authorization'] = f"Bearer {auth_token}"
        
        try:
            response = requests.post(url, data=message, headers=headers)
            if response.status_code == 200:
                print(f"✅ Bildirim gönderildi: {repo_name}/{event}")
                return True
            else:
                print(f"❌ Bildirim gönderilemedi: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Hata: {e}")
            return False
    
    def list_repositories(self):
        """Repository'leri listele"""
        print("📋 Kayıtlı Repository'ler:")
        for repo_name, config in self.config['repositories'].items():
            print(f"\n🔗 {repo_name} (topic: {config['topic']})")
            for event, event_config in config['events'].items():
                status = "✅" if event_config['enabled'] else "❌"
                priority = event_config['priority']
                print(f"  {status} {event} (priority: {priority})")
    
    def view_notifications(self, repo_name: str = None, follow: bool = False):
        """Bildirimleri görüntüle"""
        if repo_name and repo_name not in self.config['repositories']:
            print(f"❌ Repository '{repo_name}' bulunamadı")
            return
        
        if repo_name:
            topic = self.config['repositories'][repo_name]['topic']
            topics = [topic]
        else:
            # Tüm repository'lerin topic'lerini al
            topics = [config['topic'] for config in self.config['repositories'].values()]
        
        server = self.config['default_server']
        
        for topic in topics:
            url = f"https://{server}/{topic}/json"
            if follow:
                url += "?poll=1"
            
            print(f"📱 {topic} bildirimleri:")
            try:
                response = requests.get(url, stream=follow)
                if follow:
                    for line in response.iter_lines():
                        if line:
                            data = json.loads(line)
                            print(f"  [{data.get('time', '')}] {data.get('message', '')}")
                else:
                    notifications = response.json()
                    if isinstance(notifications, list):
                        for notif in notifications[-5:]:  # Son 5 bildirim
                            print(f"  [{notif.get('time', '')}] {notif.get('message', '')}")
            except Exception as e:
                print(f"❌ {topic} bildirimleri alınamadı: {e}")

def main():
    parser = argparse.ArgumentParser(description='ntfy.sh Notification Manager')
    parser.add_argument('--config', default='ntfy-manager.json', help='Konfigürasyon dosyası')
    
    subparsers = parser.add_subparsers(dest='command', help='Komutlar')
    
    # Repository ekle
    add_parser = subparsers.add_parser('add-repo', help='Repository ekle')
    add_parser.add_argument('name', help='Repository adı')
    add_parser.add_argument('--topic', help='ntfy topic (opsiyonel)')
    add_parser.add_argument('--private', action='store_true', help='Private repository (güvenli topic kullanır)')
    
    # Event toggle
    toggle_parser = subparsers.add_parser('toggle', help='Event aç/kapat')
    toggle_parser.add_argument('repo', help='Repository adı')
    toggle_parser.add_argument('event', help='Event adı')
    toggle_parser.add_argument('--enable', action='store_true', help='Açık olarak ayarla')
    toggle_parser.add_argument('--disable', action='store_true', help='Kapalı olarak ayarla')
    
    # Bildirim gönder
    send_parser = subparsers.add_parser('send', help='Bildirim gönder')
    send_parser.add_argument('repo', help='Repository adı (veya "auto" mevcut repo için)')
    send_parser.add_argument('event', help='Event adı')
    send_parser.add_argument('message', help='Bildirim mesajı')
    send_parser.add_argument('--priority', help='Öncelik (low, default, high, urgent)')
    
    # Repository listele
    subparsers.add_parser('list', help='Repository\'leri listele')
    
    # Bildirimleri görüntüle
    view_parser = subparsers.add_parser('view', help='Bildirimleri görüntüle')
    view_parser.add_argument('--repo', help='Belirli repository')
    view_parser.add_argument('--follow', action='store_true', help='Canlı takip et')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    manager = NtfyManager(args.config)
    
    if args.command == 'add-repo':
        manager.add_repository(args.name, args.topic, args.private)
    
    elif args.command == 'toggle':
        enabled = None
        if args.enable:
            enabled = True
        elif args.disable:
            enabled = False
        manager.toggle_event(args.repo, args.event, enabled)
    
    elif args.command == 'send':
        repo_name = args.repo
        if repo_name == 'auto':
            repo_name = manager.get_current_repo()
            if not repo_name:
                print("❌ Git repository bulunamadı")
                return
        manager.send_notification(repo_name, args.event, args.message, args.priority)
    
    elif args.command == 'list':
        manager.list_repositories()
    
    elif args.command == 'view':
        manager.view_notifications(args.repo, args.follow)

if __name__ == '__main__':
    main()