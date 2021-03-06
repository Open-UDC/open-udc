---
title: OpenUDC
subtitle: Protocoles d'authentification et système monétaire universels
author: "Jbar"
docref: NSPtNCtW
lang: fr-FR
#toc: visible
revision: 2020-03-23
colorlinks: true
geometry: 'left=5cm, right=1cm, top=3.1cm, bottom=0cm, footskip=2cm, landscape'
mainfont: 'DejaVu Sans'
mainfontoptions: 'Scale=1.4'
linestretch: 1.8
sectionbreak: '\vspace*{\fill} \clearpage \vspace*{\fill}'
---

# Inspirateurs et Contributeurs

## Sociologie, Économie

* Charles Fourier (1772-1837)
* Louis Even (1885 - 1974)
* Maurice Allais (1911 - 2010)
* ... et bien d'autres.

## Science fondamental

* Giordano Bruno (1548-1600) & Galileo Galilei (1564-1642)
* Albert Einstein (1879 - 1955)
* ... et quelques autres.

## Pionniers de l'informatique

* Alan Turing (1912 - 1954)
* Dennis Ritchie (1941 - 2011)
* ... et quelques autres.

## Bâtisseurs de la noosphère numérique

* Philip Zimmermann (1954 -)
* Werner Koch (1961 -)
* Linus Torvald (1969 -)
* Satoshi Nakamoto (?)
* ... et bien d'autres.

## Disciples de la liberté

* Richard Stallman (1953 -)
* Stéphane Laborde (1969 -)

## Mais aussi

* Plusieurs "jeunes" qui souhaitent peut-être garder un peu d'anonymat.

# Problème

* Inégalités monétaire, temporelle et spatiale *"on vit mieux près du robinet"*
* Cercle vicieux qui engendre jalousies et frustrations
* Bullshit jobs, servage moderne, délocalisation.
* Violences, troubles sociaux, guerres.

#  Environnement

* Internet
* Ordiphones
* Dématérialisation des échanges
* Globalisation

# Première solution : bitcoin

## Avantages

* Décentralisé
* Simplicité
* Fiabilité & solidité
* Taille et contenu des donnés plutôt bien maîtrisés
* Relativement anonyme


## Inconvénients

* Création monétaire complètement asymétrique
* Complètement étranger à la notion d'individus
* Preuve de travail
* Limitations particulièrement contraignantes (block/jour & transactions/block)
* Non utilisable comme moyen de paiement global
* Relativement anonyme

![taille de la blockchain bitcoin](bitcoin_blockchain_size){.center}


# Autres solutions existantes

## Etherum, XRP, etc.

