#!/bin/bash

# Renk tanımlamaları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN} Mailman Docker & Nginx Konfigürasyon Çoğaltıcı${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

COMPOSE_FILE="docker-compose.yml"
NGINX_FILE="mailman.conf"
NEW_COMPOSE_FILE="docker-compose_new.yml"
NEW_NGINX_FILE="mailman_new.conf"

# Dosya varlık kontrolleri
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Hata: '$COMPOSE_FILE' dosyası bu dizinde bulunamadı.${NC}"
    exit 1
fi

if [ ! -f "$NGINX_FILE" ]; then
    echo -e "${RED}❌ Hata: '$NGINX_FILE' dosyası bu dizinde bulunamadı.${NC}"
    exit 1
fi

echo -e "${CYAN}🔍 Mevcut dosyalardaki eski değerler okunuyor...${NC}"

# Eski değerleri dosyalardan otomatik oku
OLD_ADMIN_EMAIL=$(grep "MAILMAN_ADMIN_EMAIL=" "$COMPOSE_FILE" | cut -d'=' -f2)
OLD_PG_PASS=$(grep "POSTGRES_PASSWORD=" "$COMPOSE_FILE" | cut -d'=' -f2)
OLD_HK_KEY=$(grep "HYPERKITTY_API_KEY=" "$COMPOSE_FILE" | head -n 1 | cut -d'=' -f2)
OLD_SECRET_KEY=$(grep "SECRET_KEY=" "$COMPOSE_FILE" | cut -d'=' -f2)
OLD_DOMAIN1=$(grep "POSTFIX_myhostname=" "$COMPOSE_FILE" | cut -d'=' -f2)
OLD_NGINX_DOMAIN=$(grep "server_name" "$NGINX_FILE" | head -n 1 | awk '{print $2}' | tr -d ';')

# 🛡️ DÜZELTME: İkincil domaini okurken yorum satırlarını (#) ve boşlukları temizle
RELAY_DOMAINS=$(grep "POSTFIX_relay_domains=" "$COMPOSE_FILE" | cut -d'=' -f2- | cut -d'#' -f1 | tr -d ' ')
OLD_DOMAIN2=$(echo "$RELAY_DOMAINS" | awk -F',' '{print $2}')

echo -e "${GREEN}✅ Eski değerler başarıyla okundu.${NC}"
echo ""
echo -e "${YELLOW}🚀 YENİ DEĞERLERİ GİRİN${NC}"
echo -e "${CYAN}(Hiçbir şey yazmadan Enter'a basarsanız mevcut değer korunur)${NC}"
echo ""

# Yeni değerleri sor (Eskileri parantez içinde göster)
read -p "1. Yeni Ana Domain [$OLD_DOMAIN1]: " NEW_DOMAIN1
NEW_DOMAIN1=${NEW_DOMAIN1:-$OLD_DOMAIN1}

read -p "2. Yeni Nginx/SSL Domain [$OLD_NGINX_DOMAIN]: " NEW_NGINX_DOMAIN
NEW_NGINX_DOMAIN=${NEW_NGINX_DOMAIN:-$OLD_NGINX_DOMAIN}

read -p "3. Yeni Admin E-postası [$OLD_ADMIN_EMAIL]: " NEW_ADMIN_EMAIL
NEW_ADMIN_EMAIL=${NEW_ADMIN_EMAIL:-$OLD_ADMIN_EMAIL}

read -p "4. Yeni PostgreSQL Parolası [$OLD_PG_PASS]: " NEW_PG_PASS
NEW_PG_PASS=${NEW_PG_PASS:-$OLD_PG_PASS}

read -p "5. Yeni Hyperkitty API Key [$OLD_HK_KEY]: " NEW_HK_KEY
NEW_HK_KEY=${NEW_HK_KEY:-$OLD_HK_KEY}

read -p "6. Yeni Mailman Web Secret Key [$OLD_SECRET_KEY]: " NEW_SECRET_KEY
NEW_SECRET_KEY=${NEW_SECRET_KEY:-$OLD_SECRET_KEY}

