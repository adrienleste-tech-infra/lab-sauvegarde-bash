# 🗄️ Lab — Sauvegarde automatisée d'un serveur web en Bash

## 📋 Contexte

L'entreprise fictive **TechNova** héberge ses applications web (dont un GLPI) sur un serveur Debian 12. Aucune sauvegarde automatisée n'existe : une panne disque ou une erreur de manipulation ferait perdre toutes les données.

**Mission :** écrire un script Bash qui sauvegarde `/var/www` chaque nuit, signale son succès ou son échec, conserve 7 jours d'historique, et **prouver que la restauration fonctionne**.

## 🖥️ Environnement

| Élément | Détail |
|---|---|
| Hyperviseur | VMware Workstation |
| Serveur | Debian 12 (`srv-debian`) |
| Données sauvegardées | `/var/www` (GLPI + html) |
| Outils | Bash, tar, gzip, find, cron, diff, Git |

## ⚙️ Le script

```bash
#!/bin/bash
SOURCE="/var/www"
DESTINATION="/home/adri/sauvegardes"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
RETENTION=7
mkdir -p "$DESTINATION"
tar -czf "$DESTINATION/backup_www_$DATE.tar.gz" "$SOURCE"
if [ $? -eq 0 ]; then
    echo "Sauvegarde réussie : backup_www_$DATE.tar.gz"
    find "$DESTINATION" -name "backup_www_*.tar.gz" -mtime +$RETENTION -delete
else
    echo "ERREUR : la sauvegarde a échoué"
fi
```

| Élément | Rôle |
|---|---|
| Variables | Chemins et durée de conservation définis à un seul endroit |
| `date` | Horodatage unique : aucune sauvegarde n'écrase la précédente |
| `tar -czf` | Regroupe et compresse `/var/www` en une seule archive |
| `$?` | Code retour de `tar` : 0 = succès, autre valeur = échec |
| `find ... -mtime +7 -delete` | Rotation : supprime les archives de plus de 7 jours |

**Choix de conception :** la rotation n'est exécutée **que si la sauvegarde a réussi**. Si les sauvegardes échouaient plusieurs nuits de suite, une suppression systématique finirait par effacer toutes les copies valides.

## ⏰ Planification (cron)

```
0 2 * * * /home/adri/lab-sauvegarde-bash/sauvegarde_web.sh >> /home/adri/sauvegarde.log 2>&1
```
- Exécution **chaque nuit à 2h00**
- Messages et erreurs enregistrés dans un **journal** (`sauvegarde.log`), cron n'ayant pas d'écran

## ✅ Tests réalisés

### 1. Sauvegarde nominale
Exécutions successives → archives de 61 Mo horodatées à la seconde, **aucun écrasement**.

### 2. Test d'échec volontaire
Source remplacée par un dossier inexistant → `ERREUR : la sauvegarde a échoué`.
⚠️ `tar` crée malgré tout une archive quasi vide : une sauvegarde ratée peut **ressembler** à une vraie.

### 3. Restauration testée
```bash
tar -xzf backup_www_2026-10-05_10-39-55.tar.gz -C ~/test-restauration
diff -r /var/www ~/test-restauration/var/www
```
➡️ Aucune différence : la sauvegarde est complète et exploitable.

### 4. Planification
Test cron à la minute (`* * * * *`) → une archive par minute, chaque exécution tracée dans le journal. Horaire définitif ensuite fixé à 2h00.

### 5. Incident constaté : interruption brutale
La VM a été arrêtée **pendant** une sauvegarde : archive de **0 octet**, et **aucune ligne dans le journal** (le script n'a pas atteint le contrôle `$?`).
➡️ Un échec peut être **silencieux**. Le message "réussie" ne suffit pas : il faut aussi contrôler les archives.
➡️ `cron` ne rattrape pas une exécution manquée (machine éteinte = pas de sauvegarde ; `anacron` répond à ce besoin).

### 6. Rotation
Commande testée d'abord **sans** `-delete` pour lister les fichiers ciblés, puis avec suppression. Les archives récentes sont conservées.

> 💡 Une sauvegarde n'existe que si sa restauration a été testée.

## 🔜 Améliorations prévues
- Supprimer automatiquement l'archive en cas d'échec
- Vérifier la taille de l'archive (détection d'une sauvegarde vide)
- Copie **hors serveur** (règle 3-2-1)
- Authentification Git par **clé SSH**

## 🎯 Ce que ce lab démontre

- **Automatisation :** écrire un script Bash qui sauvegarde un serveur web de façon autonome, planifiée chaque nuit, avec un horodatage unique et un contrôle du résultat.
- **Fiabilité :** vérifier qu'une sauvegarde est réellement exploitable en la restaurant dans un environnement de test et en la comparant à l'original avec `diff`.
- **Méthode :** tester volontairement les cas d'échec, diagnostiquer un incident réel, et faire des choix de conception qui protègent les données (rotation conditionnée au succès).
