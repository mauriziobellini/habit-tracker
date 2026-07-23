# App Store Submission — v2.0.0 (build 4)

> **Resubmission after Guideline 2.1(b) rejection** — sandbox legacy-detection bug fixed in `EntitlementManager` (build 4). Includes freemium IAPs and weekly/monthly habits from 2.0.0.

## Pre-submission checklist

- [ ] Unit and UI tests pass on the `HabitTracker` scheme (Release configuration)
- [ ] `CURRENT_PROJECT_VERSION` bumped to **4** in Xcode (build 3 was rejected)
- [ ] Sandbox test on device: fresh install shows **Free plan**, paywall appears on 3rd habit
- [ ] Paywall shows Monthly, Yearly, Lifetime with prices, auto-renew disclosure, and working legal links
- [ ] Privacy Policy live: https://habit-ring.lovable.app/privacy
- [ ] Terms of Use live: https://habit-ring.lovable.app/terms
- [ ] **Paid Apps Agreement** active in App Store Connect → Business (Account Holder must accept)
- [ ] IAP products attached to version: `co.fooshi.habitring.premium.monthly`, `.yearly`, `.lifetime`
- [ ] What's New filled for all 7 locales
- [ ] Description includes Terms + Privacy links (all locales)
- [ ] Notes for Reviewer pasted (English) with Sandbox test account credentials
- [ ] Screenshots current (include paywall if possible)
- [ ] Age Rating questionnaire reflects in-app purchases
- [ ] Archive validated and uploaded; build status **Ready to Submit**
- [ ] Build 4 selected on version page
- [ ] Reply posted in Resolution Center explaining sandbox fix (Section 8.d)

---

## 1. Pre-release verification

### 1.a Code & tests

1. Open `HabitTracker.xcodeproj` → scheme **HabitTracker** → **Product → Test** (⌘U).
2. Confirm Release build has no `--uitesting-premium` / `--uitesting-free` launch arguments in the scheme.
3. Verify `Configuration.storekit` product IDs match App Store Connect:

   | Product | ID | Type |
   |---------|-----|------|
   | Monthly | `co.fooshi.habitring.premium.monthly` | Auto-renewable |
   | Yearly | `co.fooshi.habitring.premium.yearly` | Auto-renewable |
   | Lifetime | `co.fooshi.habitring.premium.lifetime` | Non-consumable |

4. **Critical fix in this build:** `EntitlementManager.checkLegacyPaidAppOwnership()` now returns `false` when `AppTransaction.environment != .production`, so App Review sandbox sessions no longer get lifetime premium on first launch.

### 1.b App Store readiness

1. Confirm legal URLs load in Safari on iPhone:
   - https://habit-ring.lovable.app/privacy
   - https://habit-ring.lovable.app/terms
2. Confirm in-app paywall links open the same URLs (`PaywallView.swift`).
3. Skim `docs/app_store_approval_audit_6d588bd8.plan.md` — all critical items marked completed.
4. **Paid Apps Agreement:** App Store Connect → **Business** → verify **Paid Apps Agreement** status is **Active**. If not, the Account Holder must accept it before IAPs work in review.

### 1.c Version numbers

| Field | Xcode label | Current (rejected) | New value |
|-------|-------------|-------------------|-----------|
| Marketing version | Version | `2.0.0` | `2.0.0` (unchanged) |
| Build number | Build | `3` | **`4`** |

> Build 3 was rejected twice (3.1.2 metadata, then 2.1 sandbox IAP visibility). Build 4 includes the sandbox entitlement fix.

Also update `project.yml` if you regenerate via XcodeGen (`MARKETING_VERSION: "2.0.0"`, `CURRENT_PROJECT_VERSION: "4"`).

### 1.d Release notes source (user-visible changes in 2.0.0)

- **Freemium:** Free download with up to 2 habits; optional premium (Monthly €0.99, Yearly €7.99, Lifetime €14.99) unlocks unlimited habits.
- **Weekly & monthly habits:** Per-period targets with C/N progress counters on the task list.
- **Bug fix (build 4):** Legacy paid-app detection no longer grants premium in sandbox/App Review environments.

---

## 2. Xcode — version bump & build

> **Dependency:** Section 1 complete.

### 2.a Open project

1. Open `HabitTracker.xcodeproj` in Xcode.
2. Select the **HabitTracker** target → **General** tab.

### 2.b Set version fields

| Field | Action |
|-------|--------|
| Version | `2.0.0` |
| Build | `4` (must be higher than rejected build 3) |

### 2.c Verify signing

1. **Signing & Capabilities** → Team selected, **Automatically manage signing** enabled.
2. Bundle ID: `co.fooshi.habitring`.

### 2.d Select destination

1. Scheme: **HabitTracker**.
2. Destination: **Any iOS Device (arm64)** — not a simulator.

---

## 3. Xcode — archive & upload

> **Dependency:** Section 2 complete. Build number must be unique.

### 3.a Archive

1. **Product → Archive**.
2. Wait for the Organizer window to open.

### 3.b Validate

1. Select the new archive → **Validate App**.
2. Fix any errors (signing, entitlements, missing icons, privacy manifest).
3. Re-archive if code changed.

### 3.c Distribute

1. **Distribute App** → **App Store Connect** → **Upload**.
2. Leave default options (upload symbols on).
3. Wait for upload to finish.

