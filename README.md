# 🗄️ Lab — Sauvegarde automatisée d'un serveur web en Bash

## 📋 Contexte

L'entreprise fictive **TechNova** héberge ses applications web (dont un GLPI) sur un serveur Debian 12. Aucune sauvegarde automatisée n'existe : une panne disque ou une erreur de manipulation ferait perdre toutes les données.

**Mission :** écrire un script Bash qui sauvegarde `/var/www` dans une archive horodatée, signale son succès ou son échec, et **prouver que la restauration fonctionne**.

## 🖥️ Environnement

| Élément | Détail |
|---|---|
| Hyperviseur | VMware Workstation |
| Serveur | Debian 12 (`srv-debian`) |
| Données sauvegardées | `/var/www` (GLPI + html) |
| Outils | Bash, tar, gzip, diff, Git |

## ⚙️ Le script

```bash
#!/bin/bash
SOURCE="/var/www"
DESTINATION="/home/adri/sauvegardes"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p "$DESTINATION"
tar -czf "$DESTINATION/backup_www_$DATE.tar.gz" "$SOURCE"
if [ $? -eq 0 ]; then
    echo "Sauvegarde réussie : backup_www_$DATE.tar.gz"
else
    echo "ERREUR : la sauvegarde a échoué"
fi
```

| Élément | Rôle |
|---|---|
| Variables | Chemins définis à un seul endroit : un changement = une seule ligne modifiée |
| `date` | Horodatage unique : chaque sauvegarde a son propre nom, aucun écrasement |
| `mkdir -p` | Crée le dossier de destination s'il n'existe pas, sans erreur s'il existe |
| `tar -czf` | Regroupe et compresse `/var/www` en une seule archive |
| `$?` | Code retour de `tar` : 0 = succès, autre valeur = échec |

## ✅ Tests réalisés

### 1. Sauvegarde nominale
Trois exécutions successives → trois archives de 61 Mo, horodatées à la seconde. **Aucun écrasement.**

### 2. Test d'échec volontaire
Source remplacée par un dossier inexistant (`/var/wwwXXX`) :
```
tar: /var/wwwXXX : stat impossible: Aucun fichier ou dossier de ce type
ERREUR : la sauvegarde a échoué
```
➡️ Le script détecte l'erreur et l'annonce.

⚠️ **Constat :** `tar` crée malgré tout une archive vide de 45 octets. Une sauvegarde ratée peut donc **ressembler** à une vraie. D'où l'importance du test suivant.

### 3. Restauration testée
Extraction dans un dossier de test, **sans toucher à la production** :
```bash
tar -xzf backup_www_2026-10-05_10-39-55.tar.gz -C ~/test-restauration
diff -r /var/www ~/test-restauration/var/www
```
➡️ `diff` ne renvoie **aucune différence** : la sauvegarde est complète et exploitable.

> 💡 Une sauvegarde n'existe que si sa restauration a été testée.

## 🔜 Améliorations prévues
- **Rotation** : ne conserver que les 7 dernières archives (éviter la saturation du disque)
- **Planification** avec `cron` (exécution automatique chaque nuit)
- **Journalisation** des résultats dans un fichier de log
- **Suppression** automatique de l'archive en cas d'échec
- Copie **hors serveur** (règle 3-2-1)

## 🎯 Ce que ce lab démontre

- **Automatisation :** écrire un script Bash qui sauvegarde un serveur web de façon autonome, avec un horodatage unique et un contrôle du résultat.
- **Fiabilité :** vérifier qu'une sauvegarde est réellement exploitable en la restaurant dans un environnement de test et en la comparant à l'original avec `diff`.
- **Méthode :** tester volontairement un cas d'échec pour valider la détection d'erreur, et documenter les limites constatées (archive vide créée malgré l'échec).

