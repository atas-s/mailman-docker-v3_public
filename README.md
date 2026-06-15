# mailman v3 docker

Aşağıdaki yerler değiştirilmeli; 

 - COK-GIZLI-HYPERKITTY_API_KE
  
 - Beni-Degistirmeyi-Unutma
  
  - COK-Secret-KEY-Degistirmeyi-Unutma
  
 - admin@birinindomaini.com

Host'ta certbot kurulu

- crontab -l:

- 0 3 * * 5 certbot renew --pre-hook "docker stop mailman-nginx" --post-hook "docker start mailman-nginx" --quiet

cp mailman.con /opt/mailman/nginx/conf.d/mailman.conf