### 3.d Wait for processing

1. App Store Connect → **My Apps → Ring Habits – Streak & Reward → TestFlight** (or **Activity**).
2. Build status must reach **Ready to Submit** (typically 5–30 minutes).
3. **Do not proceed to Section 6.c until processing completes.**

---

## 4. App Store Connect — create / update version

> **Dependency:** Section 3 upload started.

### 4.a Open the app

1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps**.
2. Select **Ring Habits – Streak & Reward** (`co.fooshi.habitring`).

### 4.b Use existing version 2.0

1. Left sidebar → **App Store** (under *iOS App*).
2. Open version **2.0** (rejected). Do **not** create a new marketing version — attach build 4 to the existing 2.0 row.

### 4.c Confirm pricing

1. **Pricing and Availability** → confirm territories and **Free** download (IAP for premium).

---

## 5. App Store Connect — localized text fields

> **Dependency:** Section 4 version open.
> Paste each block per locale using the language dropdown on the version / App Information pages.

### What's New in This Version

> Limit: 4,000 characters per locale.

#### English (U.S.) — en

- Ring Habits is now free to download with up to 2 habits. Upgrade anytime for unlimited habits with Monthly, Yearly, or Lifetime options.
- Create weekly and monthly habits with per-period targets and progress counters (C/N) on your task list.
- Improved habit configuration, statistics, and reminders for daily, weekly, and monthly routines.

#### Spanish (Spain) — es

- Ring Habits ahora es gratis con hasta 2 hábitos. Mejora cuando quieras para hábitos ilimitados con opciones Mensual, Anual o de por vida.
- Crea hábitos semanales y mensuales con objetivos por periodo y contadores de progreso (C/N) en tu lista.
- Configuración de hábitos, estadísticas y recordatorios mejorados para rutinas diarias, semanales y mensuales.

#### Portuguese (Portugal) — pt-PT

- O Ring Habits é agora gratuito com até 2 hábitos. Atualize quando quiser para hábitos ilimitados com opções Mensal, Anual ou Vitalícia.
- Crie hábitos semanais e mensais com metas por período e contadores de progresso (C/N) na sua lista.
- Configuração de hábitos, estatísticas e lembretes melhorados para rotinas diárias, semanais e mensais.

#### French — fr

- Ring Habits est désormais gratuit avec jusqu'à 2 habitudes. Passez à la version premium pour des habitudes illimitées (Mensuel, Annuel ou À vie).
- Créez des habitudes hebdomadaires et mensuelles avec des objectifs par période et des compteurs de progression (C/N).
- Configuration des habitudes, statistiques et rappels améliorés pour les routines quotidiennes, hebdomadaires et mensuelles.

#### German — de

- Ring Habits ist jetzt kostenlos mit bis zu 2 Gewohnheiten. Upgrade jederzeit für unbegrenzte Gewohnheiten mit Monatlich, Jährlich oder Lifetime.
- Erstelle wöchentliche und monatliche Gewohnheiten mit Zielen pro Zeitraum und Fortschrittszählern (C/N) in deiner Liste.
- Verbesserte Gewohnheitskonfiguration, Statistiken und Erinnerungen für tägliche, wöchentliche und monatliche Routinen.

#### Italian — it

- Ring Habits è ora gratuito con fino a 2 abitudini. Passa alla versione premium per abitudini illimitate con opzioni Mensile, Annuale o Lifetime.
- Crea abitudini settimanali e mensili con obiettivi per periodo e contatori di progresso (C/N) nella tua lista.
- Configurazione abitudini, statistiche e promemoria migliorati per routine giornaliere, settimanali e mensili.

#### Dutch — nl

- Ring Habits is nu gratis met maximaal 2 gewoontes. Upgrade wanneer je wilt voor onbeperkte gewoontes met Maandelijks, Jaarlijks of Lifetime.
- Maak wekelijkse en maandelijkse gewoontes met doelen per periode en voortgangstellers (C/N) op je takenlijst.
- Verbeterde gewoonteconfiguratie, statistieken en herinneringen voor dagelijkse, wekelijkse en maandelijkse routines.

---

### Promotional Text

> Limit: 170 characters. Optional — update if currently empty or outdated.

| Locale | Text | Chars |
|--------|------|-------|
| English (U.S.) | Build habits that stick. Free with 2 habits — upgrade for unlimited. Daily, weekly, or monthly targets with streaks and gentle reminders. | 127/170 |
| Spanish (Spain) | Crea hábitos que perduren. Gratis con 2 hábitos. Objetivos diarios, semanales o mensuales con rachas y recordatorios suaves. | 113/170 |
| Portuguese (Portugal) | Crie hábitos duradouros. Grátis com 2 hábitos. Metas diárias, semanais ou mensais com sequências e lembretes suaves. | 108/170 |
| French | Créez des habitudes durables. Gratuit avec 2 habitudes. Objectifs quotidiens, hebdo ou mensuels, séries et rappels doux. | 108/170 |
| German | Gewohnheiten, die bleiben. Kostenlos mit 2 Gewohnheiten. Tägliche, wöchentliche oder monatliche Ziele mit Serien und Erinnerungen. | 119/170 |
| Italian | Crea abitudini che durano. Gratis con 2 abitudini. Obiettivi giornalieri, settimanali o mensili con serie e promemoria. | 108/170 |
| Dutch | Bouw gewoontes die blijven. Gratis met 2 gewoontes. Dagelijkse, wekelijkse of maandelijkse doelen met streaks en herinneringen. | 118/170 |