|Nom|Prix|Market Cap|Volume 24h|Quantité crée|Création monétaire|
|---|---|---|---|---|---|
|Bitcoin (BTC)|€6 136.87|€112.22B|€40.46B|18.29M BTC| minage POW|
|Ethereum (ETH)|€125.24|€13.81B|€12.13B|110.25M ETH | minage POW/POS|
|Ripple (XRP)|€0.148299|€6.51B|€1.92B|43.91B XRP | [??](https://ripple.com/files/ripple_consensus_whitepaper.pdf)|
|Tether (USDT)|€0.920933|€4.28B|€47.47B|4.64B USDT | ICO|
|Bitcoin Cash (BCH)|€203.42|€3.73B|€3.18B|18.35M BCH | minage POW|
|Bitcoin SV (BSV)|€158.36|€2.91B|€2.35B|18.35M BSV | minage POW|
|Litecoin( LTC)|€36.11|€2.32B|€2.88B|64.36M LTC | minage POW|
|EOS (EOS)|€2.12|€1.95B|€2.42B|921.24M EOS | [DPOS](https://steemit.com/dpos/@dantheman/dpos-consensus-algorithm-this-missing-white-paper)|
|Binance Coin (BNB)|€11.34|€1.76B|€263.16M|155.54M BNB | [ICO + Magic](https://www.binance.com/resources/ico/Binance_WhitePaper_en.pdf)|
|Tezos (XTZ)|€1.59|€1.12B|€127.32M|704.90M XTZ| [??](https://tezos.com/static/white_paper-2dc8c02267a8fb86bd67a108199441bf.pdf)|

*À la date du 25 mars 2020, cf. [coinmarketcap.com](https://coinmarketcap.com/)*

---

## Duniter, ĝune.

### Avantages

* Validation complètement décentralisé (P2P)
* Authentification décentralisé (toile de confiance)
* Création monétaire possiblement symétrique dans l'espace et dans le temps
* Communautés [développeurs](https://duniter.org/fr/contribuer/) et [utilisateurs](https://www.gchange.fr/) actives

### Inconvénients

* Limitations contraignantes (max ~100k individus pour une utilisation courante)
* Preuve de travail
* Fiabilité et solidité à prouver
* Peu d'interopérabilité avec d'autres technologies existantes

# [OpenUDC](https://openudc.org)

## Objectifs

Établir un standard :

* Complètement décentralisé
* Fiable & solide
* Si possible interopérable
* Le plus simple possible (DRY KISS)
* Création monétaire basé sur les individus, entièrement symétrique
* Adressable pour une utilisation courante à l'ensemble de la population mondiale
* Pouvant se substituer à toutes monnaies à cours légaux
* Ne nécessitant pas d'infrastructure couteuse, nœuds pouvant tourner sur des [Raspberry Pi](https://www.raspberrypi.org/products/raspberry-pi-4-case/) ou autres [FreedomBox](https://freedombox.org/#get).

## 1er challenge : Authentification des individus

### [Passeports biométriques](https://en.wikipedia.org/wiki/Biometric_passport)

* Largement déployés et utilisés
* Documentation technique et terminaux de lecture relativement confidentiels
* Centralisé : type LDAP, [~250 master keys](https://www.icao.int/Security/FAL/PKD/Pages/icao-master-list.aspx)
* Peut-il évoluer, comment ?
* PKI incomplète : pas de clés privées\*, juste des données personnelles signées

*\* Cet absence pourrait être comblé [grâce à GnuPG](https://wiki.gnupg.org/LDAPKeyserver)*

### [WebAuthn](https://en.wikipedia.org/wiki/WebAuthn)

* Très récent : 4 Mars 2019
* Jetons cryptographiques déjà commercialisés
* Seulement un standard d'authentification web
* PKI, comment récupérer les clés publiques de confiance : non spécifié
* Peut-il évoluer, comment ?

### [toile de confiance](https://en.wikipedia.org/wiki/Web_of_trust) [OpenPGP](https://www.openpgp.org/)

* Authentification décentralisé
* Éprouvé et évolutif
* Largement déployé et utilisé
* Jetons cryptographiques USB ou NFC (ex: [YubiKey](https://www.yubico.com/), [Nitrokey](https://www.nitrokey.com/))
* Plusieurs utilisations possibles : authentification, signature, chiffrement
* Standard ouvert, implémentations libres (ex: [GnuPG](https://gnupg.org/))
* Supporte de nombreux algorithmes de hachage et de cryptographie
* Problèmes avec les serveurs de clés précédemment déployés : trop permissifs et trop transparents
* Certificats évolutifs indexés par leur fingerprint (20 octets).

## Utilisation d\'OpenPGP

### certificat

Y mettre des informations permettant d'identifier chacun de manière unique : nom, prénom, date de naissance et lieu de naissance.
Le format de ces information est spécifié par l'[udid2](https://github.com/Open-UDC/open-udc/blob/master/docs/rfc/OpenUDC_Authentication_Mechanisms.draft.txt).

Notons que dans un certificat OpenPGP, on peut éventuellement stocker sa photo d'identité ou ses données biométriques

### toile de confiance

Les "key signing party" sont trop contraignantes et compliquées pour la plupart.

Heureusement, aujourd'hui tout le monde possède désormais un ordiphone, dont les applications peuvent accéder à la plupart de nos contacts.

La validation des certificats d'autrui peut donc se faire aisément via une application comme [OpenKeychain](https://www.openkeychain.org/) (à améliorer pour qu'elle réponde aux contraintes OpenUDC)

### stockage des certificats (serveurs de clés)

Ces serveurs de stockage étaient le maillon faible de l'écosystème OpenPGP. Trop permissive, la génération précédente (SKS key servers) n'a pas vraiment survécue à une attaque triviale (Envoi massif de fausses informations). De plus ces serveurs étaient trop transparents au vu de la [RGPD](https://en.wikipedia.org/wiki/General_Data_Protection_Regulation).

De nouveaux serveurs de clés sont actuellement en développement, il faudrait sans doute en développer également pour les besoins spécifiques OpenUDC.

## Le protocole OpenUDC

### [bloc de paramètres (& creation monétaire)](https://github.com/Open-UDC/open-udc/blob/master/docs/rfc/OpenUDC_exchange_formats.draft.txt)

Blocs d'informations chainés (blockchain) dont la validation se fait par des preuves d'identité (proof-of-identity) établies au travers de la toile de confiance. Ceux ci comprennent :

* la version du protocole, afin de pouvoir le faire évoluer
* le différentiel des clés (fingerprint) adressables, ainsi que celui de leur type
* la quantité de nouvelle monnaie allouée à chacune des clés identifiées (par leur type) comme étant unique pour un unique individu considéré comme vivant (actif et non déclaré mort)

Les informations contenues dans ces blocs sont établies en fonction de l'évolution de la toile de confiance et des choix de gouvernance monétaire. Cette gouvernance peut-être :

* manuelle : un type de clé est dédié pour designer les "administrateurs" qui pourront créer le prochain bloc.
* automatique : tout est entièrement calculé à partir de paramètres pré établis et des données de la toile de confiance

### transactions

L'ensemble de la masse monétaire est repartie en quantités de valeur
indivisible, appelés grains. Comparables à des pièces et billets, chacun de ces
grains sont eux-mêmes des chaines de blocs ultra légères.

Chacune de ces chaines pouvant être maintenues indépendamment, le protocole
OpenUDC ne démontre, contrairement à la plupart des autres solutions, quasiment
aucune limite d'utilisateurs journaliers.

### validations

La chaine de blocs de paramètres tout comme celle des grains sont maintenus par
des nœuds, qui se contentent d'enregistrer les nouveaux blocs valides et de
stocker et servir les chaines complètes.

Chaque nœud est lui même authentifié comme appartenant à un humain, et chaque humain
ne peut intégrer au réseau qu'un seul nœud pour chaque grain.

### double dépense

Lorsque qu'un fork de grain est détecté:

* l'incident est reporté et stocké.
* la clé à l'origine du fork est marqué comme corrompu jusqu'à nouvel ordre,
  comparable à un blocage de compte.
* les nœuds réalisent entre eux une procédure autonome de vote pour déterminer
  quel fork choisir.

Lors du prochain bloc de paramètres la situation devra être éclairci, et le
marquage pourra être effacé ou confirmé.

Suivant la gravité de l'incident, si il y a volonté de nuire par exemple, le
bloc de paramètre pourra sanctionner davantage : jusqu'au rejet de plusieurs
comptes, ou à l'exclusion de plusieurs individus.

Souvenez vous : "Preuve d'Identité".

## plan de financement

 Il nous faut encore un certain effort, cad du financement traditionnel, afin de
passer à l'étape suivante du financement participatif et de la transition
monétaire.

 Le financement participatif permettra d'établir et de partager la masse
monétaire initiale, qui déterminera la création monétaire par dividende
universel (= micro pourcentage de la masse monétaire précédente).

 Contre une participation dans une monnaie donné, sera crée pour chaque donateur
une quantité correspondante de cryptomonnaie, et fournit une quantité définie de
biens et services.

 Une fois la(les) campagne(s) de crowndfunding terminée(s) nous aurons une masse
monétaire initiale.

 Par exemple (en Euros):

 *    64 € -> 64 uc + T-shirt
 *   256 € -> 256 uc + Polo
 *  1024 € -> 1024 uc + T-shirt + Polo + 2 tocken sécurisé
 *  4096 € -> 4096 uc + $ans + quelque chose en plus
 *  8000 € -> 8192 uc + ...
 * 15500 € ou 15800 € -> 16384 uc + ...
 * 30000 € ou 31000 € -> 32768 uc + ...
 * 50000 € ou 60000 € -> 65536 uc + ...

 Faire des remises plus importantes pour les grosses participations risque à la
fois d'être juteux, mais de franchir l'innaceptable-inéquitable : "les riches
(en €) sont encore privilégiés"..., "Pay-To-Win"...  C'est pourquoi que préfère
la remise de 2.34% entre 4096 et 8192, puis 3.56% puis 5.4% puis 8.45% au max.

 Enfin faire le maximum pour gagner la confiance des donateurs

 Point important pour satisfaire les gros donateurs (i.e. les spéculateurs) : on
s'engage sur une règle plutôt déflationniste pendant une période donnée (disons
4 ans) après le lancement de cette monnaie.

 Une règle "déflationniste" devra être bien inférieure aux 9%/an calculé par la
TRM (en fonction de l'espérance de vie, cf.: http://openudc.org/faq_en.php)

 Enfin, dans un souci d'égalité, un plafonnement par personne devrait être mis
en place.