# 🛡️ DÜZELTME: Varsayılan değer atamasını kaldırdık. Boş geçilirse gerçekten boş kalsın.
read -p "7. Yeni İkincil Domain (Yoksa boş Enter'a basın) [$OLD_DOMAIN2]: " NEW_DOMAIN2

echo ""
echo -e "${GREEN}⏳ Dosyalar kopyalanıyor, düzenleniyor ve temizleniyor...${NC}"

# 1. Docker Compose Dosyasını Kopyala ve İşle
cp "$COMPOSE_FILE" "$NEW_COMPOSE_FILE"

sed -i "s|${OLD_DOMAIN1}|${NEW_DOMAIN1}|g" "$NEW_COMPOSE_FILE"
sed -i "s|${OLD_ADMIN_EMAIL}|${NEW_ADMIN_EMAIL}|g" "$NEW_COMPOSE_FILE"
sed -i "s|${OLD_PG_PASS}|${NEW_PG_PASS}|g" "$NEW_COMPOSE_FILE"
sed -i "s|${OLD_HK_KEY}|${NEW_HK_KEY}|g" "$NEW_COMPOSE_FILE"
sed -i "s|${OLD_SECRET_KEY}|${NEW_SECRET_KEY}|g" "$NEW_COMPOSE_FILE"

# 🛡️ DÜZELTME: İkincil domain değişimi ve silme mantığı
if [ -n "$OLD_DOMAIN2" ]; then
    # Eğer kullanıcı yeni bir domain girdiyse ve bu 'yok' değilse değiştir
    if [ -n "$NEW_DOMAIN2" ] && [ "$NEW_DOMAIN2" != "yok" ]; then
        sed -i "s|${OLD_DOMAIN2}|${NEW_DOMAIN2}|g" "$NEW_COMPOSE_FILE"
    else
        # Kullanıcı boş geçtiyse veya 'yok' yazdıysa, eskisini dosyadan tamamen sil
        # Virgülle ayrılmışsa (relay_domains)
        sed -i "s|,${OLD_DOMAIN2}||g" "$NEW_COMPOSE_FILE"
        # Boşlukla ayrılmışsa (sender_domains)
        sed -i "s| ${OLD_DOMAIN2}||g" "$NEW_COMPOSE_FILE"
    fi
fi

# 2. Nginx Dosyasını Kopyala ve İşle
cp "$NGINX_FILE" "$NEW_NGINX_FILE"

sed -i "s|${OLD_NGINX_DOMAIN}|${NEW_NGINX_DOMAIN}|g" "$NEW_NGINX_FILE"
sed -i "s|${OLD_DOMAIN1}|${NEW_DOMAIN1}|g" "$NEW_NGINX_FILE"

# Windows satır sonu karakterlerini (\r) temizle
sed -i 's/\r$//' "$NEW_COMPOSE_FILE"
sed -i 's/\r$//' "$NEW_NGINX_FILE"

echo -e "${GREEN}✅ Yeni konfigürasyon dosyaları oluşturuldu ve kontrol karakterleri temizlendi.${NC}"
echo ""

# ==============================================================================
# KLASÖR OLUŞTURMA, KOPYALAMA VE BİLGİLENDİRME
# ==============================================================================

# 1. Klasör Oluşturma
echo -e "${YELLOW}📁 Gerekli klasörler (/opt/mailman/...) oluşturulsun mu? [Y/n]:${NC}"
read -p "> " CREATE_DIRS
CREATE_DIRS=${CREATE_DIRS:-Y}

if [[ "$CREATE_DIRS" =~ ^[Yy]$ ]]; then
    mkdir -p /opt/mailman/core \
             /opt/mailman/web \
             /opt/mailman/database \
             /opt/mailman/postfix \
             /opt/mailman/dkim \
             /opt/mailman/nginx/conf.d
    echo -e "${GREEN}✅ Klasörler başarıyla oluşturuldu.${NC}"
else
    echo -e "${CYAN}⏭️ Klasör oluşturma atlandı.${NC}"
fi