---

### Subtitle

| Locale | Text | Chars |
|--------|------|-------|
| English (U.S.) | Build habits. Track streaks. | 28/30 |
| Spanish (Spain) | Crea hábitos. Sigue rachas. | 27/30 |
| Portuguese (Portugal) | Crie hábitos. Siga sequências. | 30/30 |
| French | Créez vos habitudes et séries | 29/30 |
| German | Gewohnheiten. Serien tracken. | 29/30 |
| Italian | Crea abitudini. Segui serie. | 28/30 |
| Dutch | Bouw gewoontes. Volg streaks. | 29/30 |

---

### Description

> Limit: 4,000 characters per locale. Include legal links at the end of every locale.

#### English (U.S.) — en

Ring Habits helps you build lasting habits with a simple, beautiful interface. Track daily tasks, build streaks, and stay motivated.

• Tap and hold to complete: Press and hold each habit circle for 2 seconds to mark it done. Simple and satisfying.
• Your habits, your way: Create custom habits or start from presets (fitness, health, learning, social). Set goals, reminders, and categories.
• Daily, weekly, or monthly habits: Set a target per day, week, or month and see your progress with C/N counters.
• Streaks and stats: See your completion history, current streak, and trend charts. Filter by time window and category.
• Gentle reminders: Optional local notifications remind you at the time you choose. No account or server required.
• Rewards: Set milestone rewards (e.g. "3-day streak: treat yourself") and get a celebration when you hit them.
• Privacy-first: Your habits stay on your device; no account and no cloud sync of habit data. We use anonymous analytics to improve the app and measure ads — never your habit titles, notes, or personal identifiers.

Ring Habits is local-first: no sign-up, no ads. Optional premium unlocks unlimited habits. Perfect for daily, weekly, or monthly routines — exercise, meditation, reading, or anything you want to do consistently.

> Note: the localized descriptions below still contain the old "no tracking" wording. Update each locale's "Fully private" line to match the English privacy-first copy above before submitting the analytics release (Measurement PRD §17).

Terms of Use: https://habit-ring.lovable.app/terms
Privacy Policy: https://habit-ring.lovable.app/privacy

#### Spanish (Spain) — es

Ring Habits te ayuda a crear hábitos duraderos con una interfaz sencilla y atractiva. Registra tareas diarias, construye rachas y mantente motivado.

• Mantén pulsado para completar: Mantén pulsado cada círculo de hábito durante 2 segundos para marcarlo como hecho.
• Tus hábitos, a tu manera: Crea hábitos personalizados o empieza con plantillas (fitness, salud, aprendizaje, social). Define metas, recordatorios y categorías.
• Hábitos diarios, semanales o mensuales: Establece un objetivo por día, semana o mes y consulta tu progreso con contadores C/N.
• Rachas y estadísticas: Consulta tu historial, racha actual y gráficos de tendencia. Filtra por periodo y categoría.
• Recordatorios suaves: Notificaciones locales opcionales a la hora que elijas. Sin cuenta ni servidor.
• Recompensas: Define recompensas por hitos (p. ej. "racha de 3 días: date un capricho") y celebra cuando las alcances.
• Totalmente privado: Todos los datos permanecen en tu dispositivo. Sin cuenta, sin nube, sin seguimiento.

Ring Habits es local: sin registro, sin anuncios. La versión premium opcional desbloquea hábitos ilimitados. Ideal para rutinas diarias, semanales o mensuales.

Términos de uso: https://habit-ring.lovable.app/terms
Política de privacidad: https://habit-ring.lovable.app/privacy

#### Portuguese (Portugal) — pt-PT

O Ring Habits ajuda-o a criar hábitos duradouros com uma interface simples e bonita. Acompanhe tarefas diárias, construa sequências e mantenha-se motivado.

• Toque e mantenha para concluir: Mantenha premido cada círculo de hábito durante 2 segundos para o marcar como feito.
• Os seus hábitos, à sua maneira: Crie hábitos personalizados ou comece com predefinições (fitness, saúde, aprendizagem, social). Defina metas, lembretes e categorias.
• Hábitos diários, semanais ou mensais: Defina uma meta por dia, semana ou mês e veja o seu progresso com contadores C/N.
• Sequências e estatísticas: Veja o histórico, a sequência atual e gráficos de tendência. Filtre por período e categoria.
• Lembretes suaves: Notificações locais opcionais à hora que escolher. Sem conta nem servidor.
• Recompensas: Defina recompensas por marcos (ex.: "sequência de 3 dias: mime-se") e celebre quando as atingir.
• Totalmente privado: Todos os dados ficam no seu dispositivo. Sem conta, sem nuvem, sem rastreamento.

O Ring Habits é local: sem registo, sem anúncios. O premium opcional desbloqueia hábitos ilimitados. Perfeito para rotinas diárias, semanais ou mensais.

Termos de utilização: https://habit-ring.lovable.app/terms
Política de privacidade: https://habit-ring.lovable.app/privacy

#### French — fr

