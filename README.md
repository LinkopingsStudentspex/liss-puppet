# liss-puppet

Det här repot definierar konfigurationen för LiSS nya server via Puppet. I nuläget applicerar vi den standalone, utan någon master-server.

Tredjepartsmoduler från Puppet Forge deklareras i `Puppetfile` och hanteras via r10k.

Inspiration har tagits från Holgerspexets puppetkonfiguration (https://github.com/holgerspexet/holger-puppet)

## Förutsättningar
Konfigurationen är bara testad på Ubuntu 18.04. För att kunna applicera konfigurationen behöver följande paket vara installerade på systemet:
  * `puppet`
  * `r10k`
  * `hiera-eyaml`

# Användning
## Installation
För att installera klonar man repot till `/etc/puppet/code` på servern (det ska ligga direkt i den mappen, inte i någon undermapp) och kör skriptet `update.sh`. Skriptet installerar tredjepartsmoduler via r10k och applicerar sedan konfigurationen via `puppet apply`.

## Automatisk applicering
Efter att `update.sh` har körts en första gång så körs ett cron-jobb som gör en git pull och kör om update-skriptet varje timme för att motverka configuration drift.

## Struktur
Konfigurationen är uppbyggd av ett antal moduler. De ligger i mappen `site-modules` för att skilja dem från tredjepartsmoduler som hanteras av r10k i `modules`.

## Känsliga uppgifter
Känsliga uppgifter som lösenord lagras krypterat via hiera-eyaml i filen `data/secrets.eyaml`. Den publika krypteringsnyckeln lagras i repot i `keys/public_key.pkcs7.pem` vilket gör att alla kan kryptera nya lösenord, men endast servern har den privata nyckeln och kan avkryptera dem.

