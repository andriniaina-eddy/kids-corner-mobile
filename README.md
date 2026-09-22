# StockManager — Application Android (Flutter)

Client mobile de l'application de gestion de stock multi-tenant B2B, consommant l'API REST du backend Laravel (voir le projet `saas-stock`).

## Périmètre de cette version

L'application couvre désormais l'intégralité des fonctionnalités du site web :

- Connexion (token, session persistée), avec expérience dédiée par rôle (Super Admin / Admin / Employé)
- Tableau de bord adapté au rôle
- **Boutiques** : création, modification, suppression (Admin)
- **Employés** : création, affectation aux boutiques, activation/désactivation, suppression (Admin)
- **Catalogue produits** : création (avec stock initial multi-boutiques), modification, suppression (Admin)
- **Inventaire** : consultation par boutique, ajustement manuel (entrée/sortie), ajout d'un produit existant à une boutique
- **Transferts inter-boutiques** : liste, création, validation, annulation
- **Inventaire mensuel** : création d'une session, saisie du comptage physique, clôture avec réconciliation automatique des écarts
- **Corbeille** : restauration ou purge définitive des boutiques/produits archivés (Admin)
- **Super Admin** : validation ou rejet des comptes Admin en attente

Chaque écran de gestion (Boutiques, Employés, Catalogue, Inventaires mensuels, Corbeille) est accessible depuis la section « Gestion » du tableau de bord Admin.

## Installation, étape par étape

Comme pour le projet Laravel, **ce zip ne contient que le code source Dart** (`lib/`), pas le squelette natif Android/iOS que Flutter génère lui-même. Il faut créer un projet Flutter vierge, puis copier nos fichiers par-dessus.

### 1. Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installé (`flutter doctor` sans erreur bloquante)
- Android Studio (pour le SDK Android et/ou un émulateur) ou un téléphone Android en mode développeur (USB debugging activé)

### 2. Créer le squelette Flutter

```bash
flutter create --org com.votreentreprise saas_stock_mobile
cd saas_stock_mobile
```

### 3. Copier nos fichiers par-dessus

Depuis le dossier où vous avez dézippé cette livraison :

```bash
# Remplace le lib/ généré par défaut par notre code applicatif
rm -rf ~/chemin/vers/saas_stock_mobile/lib
cp -r lib ~/chemin/vers/saas_stock_mobile/

# Remplace le pubspec.yaml (dépendances : http, provider, shared_preferences, intl)
cp pubspec.yaml ~/chemin/vers/saas_stock_mobile/
```

### 4. Autoriser l'accès réseau (Android)

Deux modifications sont nécessaires dans le projet généré à l'étape 2, dans le fichier `android/app/src/main/AndroidManifest.xml` :

**a) Ajouter la permission Internet**, juste avant la balise `<application ...>` :
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

**b) Autoriser le HTTP en clair vers l'émulateur** (obligatoire en développement — Android bloque le HTTP non chiffré par défaut depuis Android 9). Copiez notre fichier fourni :

```bash
cp android-config/res/xml/network_security_config.xml \
   ~/chemin/vers/saas_stock_mobile/android/app/src/main/res/xml/network_security_config.xml
```

Puis référencez-le sur la balise `<application ...>` du même `AndroidManifest.xml` :
```xml
<application
    android:label="StockManager"
    android:networkSecurityConfig="@xml/network_security_config"
    ...
```

**En production**, votre API doit être servie en HTTPS ; retirez alors cette configuration de trafic en clair (ou restreignez-la encore davantage) — voir les commentaires dans le fichier XML fourni.

### 5. Configurer l'URL du backend

Le fichier `lib/services/api_service.dart` définit l'URL de base :

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);
```

- **`10.0.2.2`** est l'adresse spéciale qui, depuis l'**émulateur Android**, pointe vers `localhost` de votre machine — donc vers `php artisan serve` lancé en local. Ne changez rien si vous testez sur émulateur avec le backend en local.
- **Sur un téléphone physique** connecté au même Wi-Fi que votre ordinateur, remplacez par l'IP locale de votre machine (ex: `http://192.168.1.20:8000/api`), trouvable via `ipconfig` (Windows) ou `ifconfig`/`ip a` (Mac/Linux). Deux options :
  - Éditer directement la valeur par défaut dans le fichier, ou
  - Lancer l'app avec : `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api`
- **En production**, pointez vers l'URL publique HTTPS de votre backend déployé.

### 6. Vérifier que le backend est bien lancé

Avant de tester l'app, assurez-vous que le backend Laravel tourne et que Sanctum est configuré (voir README du projet `saas-stock`, section "API REST mobile") :

```bash
php artisan install:api   # si pas déjà fait
php artisan serve
```

### 7. Lancer l'application

```bash
flutter pub get
flutter run
```

Connectez-vous avec un compte Admin déjà approuvé ou un compte Employé créé depuis l'interface web (voir README du backend pour le compte Super Admin par défaut).

### 8. Générer un APK

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://votre-domaine.com/api
```

L'APK signé (avec la configuration de signature par défaut de debug — à remplacer par votre propre clé pour une vraie publication) se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

## Architecture du code

```
lib/
  models/        User, Shop, Product, Employee, Inventory, Transfer, StockTake, Trash/Admin models
  services/
    api_service.dart     Client HTTP centralisé (GET/POST/PUT/PATCH/DELETE, gestion des erreurs 401/403/422)
    api_exception.dart   Exception dédiée, expose les erreurs de validation champ par champ
  providers/
    auth_provider.dart   État d'authentification global (token, utilisateur, persistance locale)
  screens/        Dashboard (Admin/Employé/Super Admin), Inventory, Transfers, Shops, Employees,
                  Products, StockTakes, Trash, SuperAdmin, Profile, Login
  widgets/        Composants réutilisables (StatCard, StatusBadge)
  utils/          Thème visuel, helpers d'affichage d'erreurs
```

Gestion d'état : `provider` (simple, suffisant pour cette taille d'application). Persistance de session : `shared_preferences` (token + utilisateur en JSON local, non chiffré — voir section Sécurité ci-dessous).

## Sécurité — points à connaître avant une mise en production

- **Le token est stocké en clair via `shared_preferences`.** C'est acceptable pour un prototype, mais pour une vraie mise en production, remplacez `shared_preferences` par [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) (Keystore Android / Keychain iOS), qui chiffre réellement les données stockées.
- **Aucune expiration ni révocation automatique des tokens n'est configurée côté Sanctum** dans cette livraison — un token émis reste valide indéfiniment jusqu'à déconnexion explicite. Envisagez `Sanctum::currentAccessToken()->expires_at` ou une politique d'expiration si l'app doit gérer des appareils partagés ou perdus.
- **Le HTTP en clair n'est autorisé qu'en développement** (voir étape 4) — assurez-vous de retirer cette autorisation ou de la restreindre avant toute publication.