Ring Habits vous aide à créer des habitudes durables avec une interface simple et élégante. Suivez vos tâches quotidiennes, construisez des séries et restez motivé.

• Appuyez et maintenez pour terminer : Maintenez chaque cercle d'habitude pendant 2 secondes pour le marquer comme fait.
• Vos habitudes, à votre façon : Créez des habitudes personnalisées ou commencez avec des modèles (fitness, santé, apprentissage, social). Définissez objectifs, rappels et catégories.
• Habitudes quotidiennes, hebdomadaires ou mensuelles : Fixez un objectif par jour, semaine ou mois et suivez votre progression avec des compteurs C/N.
• Séries et statistiques : Consultez votre historique, série actuelle et graphiques de tendance. Filtrez par période et catégorie.
• Rappels doux : Notifications locales optionnelles à l'heure de votre choix. Sans compte ni serveur.
• Récompenses : Définissez des récompenses par palier (ex. « série de 3 jours : faites-vous plaisir ») et célébrez vos réussites.
• Entièrement privé : Toutes les données restent sur votre appareil. Sans compte, sans cloud, sans suivi.

Ring Habits est local : sans inscription, sans publicité. Le premium optionnel débloque des habitudes illimitées. Idéal pour les routines quotidiennes, hebdomadaires ou mensuelles.

Conditions d'utilisation : https://habit-ring.lovable.app/terms
Politique de confidentialité : https://habit-ring.lovable.app/privacy

#### German — de

Ring Habits hilft dir, dauerhafte Gewohnheiten mit einer einfachen, schönen Oberfläche aufzubauen. Verfolge tägliche Aufgaben, baue Serien auf und bleib motiviert.

• Gedrückt halten zum Abschließen: Halte jeden Gewohnheitskreis 2 Sekunden lang gedrückt, um ihn als erledigt zu markieren.
• Deine Gewohnheiten, dein Weg: Erstelle eigene Gewohnheiten oder starte mit Vorlagen (Fitness, Gesundheit, Lernen, Soziales). Setze Ziele, Erinnerungen und Kategorien.
• Tägliche, wöchentliche oder monatliche Gewohnheiten: Setze ein Ziel pro Tag, Woche oder Monat und sieh deinen Fortschritt mit C/N-Zählern.
• Serien und Statistiken: Sieh Verlauf, aktuelle Serie und Trenddiagramme. Filtere nach Zeitraum und Kategorie.
• Sanfte Erinnerungen: Optionale lokale Benachrichtigungen zur gewählten Zeit. Kein Konto, kein Server.
• Belohnungen: Setze Meilenstein-Belohnungen (z. B. „3-Tage-Serie: gönn dir etwas“) und feiere deine Erfolge.
• Vollständig privat: Alle Daten bleiben auf deinem Gerät. Kein Konto, keine Cloud, kein Tracking.

Ring Habits ist lokal: keine Anmeldung, keine Werbung. Optionales Premium schaltet unbegrenzte Gewohnheiten frei. Perfekt für tägliche, wöchentliche oder monatliche Routinen.

Nutzungsbedingungen: https://habit-ring.lovable.app/terms
Datenschutzrichtlinie: https://habit-ring.lovable.app/privacy

#### Italian — it

Ring Habits ti aiuta a costruire abitudini durature con un'interfaccia semplice e bella. Tieni traccia delle attività quotidiane, costruisci serie e resta motivato.

• Tieni premuto per completare: Tieni premuto ogni cerchio abitudine per 2 secondi per segnarlo come fatto.
• Le tue abitudini, a modo tuo: Crea abitudini personalizzate o inizia con preset (fitness, salute, apprendimento, social). Imposta obiettivi, promemoria e categorie.
• Abitudini giornaliere, settimanali o mensili: Imposta un obiettivo per giorno, settimana o mese e vedi i progressi con contatori C/N.
• Serie e statistiche: Consulta cronologia, serie attuale e grafici di tendenza. Filtra per periodo e categoria.
• Promemoria delicati: Notifiche locali opzionali all'ora che scegli. Nessun account, nessun server.
• Ricompense: Imposta ricompense per traguardi (es. "serie di 3 giorni: concediti qualcosa") e festeggia i successi.
• Completamente privato: Tutti i dati restano sul dispositivo. Nessun account, nessun cloud, nessun tracciamento.

Ring Habits è locale: nessuna registrazione, nessuna pubblicità. Il premium opzionale sblocca abitudini illimitate. Perfetto per routine giornaliere, settimanali o mensili.

Termini di utilizzo: https://habit-ring.lovable.app/terms
Informativa sulla privacy: https://habit-ring.lovable.app/privacy

#### Dutch — nl

Ring Habits helpt je blijvende gewoontes op te bouwen met een eenvoudige, mooie interface. Volg dagelijkse taken, bouw streaks op en blijf gemotiveerd.

• Ingedrukt houden om te voltooien: Houd elke gewoontecirkel 2 seconden ingedrukt om deze als voltooid te markeren.
• Jouw gewoontes, jouw manier: Maak aangepaste gewoontes of begin met presets (fitness, gezondheid, leren, sociaal). Stel doelen, herinneringen en categorieën in.
• Dagelijkse, wekelijkse of maandelijkse gewoontes: Stel een doel per dag, week of maand in en zie je voortgang met C/N-tellers.
• Streaks en statistieken: Bekijk je geschiedenis, huidige streak en trendgrafieken. Filter op tijdsperiode en categorie.
• Zachte herinneringen: Optionele lokale meldingen op het door jou gekozen tijdstip. Geen account, geen server.
• Beloningen: Stel mijlpaalbeloningen in (bijv. "3-dagen streak: trakteer jezelf") en vier je successen.
• Volledig privé: Alle gegevens blijven op je apparaat. Geen account, geen cloud, geen tracking.

