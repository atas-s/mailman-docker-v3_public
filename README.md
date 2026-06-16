### Mailman v3 docker (adimlarda eksiklikler olabilir & Gelistiriliyor)

0. generate_dockerfile.sh betigini calistirmak en kolayi. Calismazsa 1. adimdan sonrasi izlenebilir
   	- docker ayaga kalktiginda 8. adima gecilebilir
   	- admin onayi alindiktan ve login olduktan sonra default iligli domain arayuzden yine de yaratilmalidir.
   
1. Docker guncelle
   
  - Domain isimleri guncellenmeli
  - Parolalar guncellenmeli

2. DNS guncellemesi yapilmali (MX, SPF, DKIM, DMARC)

3. Gerekli paketleri kur

	apt update; apt install -y docker.io docker-compose git curl docker-buildx docker-cli docker-compose

4. Git ile projeyi cek
	-  git clone git@github.com:atas-s/mailman-docker-v3_public.git
	

5. Dizinleri olustur & nginx config yukle
	- cd /opt/mailman-docker
	- nano docker-compose.yaml (bu zaten git ile cekilmis durumda)
	- mkdir -p /opt/mailman/{core,web,database,postfix,dkim}
	- mkdir -p /opt/mailman/nginx/conf.d
	- cp mailman.conf /opt/mailman/nginx/conf.d/

6. Docker'i ayaga kaldir
	- cd /opt/mailman-docker
	- docker compose up -d	# ilk sefer uzun sürebilir


7. Nginx ilk ayaga kalktiginda sorun verecektir. nginx container'i kapatip ssl'i oyle almak gerekiyor;
	- cd /opt/mailman-docker && docker compose down
	- certbot certonly --standalone   -d list.domain1.org   --email bisey@domain.com   --agree-tos   --no-eff-email

8. mailman admin sifresi resetle 
	- docker exec -it mailman-web bash
	- python manage.py changepassword admin
 - Not: web arayuzden login olmadan onay e-postasi cikmiyor

- Ilk login denemesinde onay maili gonderiyor;
- Onay mail icerigi goruntulemek icin; (url'deki ssl'e dikkat);
	- docker exec -it mailman-postfix mailq
	- docker exec -it mailman-postfix  postcat -vq {{MAILID}}
	
9. Web arayuzden mutlaka domain tanimlaman gerekli, lmtp boyle guncelleniyor.

## Yardimci komutlar
- Mailq temizle: docker exec -it mailman-postfix postsuper -d ALL
- docker compose up -d --force-recreate postfix
- Mailman dkim eklemesi icin: DMARC Mitigation action: Replace From: with list addres
- ilk ssl alma isi: certbot certonly --standalone   -d list.domain1.org   --email bisey@domain.com   --agree-tos   --no-eff-email
- ssl yenileme test edilmedi: 0 3 * * 5 certbot renew --pre-hook "docker stop mailman-nginx" --post-hook "docker start mailman-nginx" --quiet (crontab)
                              Dmarck Mitigate unconditionally : Yes
- dkim eklemek icn


## Nginx SSL 
- SSL isleri host'a kurulu olan certbot ile cozuluyor. Docker compose dosyasinda ilgili volume tanimli

- crontab -l:

- 0 3 * * 5 certbot renew --pre-hook "docker stop mailman-nginx" --post-hook "docker start mailman-nginx" --quiet

cp mailman.con /opt/mailman/nginx/conf.d/mailman.conf