# 2. Nginx Conf Kopyalama
echo ""
echo -e "${YELLOW}📄 'mailman_new.conf' dosyası '/opt/mailman/nginx/conf.d/mailman.conf' olarak kopyalansın mı? [Y/n]:${NC}"
read -p "> " COPY_NGINX
COPY_NGINX=${COPY_NGINX:-Y}

if [[ "$COPY_NGINX" =~ ^[Yy]$ ]]; then
    TARGET_NGINX="/opt/mailman/nginx/conf.d/mailman.conf"
    if [ -f "$TARGET_NGINX" ]; then
        mv "$TARGET_NGINX" "/opt/mailman/nginx/conf.d/mailman_bak.conf"
        echo -e "${YELLOW}⚠️ Mevcut dosya 'mailman_bak.conf' olarak yedeklendi.${NC}"
    fi
    cp "$NEW_NGINX_FILE" "$TARGET_NGINX"
    echo -e "${GREEN}✅ Nginx konfigürasyonu hedef dizine kopyalandı.${NC}"
fi

# 3. Docker Compose Kopyalama
echo ""
echo -e "${YELLOW}📄 'docker-compose_new.yml' dosyası '/opt/mailman-docker/docker-compose.yml' olarak kopyalansın mı? [Y/n]:${NC}"
read -p "> " COPY_COMPOSE
COPY_COMPOSE=${COPY_COMPOSE:-Y}

if [[ "$COPY_COMPOSE" =~ ^[Yy]$ ]]; then
    mkdir -p /opt/mailman-docker
    TARGET_COMPOSE="/opt/mailman-docker/docker-compose.yml"
    if [ -f "$TARGET_COMPOSE" ]; then
        mv "$TARGET_COMPOSE" "/opt/mailman-docker/docker-compose_bak.yml"
        echo -e "${YELLOW}⚠️ Mevcut dosya 'docker-compose_bak.yml' olarak yedeklendi.${NC}"
    fi
    cp "$NEW_COMPOSE_FILE" "$TARGET_COMPOSE"
    echo -e "${GREEN}✅ Docker compose dosyası hedef dizine kopyalandı.${NC}"
fi

# 4. Final Bilgilendirme
echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN} 🎉 İŞLEM TAMAMLANDI - SONRASI İÇİN BİLGİLENDİRME${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

echo -e "${CYAN}1️⃣ Konteynerleri Başlatma:${NC}"
echo "   Aşağıdaki komutları sırasıyla çalıştırarak servisleri ayağa kaldırabilirsiniz:"
echo -e "   ${YELLOW}cd /opt/mailman-docker/${NC}"
echo -e "   ${YELLOW}docker compose up -d${NC}"
echo ""

echo -e "${CYAN}2️⃣ SSL Sertifikası Alma (Certbot):${NC}"
echo -e "   ${RED}⚠️ DİKKAT:${NC} Certbot 'standalone' modu 80. portu kullanır."
echo "   Bu nedenle işlemi yapmadan önce Nginx'in durdurulması ZORUNLUDUR."
echo ""
echo "   Nginx'i durdurmak için:"
echo -e "   ${YELLOW}docker stop mailman-nginx${NC}"
echo "   (Veya tüm stack'i 'cd /opt/mailman-docker && docker compose down' ile kapatabilirsiniz)"
echo ""
echo "   Nginx durduktan sonra aşağıdaki komutla SSL alabilirsiniz:"
echo -e "   ${YELLOW}certbot certonly --standalone -d ${NEW_NGINX_DOMAIN} --email ${NEW_ADMIN_EMAIL} --agree-tos --no-eff-email${NC}"
echo ""

echo -e "${CYAN}3️⃣ Nginx'i Tekrar Başlatma:${NC}"
echo "   SSL sertifikası başarıyla alındıktan sonra Nginx'i tekrar başlatabilirsiniz:"
echo -e "   ${YELLOW}docker start mailman-nginx${NC}"
echo "   (Veya 'cd /opt/mailman-docker && docker compose up -d' ile tüm stack'i başlatabilirsiniz)"
echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN} Başarılar dilerim! 🚀${NC}"
echo -e "${GREEN}==================================================${NC}"