Ring Habits is lokaal: geen aanmelding, geen advertenties. Optionele premium ontgrendelt onbeperkte gewoontes. Perfect voor dagelijkse, wekelijkse of maandelijkse routines.

Gebruiksvoorwaarden: https://habit-ring.lovable.app/terms
Privacybeleid: https://habit-ring.lovable.app/privacy

---

### Keywords

> Comma-separated, no spaces after commas. Max 100 characters.

| Locale | Keywords | Chars |
|--------|----------|-------|
| English (U.S.) | habit tracker,habits,daily habits,streak,goals,productivity,routine,reminder,self improvement | 89/100 |
| Spanish (Spain) | habitos,rutina,racha,metas,productividad,recordatorio,ejercicio,meditacion,lectura,tareas | 85/100 |
| Portuguese (Portugal) | habitos,rotina,sequencia,metas,produtividade,lembrete,exercicio,meditacao,leitura,tarefas | 86/100 |
| French | habitudes,routine,serie,objectifs,productivite,rappel,exercice,meditation,lecture,taches | 84/100 |
| German | gewohnheiten,routine,serie,ziele,produktivitat,erinnerung,sport,meditation,lesen,aufgaben | 87/100 |
| Italian | abitudini,routine,serie,obiettivi,produttivita,promemoria,esercizio,meditazione,lettura | 87/100 |
| Dutch | gewoontes,routine,streak,doelen,productiviteit,herinnering,sport,meditatie,lezen,taken | 84/100 |

---

### Notes for Reviewer

> Paste **English (U.S.)** into App Review Information → Notes. All 7 locales included for reference.

#### English (U.S.) — en

**How to complete a habit (required for testing):**
Press and HOLD a habit circle for about 2 seconds. A progress ring fills; when complete you feel haptic feedback and the task is marked done. A short tap opens the context menu (Stats, Edit, Remove) instead of completing.

**First launch:**
New users see a short onboarding that teaches the tap-and-hold gesture. Tap "Skip" to go straight to the task list. On a fresh install the app shows the Free plan (not Premium).

**How to reach the paywall / In-App Purchases:**
1. Create 2 habits (tap +, configure, then press and hold to complete if needed).
2. Tap the + button to add a 3rd habit — the paywall appears.
3. The paywall shows Monthly (auto-renewable), Yearly (auto-renewable), and Lifetime (one-time), each with title, billing period, price from the App Store, auto-renewal disclosure, and links to Terms of Use and Privacy Policy.

**Restore Purchases:**
Available on the paywall and in Settings → Premium → Restore Purchases.

**Manage Subscription:**
Settings → Premium → Manage Subscription (visible when a subscription is active).

**Architecture / privacy:**
The app is local-first with no account or login. Habit data is stored on-device with SwiftData and is never uploaded. Notifications are local only (UserNotifications). In-app purchases are processed by Apple; the app does not collect payment data. The app sends anonymous product analytics to PostHog (aggregate usage, no habit content or personal identifiers) and a minimal Firebase Analytics event set (first_open, purchase) used only for Google Ads conversion measurement.

**Legal links:**
Terms of Use (EULA): https://habit-ring.lovable.app/terms
Privacy Policy: https://habit-ring.lovable.app/privacy

**Sandbox test account:**
Email: [YOUR_SANDBOX_APPLE_ID]
Password: [YOUR_SANDBOX_PASSWORD]

**Support:**
Support URL: https://habit-ring.lovable.app
Email: habit-tracker@fooshi.co

#### Spanish (Spain) — es

**Cómo completar un hábito:**
Mantén pulsado un círculo de hábito unos 2 segundos. Un anillo de progreso se llena; al completarse, recibes retroalimentación háptica y la tarea se marca como hecha. Un toque corto abre el menú contextual (Estadísticas, Editar, Eliminar).

**Primer inicio:**
Los nuevos usuarios ven un breve onboarding. Toca "Omitir" para ir directamente a la lista. En una instalación nueva la app muestra el plan Gratuito (no Premium).

**Cómo llegar al paywall / compras dentro de la app:**
1. Crea 2 hábitos.
2. Toca + para añadir un 3.er hábito — aparece el paywall.
3. El paywall muestra Mensual (renovable), Anual (renovable) y De por vida (pago único), con título, periodo, precio, aviso de renovación automática y enlaces legales.

**Restaurar compras:** En el paywall y en Ajustes → Premium → Restaurar compras.

**Arquitectura:** App totalmente local. Sin cuenta ni servidor. Datos en el dispositivo con SwiftData.

**Enlaces legales:**
Términos: https://habit-ring.lovable.app/terms
Privacidad: https://habit-ring.lovable.app/privacy

**Cuenta sandbox:** [TU_APPLE_ID_SANDBOX] / [CONTRASEÑA]

#### Portuguese (Portugal) — pt-PT

