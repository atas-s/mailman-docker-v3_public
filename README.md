### Mailman v3 docker (adimlarda eksiklikler olabilir & Gelistiriliyor)

0. generate_dockerfile.sh betigini calistirmak en kolayi. Calismazsa 1. adimdan sonrasi izlenebilir
   	- docker ayaga kalktiginda 8. adima gecilebilir
   	- admin onayi alindiktan ve login oldutan sonra default domain'in arayuzden yine de yaratilmasi gerekir
   
2. Docker guncelle
   
  - domain isimleri guncellenmeli

2. DNS/cloudflare guncelle 

3. Docker kur

	apt update; apt install -y docker.io docker-compose git curl docker-buildx docker-cli docker-compose

4. Git için anahtar oluşturup github'a ekle
- ssh-keygen -t ed25519 -C "bisey@domain.com
- cat ~/.ssh/id_ed25519.pub
- github: Profil → Settings > SSH and GPG keys > New SSH key
- Test: ssh -T git@github.com
-  cd /opt
-  git clone git@github.com:atas-s/mailman-docker-v3_public.git
	

5. Dizinleri olustur & nginx config yukle
- cd /opt/mailman-docker
- nano docker-compose.yaml (bu zaten git ile cekilmis durumda)
- mkdir -p /opt/mailman/{core,web,database,postfix,dkim}
- mkdir -p /opt/mailman/nginx/conf.d
- cp mailman.conf /opt/mailman/nginx/conf.d/
- mkdir -p /opt/mailman/run/opendkim	- GEREK YOK GIBI KONTROL
- chown -R 100:100 /opt/mailman/run/opendkim - GEREK YOK GIBI KONTROL
- mkdir -p /opt/mailman/nginx/ssl		- GEREK YOK GIBI KONTROL
- #chown -R 1000:1000 /opt/mailman/core /opt/mailman/web /opt/mailman/database	# Gerekebilir ben yapmadım


6. Docker'i ayaga kaldir
- docker compose up -d	# ilk sefer uzun sürebilir


7. Nginx docker icine alindi. ilk ayaga kalktiginda sorun verecektir. nginx container'i kapatip ssl'i oyle almak gerekiyor;

- certbot certonly --standalone   -d list.domain1.org   --email bisey@domain.com   --agree-tos   --no-eff-email

8. mailman admin sifresi resetle
	- docker exec -it mailman-web bash
	- python manage.py changepassword admin

- Ilk login denemesinde onay maili gonderiyor;
- Onay mail icerigi goruntulemek icin; (url'deki ssl'e dikkat;
	- docker exec -it mailman-postfix mailq
	- docker exec -it mailman-postfix  postcat -vq {{MAILID}}
	

9. opendkim icin
	chmod 755 /opt/mailman/dkim GEREK YOK GIBI KONTROL ??

10. web arayuzden yine de domain tanimlaman gerekli, lmtp boyle guncelleniyor

11. Yardimci komutlar
- Mailq temizle: docker exec -it mailman-postfix postsuper -d ALL
- docker compose up -d --force-recreate postfix
- Mailman dkim eklemesi icin: DMARC Mitigation action: Replace From: with list addres
- ilk ssl alma isi: certbot certonly --standalone   -d list.domain1.org   --email bisey@domain.com   --agree-tos   --no-eff-email
- ssl yenileme test edilmedi: 0 3 * * 5 certbot renew --pre-hook "docker stop mailman-nginx" --post-hook "docker start mailman-nginx" --quiet (crontab)
                              Dmarck Mitigate unconditionally : Yes
- dkim eklemek icn


Host'ta certbot kurulu

- crontab -l:

- 0 3 * * 5 certbot renew --pre-hook "docker stop mailman-nginx" --post-hook "docker start mailman-nginx" --quiet

cp mailman.con /opt/mailman/nginx/conf.d/mailman.conf
