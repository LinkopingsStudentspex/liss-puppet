# Instruktioner när allt gått åt pipan

Det här dokumentet innehåller instruktioner för hur man får igång spexets server från backups (eller från grunden) igen efter att något katastrofalt har skett.

Det ska hållas uppdaterat vid förändringar i konfigurationen och instruktionerna bör testas regelbundet på en testserver.

## Förutsättningar
Du behöver följande:
  * En server som kör Ubuntu 18.04 LTS, virtuell eller fysisk, samt root-åtkomst till denna.
  * Tillgång till DNS-inställningar för studentspex.se.
  * Färska backups av databaserna:
    * wikidb (mysql)
    * django (postgres)
    * keycloak (postgres)
  * Backup av filerna för wikin.
  * Om möjligt: privata nyckeln för hiera-eyaml för att kunna läsa och använda de krypterade lösenorden i git-repot.

Databasbackuperna är krypterade med GPG, och kan endast dekrypteras av den vars publika nyckel användes vid krypteringen.
Enklast är att be någon som kan tänkas ha denna nyckel att dekryptera backuperna åt dig och ladda upp dem direkt på servern.

## Installation

Installera nödvändiga paket:
```
apt install puppet hiera-eyaml r10k
```

Klona ner puppet-konfigurationen från detta repo till `/etc/puppet/code`:
```
git clone https://github.com/LinkopingsStudentspex/liss-puppet.git /etc/puppet/code
```

## Nycklar
### Hiera-eyaml
Någon gammal IT-kunnig i spexet borde ha en kopia av den privata nyckeln för hiera-eyaml lagrad på en säker plats. Kopiera den till `/etc/puppet/code/keys/private_key.pkcs7.pem`. 

Om nyckeln inte går att få tag på så måste ett nytt nyckelpar genereras, och nya lösenord måste genereras i `/etc/puppet/code/data/secrets.eyaml`. Glöm inte att committa nya publika nyckeln till git.

### GPG för backup
För att kryptering av automatiska backups ska funka behöver du importera en publik GPG-nyckel för den som ska kunna dekryptera dem.
Nyckeln ska importeras hos `root`-användaren, eftersom det är den som krypterar backuperna. Se till att GPG litar fullt ut på denna nyckel, annars kommer backupjobbet stanna mitt i natten och fråga om du litar på nyckeln.

Om du inte får tag på nyckeln som använts tidigare, välj någon som ska ha rättighet att dekryptera backuperna och lägg till deras publika nyckel. Du behöver också ändra så att mottagarens GPG-userID står i `/etc/puppet/code/data/secrets.eyaml` under `backup::recipient`. 

## Applicera konfigurationen

Kör skriptet som installerar puppet-moduler och tillämpar konfigurationen (som `root`):
```
cd /etc/puppet/code
update.sh
```

Det kan faila på några punkter första gången man kör, men kör ett par gånger till så brukar det lösa sig.

Det som inte verkar ske korrekt när man kör för första gången är migreringen av djangos databas och hanteringen av statiska filer, så det får man göra själv en gång (som `www-data`):
```
cd /opt/internsidor/src
source ../venv/bin/activate
python manage.py migrate --settings=internsidor.settings.production
python manage.py collectstatic --settings=internsidor.settings.production
```

## Återställ databaser från backup
Stoppa först alla tjänster som försöker komma åt databaserna:
```
systemctl stop internsidor-gunicorn
systemctl stop lissmilter
systemctl stop recipient-lookup
systemctl stop keycloak
```

Droppa och återställ postgres-databaserna:
```
su postgres
dropdb django
dropdb keycloak
pg_restore -C -d postgres {dumpfilen för django}
pg_restore -C -d postgres {dumpfilen för keycloak}
exit
```

Droppa och återställ mysql-databasen:
```
mysql -u root -e 'drop database wikidb;'
mysql -u root -e 'create database wikidb;'
mysql -u root wikidb < {dumpfilen för wikidb}
```

Kör om puppet för att sätta rättigheter på databaserna, för att korrigera eventuella skillnader i inställningar mellan backupen och puppet, och för att starta tjänsterna igen:
```
cd /etc/puppet/code
update.sh
```

Kör uppdateringsskript för MediaWiki:
```
cd /var/www/mediawiki/maintenance
php rebuildLocalisationCache.php
php update.php
```

## Återställ wikins filer
Filerna som folk har laddat upp till wikin hör hemma i `/var/www/mediawiki/images`. Kopiera filerna från backupen dit, så borde allting förhoppningsvis hittas korrekt.

## Övrigt

### Inkommande e-post
Om du återställer till en server som inte ligger hos lysator eller LiU-IT så behöver du ändra MX-posterna för studentspex.se så att mailen kommer fram.

Om den nya servern ligger hos Lysator men har fått ett nytt hostname så behöver man peka om SUNET:s mailfilter så att inkommande epost routas till den nya servern. Hör av dig till LiU-IT så finns det nog någon där som kan göra detta åt dig.

# Hjälp
Om det inte längre finns några i LiSS som kan hjälpa dig med detta så finns det ett par ställen du kanske kan hitta assistans:
  * Holgerspexet använder också Puppet för sina system, och deras disaster-management-rutiner var en inspiration för detta dokument.
  * Lysator kanske också kan hjälpa dig om du är snäll och erbjuder fika.