**Como concluir um hábito:**
Mantenha premido um círculo de hábito durante cerca de 2 segundos. Um anel de progresso enche-se; ao concluir, sente feedback háptico e a tarefa fica marcada. Um toque curto abre o menu contextual (Estatísticas, Editar, Remover).

**Primeiro arranque:**
Novos utilizadores veem um onboarding breve. Toque em "Ignorar" para ir à lista. Numa instalação nova a app mostra o plano Gratuito (não Premium).

**Como chegar ao paywall / compras na app:**
1. Crie 2 hábitos.
2. Toque em + para adicionar um 3.º hábito — o paywall aparece.
3. O paywall mostra Mensal (renovável), Anual (renovável) e Vitalícia (pagamento único), com título, período, preço, aviso de renovação automática e links legais.

**Restaurar compras:** No paywall e em Definições → Premium → Restaurar compras.

**Arquitetura:** App totalmente local. Sem conta nem servidor. Dados no dispositivo com SwiftData.

**Links legais:**
Termos: https://habit-ring.lovable.app/terms
Privacidade: https://habit-ring.lovable.app/privacy

**Conta sandbox:** [SEU_APPLE_ID_SANDBOX] / [PALAVRA-PASSE]

#### French — fr

**Comment terminer une habitude :**
Maintenez un cercle d'habitude environ 2 secondes. Un anneau de progression se remplit ; une fois terminé, vous ressentez un retour haptique et la tâche est marquée comme faite. Un appui court ouvre le menu contextuel (Stats, Modifier, Supprimer).

**Premier lancement :**
Les nouveaux utilisateurs voient un court onboarding. Appuyez sur « Ignorer » pour accéder à la liste. Sur une installation neuve, l'app affiche le plan Gratuit (pas Premium).

**Comment accéder au paywall / achats intégrés :**
1. Créez 2 habitudes.
2. Appuyez sur + pour ajouter une 3e habitude — le paywall s'affiche.
3. Le paywall montre Mensuel (renouvelable), Annuel (renouvelable) et À vie (achat unique), avec titre, période, prix, mention de renouvellement automatique et liens légaux.

**Restaurer les achats :** Sur le paywall et dans Réglages → Premium → Restaurer les achats.

**Architecture :** App entièrement locale. Sans compte ni serveur. Données sur l'appareil avec SwiftData.

**Liens légaux :**
Conditions : https://habit-ring.lovable.app/terms
Confidentialité : https://habit-ring.lovable.app/privacy

**Compte sandbox :** [VOTRE_APPLE_ID_SANDBOX] / [MOT_DE_PASSE]

#### German — de

**Gewohnheit abschließen:**
Halte einen Gewohnheitskreis etwa 2 Sekunden gedrückt. Ein Fortschrittsring füllt sich; bei Abschluss gibt es haptisches Feedback und die Aufgabe wird als erledigt markiert. Ein kurzer Tipp öffnet das Kontextmenü (Statistiken, Bearbeiten, Entfernen).

**Erster Start:**
Neue Nutzer sehen ein kurzes Onboarding. Tippe auf „Überspringen“ für die Aufgabenliste. Bei einer Neuinstallation zeigt die App den kostenlosen Plan (nicht Premium).

**Paywall / In-App-Käufe finden:**
1. Erstelle 2 Gewohnheiten.
2. Tippe auf + für eine 3. Gewohnheit — die Paywall erscheint.
3. Die Paywall zeigt Monatlich (auto-verlängernd), Jährlich (auto-verlängernd) und Lifetime (Einmalkauf) mit Titel, Zeitraum, Preis, Auto-Verlängerungshinweis und Rechtslinks.

**Käufe wiederherstellen:** In der Paywall und unter Einstellungen → Premium → Käufe wiederherstellen.

**Architektur:** Vollständig lokal. Kein Konto, kein Server. Daten auf dem Gerät mit SwiftData.

**Rechtslinks:**
Nutzungsbedingungen: https://habit-ring.lovable.app/terms
Datenschutz: https://habit-ring.lovable.app/privacy

**Sandbox-Konto:** [DEINE_SANDBOX_APPLE_ID] / [PASSWORT]

#### Italian — it

**Come completare un'abitudine:**
Tieni premuto un cerchio abitudine per circa 2 secondi. Un anello di progresso si riempie; al completamento senti il feedback aptico e l'attività viene segnata come fatta. Un tocco breve apre il menu contestuale (Statistiche, Modifica, Rimuovi).

**Primo avvio:**
I nuovi utenti vedono un breve onboarding. Tocca "Salta" per andare alla lista. Su un'installazione nuova l'app mostra il piano Gratuito (non Premium).

**Come raggiungere il paywall / acquisti in-app:**
1. Crea 2 abitudini.
2. Tocca + per aggiungere una 3ª abitudine — appare il paywall.
3. Il paywall mostra Mensile (rinnovabile), Annuale (rinnovabile) e Lifetime (acquisto una tantum), con titolo, periodo, prezzo, informativa sul rinnovo automatico e link legali.

**Ripristina acquisti:** Nel paywall e in Impostazioni → Premium → Ripristina acquisti.

**Architettura:** App completamente locale. Nessun account, nessun server. Dati sul dispositivo con SwiftData.

**Link legali:**
Termini: https://habit-ring.lovable.app/terms
Privacy: https://habit-ring.lovable.app/privacy

**Account sandbox:** [TUO_APPLE_ID_SANDBOX] / [PASSWORD]

#### Dutch — nl

**Gewoonte voltooien:**
Houd een gewoontecirkel ongeveer 2 seconden ingedrukt. Een voortgangsring vult zich; bij voltooiing voel je haptische feedback en de taak wordt als voltooid gemarkeerd. Een korte tik opent het contextmenu (Statistieken, Bewerken, Verwijderen).

**Eerste start:**
Nieuwe gebruikers zien een korte onboarding. Tik op "Overslaan" voor de takenlijst. Bij een nieuwe installatie toont de app het Gratis abonnement (niet Premium).

**Paywall / in-app aankopen vinden:**
1. Maak 2 gewoontes.
2. Tik op + voor een 3e gewoonte — de paywall verschijnt.
3. De paywall toont Maandelijks (automatisch verlengbaar), Jaarlijks (automatisch verlengbaar) en Lifetime (eenmalige aankoop), met titel, periode, prijs, automatische verlenging en juridische links.

**Aankopen herstellen:** Op de paywall en in Instellingen → Premium → Aankopen herstellen.

**Architectuur:** Volledig lokaal. Geen account, geen server. Gegevens op het apparaat met SwiftData.

**Juridische links:**
Voorwaarden: https://habit-ring.lovable.app/terms
Privacy: https://habit-ring.lovable.app/privacy

**Sandbox-account:** [JOUW_SANDBOX_APPLE_ID] / [WACHTWOORD]

---

### Subscription — Monthly (`co.fooshi.habitring.premium.monthly`)

| Locale | Display Name (30) | Description (45) |
|--------|-------------------|------------------|
| English (U.S.) | Monthly | Unlimited habits, billed monthly. |
| Spanish (Spain) | Mensual | Hábitos ilimitados, facturación mensual. |
| Portuguese (Portugal) | Mensal | Hábitos ilimitados, faturação mensal. |
| French | Mensuel | Habitudes illimitées, facturation mensuelle. |
| German | Monatlich | Unbegrenzte Gewohnheiten, monatlich. |
| Italian | Mensile | Abitudini illimitate, fatturazione mensile. |
| Dutch | Maandelijks | Onbeperkte gewoontes, maandelijks. |

### Subscription — Yearly (`co.fooshi.habitring.premium.yearly`)

| Locale | Display Name (30) | Description (45) |
|--------|-------------------|------------------|
| English (U.S.) | Yearly | Unlimited habits, billed yearly. |
| Spanish (Spain) | Anual | Hábitos ilimitados, facturación anual. |
| Portuguese (Portugal) | Anual | Hábitos ilimitados, faturação anual. |
| French | Annuel | Habitudes illimitées, facturation annuelle. |
| German | Jährlich | Unbegrenzte Gewohnheiten, jährlich. |
| Italian | Annuale | Abitudini illimitate, fatturazione annuale. |
| Dutch | Jaarlijks | Onbeperkte gewoontes, jaarlijks. |

### Subscription — Lifetime (`co.fooshi.habitring.premium.lifetime`)

| Locale | Display Name (30) | Description (45) |
|--------|-------------------|------------------|
| English (U.S.) | Lifetime | Unlock unlimited habits forever. |
| Spanish (Spain) | De por vida | Hábitos ilimitados para siempre. |
| Portuguese (Portugal) | Vitalícia | Hábitos ilimitados para sempre. |
| French | À vie | Habitudes illimitées à vie. |
| German | Lifetime | Unbegrenzte Gewohnheiten für immer. |
| Italian | Lifetime | Abitudini illimitate per sempre. |
| Dutch | Lifetime | Onbeperkte gewoontes voor altijd. |

### Subscription Group — Premium

| Locale | Subscription Group Display Name |
|--------|--------------------------------|
| English (U.S.) | Premium |
| Spanish (Spain) | Premium |
| Portuguese (Portugal) | Premium |
| French | Premium |
| German | Premium |
| Italian | Premium |
| Dutch | Premium |

---

## 6. App Store Connect — version page assets

> **Dependency:** Section 4 version exists. Section 5 text ready to paste.

### 6.a Screenshots

Capture per required device size (6.9", 6.7", 6.5", 5.5" iPhone):

1. Task list with habits
2. Onboarding (tap-and-hold)
3. Habit configuration (weekly/monthly option visible)
4. Stats screen
5. **Paywall** (Monthly / Yearly / Lifetime visible) — strongly recommended for IAP review

Localize screenshots if they contain on-screen text.

### 6.b Paste localized metadata

1. On version **2.0**, select each locale from the language dropdown.
2. Paste **What's New** from Section 5.
3. Paste updated **Description** (includes legal links) if not already saved from prior attempt.
4. Update **Keywords** / **Subtitle** / **Promotional Text** if changed.

### 6.c Select build

> **Dependency:** Section 3.d — build **2.0.0 (4)** status **Ready to Submit**.

1. Version page → **Build** → remove build 3 if attached.
2. Click **+** → select build **2.0.0 (4)**.

### 6.d App Review Information

| Field | Value |
|-------|-------|
| Sign-in required | No |
| Contact — First name | *(your name)* |
| Contact — Last name | *(your name)* |
| Contact — Phone | *(your phone)* |
| Contact — Email | habit-tracker@fooshi.co |
| Notes | Paste **English (U.S.)** Notes for Reviewer from Section 5 (fill in Sandbox credentials) |
| Attachment | Screen recording: paywall with IAPs + legal links working |

### 6.e Age Rating & Privacy

1. **Age Rating** → reconfirm questionnaire answers reflect **In-App Purchases** (no longer "no purchases").
2. **App Privacy** → nutrition labels must match actual collection. The app now collects anonymous analytics: declare Usage Data / Product Interaction (and Diagnostics as applicable) for **Analytics** (PostHog) and **Advertising** (Firebase, for Google Ads conversion measurement). Data is not linked to identity (anonymous). Answer the "Used for Tracking" question per Apple's definition based on the final Firebase/ODM configuration (Measurement PRD §17). The previous "local-only; no tracking" declaration is no longer accurate.
3. **Privacy Policy URL** field: `https://habit-ring.lovable.app/privacy`

---

## 7. App Store Connect — app-level settings

### 7.a App Information

| Field | Value |
|-------|-------|
| Name | Ring Habits – Streak & Reward |
| Subtitle | *(localized — Section 5 Subtitle table)* |
| Privacy Policy URL | https://habit-ring.lovable.app/privacy |
| Support URL | https://habit-ring.lovable.app |
| Category | Lifestyle (primary) |
| Copyright | © 2026 Fooshi |

### 7.b App Store server & EULA

| Field | Value |
|-------|-------|
| License Agreement | Custom EULA **or** Apple's Standard EULA |
| Terms link in Description | https://habit-ring.lovable.app/terms (required for subscriptions) |

### 7.c Subscriptions (freemium)

1. **Subscriptions** → group **Premium** → verify metadata + pricing for all 3 products.
2. Paste subscription localizations from Section 5 (all 7 locales per product).
3. Confirm each IAP status is **Ready to Submit** and attached to version 2.0.
4. **Business → Paid Apps Agreement** must be **Active**.

### 7.d Sandbox testers

1. App Store Connect → **Users and Access → Sandbox → Testers**.
2. Create a dedicated Sandbox Apple ID for review (if not already).
3. Paste credentials into Notes for Reviewer (Section 6.d).

---

## 8. Submit for review

> **Dependency:** Sections 2–7 complete. Build 4 selected. All required locales filled.

### 8.a Final review on version page

- [ ] Build **2.0.0 (4)** attached (not build 3)
- [ ] What's New filled for all 7 locales
- [ ] Description includes Terms + Privacy links (all locales)
- [ ] Screenshots current (paywall recommended)
- [ ] Export compliance answered (No encryption beyond HTTPS → exempt)
- [ ] Content rights, advertising identifier (No), IDFA (No) confirmed
- [ ] Paid Apps Agreement active
- [ ] Sandbox credentials in reviewer notes
- [ ] Screen recording attached to review notes or Resolution Center reply

### 8.b Submit

1. Click **Add for Review** (or **Submit for Review**).
2. Answer submission questionnaire (manual or automatic release).
3. Confirm **Submit**.

### 8.c After submission

1. Monitor **App Review** status in App Store Connect.
2. If **Rejected**, read Resolution Center notes, fix, increment build to 5, re-upload (Section 3), reattach (Section 6.c), resubmit.
3. On **Approved**, release manually or wait for automatic release.

### 8.d Reply in Resolution Center (paste with screen recording)

```
Hello,

Thank you for the detailed feedback on Guideline 2.1(b).

Root cause: our app maps original (legacy) paid-app customers to a lifetime entitlement using AppTransaction.originalAppVersion. In the App Review sandbox environment this value is always "1.0", which caused the app to incorrectly treat the review session as a legacy lifetime customer. Premium was already active on first launch, so the paywall and In-App Purchases were hidden.

Fix: we now only apply legacy mapping when AppTransaction.environment == .production. In the sandbox environment the app no longer grants premium automatically. This fix is included in build 2.0.0 (4), which we have just submitted.

Steps to locate the In-App Purchases:
1. Launch the app on a fresh install. Settings → Premium should show "Free plan" (not Premium active).
2. Create 2 habits (tap +, then press and hold a habit circle for ~2 seconds to complete if needed).
3. Tap the + button to add a 3rd habit — the paywall appears.
4. The paywall shows Monthly (auto-renewable), Yearly (auto-renewable), and Lifetime (one-time), each with title, billing period, price, auto-renewal disclosure, and working Terms of Use / Privacy Policy links.

We have confirmed the Paid Apps Agreement is active and included a Sandbox test account in the App Review notes.

A screen recording is attached demonstrating the paywall and working legal links.

Thank you!
```

---

## Open risks to address before submit

| Risk | Severity | Action |
|------|----------|--------|
| Build still at **3** in `project.pbxproj` | Critical | Bump to **4** before archiving |
| Paid Apps Agreement not active | Critical | Account Holder accepts in Business section |
| Sandbox credentials missing in notes | High | Create Sandbox tester, paste in Section 6.d |
| `project.yml` out of sync (`1.1.0` / build `2`) | Low | Update if using XcodeGen |
| Reviewer notes in `docs/app-store-review-notes.md` outdated | Medium | Use Section 5 Notes instead (includes IAP steps) |
