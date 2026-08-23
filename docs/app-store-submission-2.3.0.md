# App Store Submission — v2.3.0 (build 7)

> **New marketing version** — Habit Strength (score, stages, summary sheet, celebrations, actionable notifications), bottom-sheet layout polish, Firebase default consent keys for Google Ads conversion measurement. Builds on shipping **2.2.0** (opt-out reminders, first-completion prompt, stats chart tap).

## Pre-submission checklist

- [ ] Unit and UI tests pass on the `HabitTracker` scheme (122 unit + 20 UI tests green at time of writing)
- [ ] Bump `MARKETING_VERSION` to **2.3.0** and `CURRENT_PROJECT_VERSION` to **7** in Xcode and `project.yml` (repo still shows 2.2.0 / 6 — same as the live App Store build)
- [ ] Device: single tap a habit → summary sheet opens with strength ring, stage, consistency grid, Manage Completions link, Stats / Edit / Remove
- [ ] Device: press and hold ~1.4 s to complete; dashboard inner strength ring and stage badge update
- [ ] Device: complete enough days to cross a stage boundary → celebration overlay (may be suppressed by 12 h cooldown per habit)
- [ ] Device: Settings → Your plan → tap Free row opens paywall; create 3rd habit also opens paywall
- [ ] Sandbox: Restore Purchases on paywall and in Settings
- [ ] Privacy Policy live: https://habit-ring.lovable.app/privacy (mentions analytics + masked session replay)
- [ ] Terms of Use live: https://habit-ring.lovable.app/terms
- [ ] **Paid Apps Agreement** Active in App Store Connect → Business
- [ ] IAP products Ready: `co.fooshi.habitring.premium.monthly`, `.yearly`, `.lifetime`
- [ ] What's New filled for all 7 locales
- [ ] Description updated for Habit Strength (all 7 locales)
- [ ] Notes for Reviewer pasted (English) with Sandbox credentials; hold duration **1.4 s**; single tap = summary sheet
- [ ] Screenshots updated (habit summary sheet, strength ring on dashboard, stage badge, optional celebration)
- [ ] App Privacy nutrition labels include analytics / product interaction (PostHog + Firebase; no IDFA)
- [ ] Archive validated and uploaded; Activity status **Ready to Submit**
- [ ] Build **2.3.0 (7)** selected on the new version page

---

## 1. Pre-release verification

> **Goal:** Confirm the app is technically sound and App Store-ready before changing versions or uploading.
> **Where you'll work:** Terminal, Xcode, Codebase, Browser, App Store Connect (read-only checks)
> **Outcome:** Tests pass, no debug leakage, IAP IDs aligned, legal URLs live, version numbers decided, changelog ready for Section 5.

### 1.a Code & tests

| # | Where | Action |
|---|-------|--------|
| 1 | Terminal / Xcode | Run unit and UI tests on the `HabitTracker` scheme (Xcode → Product → Test, or `xcodebuild test`). |
| 2 | Codebase | Confirm no debug-only code paths, test launch arguments (`--uitesting-seed-two`, `--uitesting-seed-strong`, `--uitesting-premium`, `--uitesting-free`), or placeholder content ship in Release. |
| 3 | Codebase + App Store Connect | Verify `HabitTracker/Configuration.storekit` product IDs match **Subscriptions** in App Store Connect: `co.fooshi.habitring.premium.monthly`, `.yearly`, `.lifetime`. |

### 1.b App Store readiness

| # | Where | Action |
|---|-------|--------|
| 1 | Codebase | Skim `docs/app_store_approval_audit_6d588bd8.plan.md` — critical items remain completed. |
| 2 | Browser | Confirm Privacy Policy and Support URLs load on mobile Safari: https://habit-ring.lovable.app/privacy and https://habit-ring.lovable.app |
| 3 | Browser | Confirm Terms of Use: https://habit-ring.lovable.app/terms |
| 4 | App Store Connect | Confirm Terms of Use / EULA link is set (required for subscriptions). |
| 5 | App Store Connect | **Business** → verify **Paid Apps Agreement** is Active (Account Holder). |

### 1.c Decide version numbers

| # | Where | Action |
|---|-------|--------|
| 1 | Codebase | Current values in `project.yml` / `HabitTracker.xcodeproj/project.pbxproj`: **2.2.0** / **6** — matches the **live** App Store version (released 2026-08-12). |
| 2 | — | **Marketing version:** bump to **2.3.0** for this release. Do **not** reuse 2.2.0 — that train is already approved and live. |
| 3 | — | **Build number:** **7** (must be higher than any previously uploaded build; 2.2.0 used build 6). |
| 4 | Codebase | Update `project.yml` and Xcode **General** tab before archiving. |

### 1.d Prepare release notes source

| # | Where | Action |
|---|-------|--------|
| 1 | Codebase | User-visible changes since live **2.2.0** (commits `2648212`, `1da7e15`, `d95a8b0`): |
|   | | • **Habit Strength** — score (0–100), six formation stages (Starting → Mastering), inner ring on dashboard, stage badge from Developing upward |
|   | | • **Habit summary sheet** — single tap a habit for strength ring, stage label, consistency grid, Manage Completions link, Stats / Edit / Remove |
|   | | • **Stage celebrations** — full-screen overlay when a habit advances; optional notification opt-in |
|   | | • **Strength notifications** — proximity / reversion local notifications with Mark done / Later actions (requires notification permission) |
|   | | • **Polish** — faster tap-and-hold (~1.4 s), dashboard hint subtitle, tappable Free plan row in Settings, App Store review prompt after 3 completions |
|   | | • **Firebase consent defaults** — Info.plist keys for Google Ads conversion measurement (no ATT / IDFA) |
| 2 | — | This list becomes **What's New** in Section 5. |

---

## 2. Xcode — version bump & build

> **Goal:** Set marketing version and build number in the project so the archive matches what you'll create in App Store Connect.
> **Where you'll work:** Xcode, Codebase (`project.yml` if using XcodeGen)
> **Outcome:** `MARKETING_VERSION` **2.3.0** and `CURRENT_PROJECT_VERSION` **7** set; signing verified; device destination selected.

> **Dependency:** Complete Section 1 first.

### 2.a Open project

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | Open `HabitTracker.xcodeproj`. |
| 2 | Xcode | Select the **HabitTracker** target → **General** tab. |

### 2.b Set version fields

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | Set **Version** to **2.3.0**. |
| 2 | Xcode | Set **Build** to **7** (must be higher than build 6 already on App Store Connect). |
| 3 | Codebase | Also update `project.yml`: `MARKETING_VERSION: "2.3.0"`, `CURRENT_PROJECT_VERSION: "7"`. Regenerate with XcodeGen if you use it. |

### 2.c Verify signing

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | **Signing & Capabilities** → Team selected, **Automatically manage signing** enabled. |
| 2 | Xcode | Confirm Bundle ID: `co.fooshi.habitring`. |

### 2.d Select destination

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | Scheme: **HabitTracker**. |
| 2 | Xcode | Destination: **Any iOS Device (arm64)** — not a simulator. |

---

## 3. Xcode — archive & upload

> **Goal:** Produce and upload a signed Release archive to App Store Connect.
> **Where you'll work:** Xcode (Organizer), App Store Connect (wait for processing)
> **Outcome:** Build uploaded; status reaches **Ready to Submit**.

> **Dependency:** Section 2 complete. Build number must be unique.

### 3.a Archive

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | **Product → Archive**. |
| 2 | Xcode | Wait for the Organizer window to open. |

### 3.b Validate

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | Select the new archive → **Validate App**. |
| 2 | Xcode + Codebase | Fix any errors (signing, entitlements, missing icons, privacy manifest). |
| 3 | Xcode | Re-archive if code changed. |

### 3.c Distribute

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | **Distribute App** → **App Store Connect** → **Upload**. |
| 2 | Xcode | Leave default options (include bitcode off, upload symbols on, manage version/build on). |
| 3 | Xcode | Wait for upload to finish. |

### 3.d Wait for processing

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | **My Apps → Ring Habits – Streak & Reward → TestFlight** (or **Activity**). |
| 2 | App Store Connect | Build status must reach **Ready to Submit** (typically 5–30 minutes; longer after export-compliance answers). |
| 3 | App Store Connect | If status is **Missing Compliance**, open the build → answer the export-encryption questionnaire (typically **No** — app uses only standard HTTPS). Apple re-processes the build after you submit; wait again. |
| 4 | — | **TestFlight ≠ version page:** a build can appear in **TestFlight** before it is selectable on the **App Store** version page. Only proceed to Section 6.c when **Activity** shows **Ready to Submit**, not merely when the build is visible under TestFlight. |
| 5 | — | **Do not proceed to Section 6.c until processing completes.** |

---

## 4. App Store Connect — create version

> **Goal:** Create the App Store version row so version-specific fields and the build picker are available.
> **Where you'll work:** App Store Connect
> **Outcome:** New iOS version **2.3.0** exists; pricing confirmed.

> **Dependency:** Section 3 upload started (version can be created while build processes).

### 4.a Open the app

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | [App Store Connect](https://appstoreconnect.apple.com) → **My Apps**. |
| 2 | App Store Connect | Select **Ring Habits – Streak & Reward** (`co.fooshi.habitring`). |

### 4.b Create or reuse version

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Left sidebar → **App Store** (under *iOS App*). |
| 2a | App Store Connect | **New marketing version:** click **+** next to *iOS App* or **Add Version** → enter **2.3.0** (must match `MARKETING_VERSION` in Xcode). |
| 2b | App Store Connect | **Resubmission after rejection (same marketing version):** open the **existing** rejected **2.3.0** row. Do **not** create a duplicate version — attach the new build to the same row in Section 6.c. |
| 3 | — | This submission is a **new version** (2.2.0 is live; 2.3.0 is new). |

### 4.c Confirm pricing

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | **Pricing and Availability** → confirm territories and price tier (free download with IAP). |

---

## 5. App Store Connect — localized text fields

> **Goal:** Generate all localized copy to paste into App Store Connect for this release.
> **Where you'll work:** Codebase (research) → this document; you paste into App Store Connect in Section 6
> **Outcome:** Complete text blocks for all 7 locales; no TBD placeholders in listing fields.

> **Dependency:** Section 4 version created.

Paste order tip: English (U.S.) → Spanish (Spain) → French → German → Italian → Dutch → Portuguese (Portugal).

---

### What's New in This Version

> Limit: 4,000 characters per locale. Bullets encouraged.

#### English (U.S.) — en

- **Habit Strength** — every habit now has a formation score (0–100) and a stage from Starting to Mastering. Watch the inner ring on the dashboard grow as your habit becomes automatic.
- **Habit summary sheet** — tap a habit once to see your strength, stage, and a consistency grid. Stats, Edit, and Remove are one tap away.
- **Stage celebrations** — when your habit advances to a new stage, enjoy a full-screen celebration. Optionally turn on reminders right from the moment.
- **Smarter notifications** — get a heads-up when you're close to the next stage or at risk of slipping back. Mark done or snooze directly from the notification.
- Faster tap-and-hold to complete (~1.4 seconds) and clearer dashboard hints.

#### Spanish (Spain) — es

- **Fuerza del hábito** — cada hábito tiene ahora una puntuación de formación (0–100) y una etapa de Starting a Mastering. Observa crecer el anillo interior en el panel principal.
- **Ficha resumen del hábito** — toca una vez un hábito para ver tu fuerza, etapa y una cuadrícula de consistencia. Estadísticas, Editar y Eliminar a un toque.
- **Celebraciones de etapa** — cuando tu hábito avanza de etapa, disfruta de una celebración a pantalla completa. Activa recordatorios desde el mismo momento si quieres.
- **Notificaciones más inteligentes** — aviso cuando estés cerca de la siguiente etapa o en riesgo de retroceder. Marca hecho o posponer desde la notificación.
- Mantén pulsado más rápido para completar (~1,4 s) e indicaciones más claras en el panel.

#### Portuguese (Portugal) — pt-PT

- **Força do hábito** — cada hábito tem agora uma pontuação de formação (0–100) e uma fase de Starting a Mastering. Veja o anel interior no painel principal crescer.
- **Ficha resumo do hábito** — toque uma vez num hábito para ver a força, fase e grelha de consistência. Estatísticas, Editar e Remover a um toque.
- **Celebrações de fase** — quando o hábito avança de fase, desfrute de uma celebração em ecrã completo. Ative lembretes nesse momento, se quiser.
- **Notificações mais inteligentes** — aviso quando estiver perto da fase seguinte ou em risco de recuar. Marque feito ou adie a partir da notificação.
- Toque e mantenha mais rápido para concluir (~1,4 s) e dicas mais claras no painel.

#### French — fr

- **Force de l'habitude** — chaque habitude a désormais un score de formation (0–100) et une étape de Starting à Mastering. Regardez l'anneau intérieur grandir sur le tableau de bord.
- **Fiche résumé de l'habitude** — touchez une habitude une fois pour voir votre force, étape et une grille de régularité. Stats, Modifier et Supprimer à portée de main.
- **Célébrations d'étape** — quand votre habitude progresse, profitez d'une célébration plein écran. Activez les rappels sur le moment si vous le souhaitez.
- **Notifications plus intelligentes** — alerte quand vous approchez de l'étape suivante ou risquez de reculer. Marquer fait ou reporter depuis la notification.
- Appui prolongé plus rapide pour terminer (~1,4 s) et indications plus claires sur le tableau de bord.

#### German — de

- **Gewohnheitsstärke** — jede Gewohnheit hat jetzt einen Formationswert (0–100) und eine Stufe von Starting bis Mastering. Sieh zu, wie der innere Ring auf dem Dashboard wächst.
- **Gewohnheits-Übersicht** — einmal tippen für Stärke, Stufe und Konsistenzraster. Statistiken, Bearbeiten und Entfernen direkt erreichbar.
- **Stufen-Feiern** — bei einem Stufenaufstieg gibt es eine Vollbild-Feier. Erinnerungen optional direkt dabei aktivieren.
- **Intelligentere Benachrichtigungen** — Hinweis, wenn du der nächsten Stufe nahe bist oder zurückfallen könntest. Als erledigt markieren oder später direkt aus der Benachrichtigung.
- Schnelleres Gedrückthalten zum Abschließen (~1,4 s) und klarere Dashboard-Hinweise.

#### Italian — it

- **Forza dell'abitudine** — ogni abitudine ha ora un punteggio di formazione (0–100) e una fase da Starting a Mastering. Guarda crescere l'anello interno nella dashboard.
- **Scheda riepilogo abitudine** — tocca una volta un'abitudine per vedere forza, fase e griglia di costanza. Statistiche, Modifica e Rimuovi a un tocco.
- **Celebrazioni di fase** — quando l'abitudine avanza, goditi una celebrazione a schermo intero. Attiva i promemoria in quel momento, se vuoi.
- **Notifiche più intelligenti** — avviso quando sei vicino alla fase successiva o a rischio di retrocedere. Segna fatto o posticipa dalla notifica.
- Tieni premuto più velocemente per completare (~1,4 s) e suggerimenti più chiari nella dashboard.

#### Dutch — nl

- **Gewoontesterkte** — elke gewoonte heeft nu een vormingsscore (0–100) en een fase van Starting tot Mastering. Zie de binnenste ring op het dashboard groeien.
- **Gewoonte-overzicht** — tik één keer op een gewoonte voor sterkte, fase en consistentieraster. Statistieken, Bewerken en Verwijderen binnen bereik.
- **Fase-vieringen** — bij een nieuwe fase een volledig scherm viering. Schakel desgewenst direct herinneringen in.
- **Slimmere meldingen** — heads-up wanneer je dicht bij de volgende fase bent of kunt terugvallen. Markeer klaar of stel uit vanuit de melding.
- Sneller ingedrukt houden om te voltooien (~1,4 s) en duidelijkere dashboardhints.

---

### Promotional Text

> Limit: 170 characters. Optional — update for Habit Strength release.

| Locale | Text | Chars |
|--------|------|-------|
| English (U.S.) | Every habit now has a strength score and a formation stage. Watch the inner ring grow as your habit becomes automatic. | 118/170 |
| Spanish (Spain) | Cada hábito tiene ahora una puntuación de fuerza y una etapa de formación. Observa crecer el anillo interior hasta que sea automático. | 134/170 |
| Portuguese (Portugal) | Cada hábito tem agora uma pontuação de força e uma fase de formação. Veja o anel interior crescer até se tornar automático. | 123/170 |
| French | Chaque habitude a désormais un score de force et une étape de formation. Regardez l'anneau intérieur grandir jusqu'à l'automatisme. | 131/170 |
| German | Jede Gewohnheit hat jetzt einen Stärkewert und eine Entwicklungsstufe. Sieh zu, wie der innere Ring wächst, bis alles automatisch läuft. | 136/170 |
| Italian | Ogni abitudine ha ora un punteggio di forza e una fase di formazione. Guarda crescere l'anello interno fino all'automatismo. | 124/170 |
| Dutch | Elke gewoonte heeft nu een sterktescore en een vormingsfase. Zie de binnenste ring groeien tot het automatisch gaat. | 116/170 |

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

> Limit: 4,000 characters per locale. Updated for Habit Strength. Include legal links at the end of every locale.

#### English (U.S.) — en

Ring Habits helps you build lasting habits with a simple, beautiful interface. Track daily tasks, build streaks, and stay motivated.

• Tap and hold to complete: Press and hold each habit circle for about 1.4 seconds to mark it done. Simple and satisfying.
• Tap for details: A single tap opens the habit summary — your Habit Strength score, formation stage, consistency grid, and quick actions.
• Habit Strength: Every habit earns a score from 0 to 100 and progresses through six stages (Starting → Mastering). An inner ring on the dashboard shows your progress; a stage badge appears from Developing upward.
• Your habits, your way: Create custom habits or start from presets (fitness, health, learning, social). Set goals, reminders, and categories.
• Daily, weekly, or monthly habits: Set a target per day, week, or month and see your progress with C/N counters.
• Streaks and stats: See your completion history, current streak, and trend charts. Filter by time window and category. Tap chart points for day-level detail.
• Gentle reminders: Local notifications default on when you create a habit (you can turn them off). Strength notifications nudge you when you are close to the next stage.
• Rewards: Set milestone rewards (e.g. "3-day streak: treat yourself") and get a celebration when you hit them.
• Privacy-first: Your habits stay on your device; no account and no cloud sync of habit data. We use anonymous analytics to improve the app and measure ads, and masked session replay to understand usability — never your habit titles, notes, or personal identifiers.

Ring Habits is local-first: no sign-up, no ads. Optional premium unlocks unlimited habits. Perfect for daily, weekly, or monthly routines — exercise, meditation, reading, or anything you want to do consistently.

Terms of Use: https://habit-ring.lovable.app/terms
Privacy Policy: https://habit-ring.lovable.app/privacy

#### Spanish (Spain) — es

Ring Habits te ayuda a crear hábitos duraderos con una interfaz sencilla y atractiva. Registra tareas diarias, construye rachas y mantente motivado.

• Mantén pulsado para completar: Mantén pulsado cada círculo de hábito unos 1,4 segundos para marcarlo como hecho.
• Toca para ver detalles: Un toque abre la ficha resumen — puntuación de Fuerza del hábito, etapa de formación, cuadrícula de consistencia y acciones rápidas.
• Fuerza del hábito: Cada hábito obtiene una puntuación de 0 a 100 y avanza por seis etapas (Starting → Mastering). Un anillo interior en el panel muestra tu progreso; un distintivo de etapa aparece desde Developing.
• Tus hábitos, a tu manera: Crea hábitos personalizados o empieza con plantillas (fitness, salud, aprendizaje, social). Define metas, recordatorios y categorías.
• Hábitos diarios, semanales o mensuales: Establece un objetivo por día, semana o mes y consulta tu progreso con contadores C/N.
• Rachas y estadísticas: Consulta tu historial, racha actual y gráficos de tendencia. Toca los puntos del gráfico para el detalle diario.
• Recordatorios suaves: Las notificaciones locales se activan por defecto al crear un hábito (puedes desactivarlas). Las notificaciones de fuerza te avisan cuando estás cerca de la siguiente etapa.
• Recompensas: Define recompensas por hitos y celebra cuando las alcances.
• Privacidad primero: Tus hábitos permanecen en el dispositivo; sin cuenta ni sincronización en la nube. Usamos analítica anónima para mejorar la app y medir anuncios, y reproducción de sesión enmascarada para la usabilidad — nunca títulos, notas ni identificadores personales.

Ring Habits es local: sin registro, sin anuncios. La versión premium opcional desbloquea hábitos ilimitados.

Términos de uso: https://habit-ring.lovable.app/terms
Política de privacidad: https://habit-ring.lovable.app/privacy

#### Portuguese (Portugal) — pt-PT

O Ring Habits ajuda-o a criar hábitos duradouros com uma interface simples e bonita. Acompanhe tarefas diárias, construa sequências e mantenha-se motivado.

• Toque e mantenha para concluir: Mantenha premido cada círculo de hábito cerca de 1,4 segundos para o marcar como feito.
• Toque para detalhes: Um toque abre a ficha resumo — pontuação de Força do hábito, fase de formação, grelha de consistência e ações rápidas.
• Força do hábito: Cada hábito obtém uma pontuação de 0 a 100 e progride por seis fases (Starting → Mastering). Um anel interior no painel mostra o progresso; um emblema de fase aparece a partir de Developing.
• Os seus hábitos, à sua maneira: Crie hábitos personalizados ou comece com predefinições. Defina metas, lembretes e categorias.
• Hábitos diários, semanais ou mensais: Defina uma meta por dia, semana ou mês e veja o progresso com contadores C/N.
• Sequências e estatísticas: Veja o histórico, a sequência atual e gráficos de tendência. Toque nos pontos do gráfico para o detalhe diário.
• Lembretes suaves: As notificações locais ficam ativas por predefinição ao criar um hábito (pode desativá-las). Notificações de força avisam quando está perto da fase seguinte.
• Recompensas: Defina recompensas por marcos e celebre quando as atingir.
• Privacidade em primeiro lugar: Os hábitos ficam no dispositivo; sem conta nem sincronização na nuvem. Usamos analítica anónima e reprodução de sessão mascarada — nunca títulos, notas nem identificadores pessoais.

O Ring Habits é local: sem registo, sem anúncios. O premium opcional desbloqueia hábitos ilimitados.

Termos de utilização: https://habit-ring.lovable.app/terms
Política de privacidade: https://habit-ring.lovable.app/privacy

#### French — fr

Ring Habits vous aide à créer des habitudes durables avec une interface simple et élégante. Suivez vos tâches quotidiennes, construisez des séries et restez motivé.

• Appuyez et maintenez pour terminer : Maintenez chaque cercle d'habitude environ 1,4 seconde pour le marquer comme fait.
• Touchez pour les détails : Un toucher ouvre la fiche résumé — score de Force de l'habitude, étape de formation, grille de régularité et actions rapides.
• Force de l'habitude : Chaque habitude obtient un score de 0 à 100 et progresse en six étapes (Starting → Mastering). Un anneau intérieur sur le tableau de bord montre votre progression ; un badge d'étape apparaît à partir de Developing.
• Vos habitudes, à votre façon : Créez des habitudes personnalisées ou commencez avec des modèles. Définissez objectifs, rappels et catégories.
• Habitudes quotidiennes, hebdomadaires ou mensuelles : Fixez un objectif par jour, semaine ou mois et suivez votre progression avec des compteurs C/N.
• Séries et statistiques : Consultez votre historique, série actuelle et graphiques. Touchez les points du graphique pour le détail journalier.
• Rappels doux : Les notifications locales sont activées par défaut à la création (vous pouvez les désactiver). Les notifications de force vous alertent quand vous approchez de l'étape suivante.
• Récompenses : Définissez des récompenses par palier et célébrez vos réussites.
• Confidentialité d'abord : Vos habitudes restent sur l'appareil ; pas de compte ni de sync cloud. Analytique anonyme et relecture de session masquée — jamais vos titres, notes ou identifiants personnels.

Ring Habits est local : sans inscription, sans publicité. Le premium optionnel débloque des habitudes illimitées.

Conditions d'utilisation : https://habit-ring.lovable.app/terms
Politique de confidentialité : https://habit-ring.lovable.app/privacy

#### German — de

Ring Habits hilft dir, dauerhafte Gewohnheiten mit einer einfachen, schönen Oberfläche aufzubauen. Verfolge tägliche Aufgaben, baue Serien auf und bleib motiviert.

• Gedrückt halten zum Abschließen: Halte jeden Gewohnheitskreis etwa 1,4 Sekunden lang gedrückt, um ihn als erledigt zu markieren.
• Tippen für Details: Ein Tippen öffnet die Übersicht — Gewohnheitsstärke-Wert, Entwicklungsstufe, Konsistenzraster und Schnellaktionen.
• Gewohnheitsstärke: Jede Gewohnheit erhält einen Wert von 0 bis 100 und durchläuft sechs Stufen (Starting → Mastering). Ein innerer Ring auf dem Dashboard zeigt deinen Fortschritt; ein Stufen-Badge erscheint ab Developing.
• Deine Gewohnheiten, dein Weg: Erstelle eigene Gewohnheiten oder starte mit Vorlagen. Setze Ziele, Erinnerungen und Kategorien.
• Tägliche, wöchentliche oder monatliche Gewohnheiten: Setze ein Ziel pro Tag, Woche oder Monat und sieh deinen Fortschritt mit C/N-Zählern.
• Serien und Statistiken: Sieh Verlauf, aktuelle Serie und Trenddiagramme. Tippe auf Diagrammpunkte für Tagesdetails.
• Sanfte Erinnerungen: Lokale Benachrichtigungen sind beim Erstellen standardmäßig an (abschaltbar). Stärke-Benachrichtigungen warnen, wenn du der nächsten Stufe nahe bist.
• Belohnungen: Setze Meilenstein-Belohnungen und feiere deine Erfolge.
• Datenschutz zuerst: Deine Gewohnheiten bleiben auf dem Gerät; kein Konto, keine Cloud-Sync. Anonyme Analytik und maskierte Session-Replays — niemals Titel, Notizen oder personenbezogene Kennungen.

Ring Habits ist lokal: keine Anmeldung, keine Werbung. Optionales Premium schaltet unbegrenzte Gewohnheiten frei.

Nutzungsbedingungen: https://habit-ring.lovable.app/terms
Datenschutzrichtlinie: https://habit-ring.lovable.app/privacy

#### Italian — it

Ring Habits ti aiuta a costruire abitudini durature con un'interfaccia semplice e bella. Tieni traccia delle attività quotidiane, costruisci serie e resta motivato.

• Tieni premuto per completare: Tieni premuto ogni cerchio abitudine per circa 1,4 secondi per segnarlo come fatto.
• Tocca per i dettagli: Un tocco apre la scheda riepilogo — punteggio Forza dell'abitudine, fase di formazione, griglia di costanza e azioni rapide.
• Forza dell'abitudine: Ogni abitudine ottiene un punteggio da 0 a 100 e progredisce in sei fasi (Starting → Mastering). Un anello interno nella dashboard mostra i progressi; un badge di fase appare da Developing in su.
• Le tue abitudini, a modo tuo: Crea abitudini personalizzate o inizia con preset. Imposta obiettivi, promemoria e categorie.
• Abitudini giornaliere, settimanali o mensili: Imposta un obiettivo per giorno, settimana o mese e vedi i progressi con contatori C/N.
• Serie e statistiche: Consulta cronologia, serie attuale e grafici. Tocca i punti del grafico per il dettaglio giornaliero.
• Promemoria delicati: Le notifiche locali sono attive per impostazione predefinita alla creazione (puoi disattivarle). Le notifiche di forza avvisano quando sei vicino alla fase successiva.
• Ricompense: Imposta ricompense per traguardi e festeggia i successi.
• Privacy prima di tutto: Le abitudini restano sul dispositivo; nessun account né sync cloud. Analitica anonima e replay di sessione mascherati — mai titoli, note o identificatori personali.

Ring Habits è locale: nessuna registrazione, nessuna pubblicità. Il premium opzionale sblocca abitudini illimitate.

Termini di utilizzo: https://habit-ring.lovable.app/terms
Informativa sulla privacy: https://habit-ring.lovable.app/privacy

#### Dutch — nl

Ring Habits helpt je blijvende gewoontes op te bouwen met een eenvoudige, mooie interface. Volg dagelijkse taken, bouw streaks op en blijf gemotiveerd.

• Ingedrukt houden om te voltooien: Houd elke gewoontecirkel ongeveer 1,4 seconden ingedrukt om deze als voltooid te markeren.
• Tik voor details: Eén tik opent het overzicht — Gewoontesterkte-score, vormingsfase, consistentieraster en snelle acties.
• Gewoontesterkte: Elke gewoonte krijgt een score van 0 tot 100 en doorloopt zes fasen (Starting → Mastering). Een binnenste ring op het dashboard toont je voortgang; een fase-badge verschijnt vanaf Developing.
• Jouw gewoontes, jouw manier: Maak aangepaste gewoontes of begin met presets. Stel doelen, herinneringen en categorieën in.
• Dagelijkse, wekelijkse of maandelijkse gewoontes: Stel een doel per dag, week of maand in en zie je voortgang met C/N-tellers.
• Streaks en statistieken: Bekijk geschiedenis, huidige streak en trendgrafieken. Tik op grafiekpunten voor dagdetails.
• Zachte herinneringen: Lokale meldingen staan standaard aan bij het maken van een gewoonte (uit te zetten). Sterktemeldingen waarschuwen wanneer je dicht bij de volgende fase bent.
• Beloningen: Stel mijlpaalbeloningen in en vier je successen.
• Privacy eerst: Je gewoontes blijven op je apparaat; geen account en geen cloud-sync. Anonieme analytics en gemaskeerde session replay — nooit je titels, notities of persoonlijke identifiers.

Ring Habits is lokaal: geen aanmelding, geen advertenties. Optionele premium ontgrendelt onbeperkte gewoontes.

Gebruiksvoorwaarden: https://habit-ring.lovable.app/terms
Privacybeleid: https://habit-ring.lovable.app/privacy

---

### Keywords

> Comma-separated, no spaces after commas. Max 100 characters. Added habit strength terms where space allows.

| Locale | Keywords | Chars |
|--------|----------|-------|
| English (U.S.) | habit tracker,habits,daily habits,streak,goals,productivity,routine,reminder,self improvement | 93/100 |
| Spanish (Spain) | habitos,rutina,racha,metas,productividad,recordatorio,ejercicio,meditacion,lectura,tareas | 89/100 |
| Portuguese (Portugal) | habitos,rotina,sequencia,metas,produtividade,lembrete,exercicio,meditacao,leitura,tarefas | 89/100 |
| French | habitudes,routine,serie,objectifs,productivite,rappel,exercice,meditation,lecture,taches | 88/100 |
| German | gewohnheiten,routine,serie,ziele,produktivitat,erinnerung,sport,meditation,lesen,aufgaben | 89/100 |
| Italian | abitudini,routine,serie,obiettivi,produttivita,promemoria,esercizio,meditazione,lettura | 87/100 |
| Dutch | gewoontes,routine,streak,doelen,productiviteit,herinnering,sport,meditatie,lezen,taken | 86/100 |

---

### Notes for Reviewer

> Paste **English (U.S.)** into App Review Information → Notes. All 7 locales included for reference.

#### English (U.S.) — en

**How to complete a habit (required for testing):**
Press and HOLD a habit circle for about 1.4 seconds. A progress ring fills; when complete you feel haptic feedback and the task is marked done.

**How to open habit details (new in 2.3.0):**
A short single TAP opens the habit summary sheet (strength ring, stage, consistency grid, Manage Completions link, Stats / Edit / Remove). It does NOT complete the habit.

**Habit Strength (new in 2.3.0):**
After 3 credited completions, each habit shows a score (0–100) and a formation stage (Starting through Mastering). An inner ring on the dashboard reflects the score; a stage badge appears from Developing upward. Crossing a stage boundary may show a full-screen celebration (at most one celebration per habit per 12 hours).

**First launch:**
New users see a short onboarding that teaches the tap-and-hold gesture. Tap "Skip" to go straight to the task list. On a fresh install the app shows the Free plan (not Premium).

**Reminders:**
When creating a habit, the Reminder toggle defaults to ON (user can turn it off before saving). After the very first successful habit completion, a congratulations popup appears. If that habit does not have reminders enabled, the popup offers a CTA to turn reminders on. Strength notifications (proximity / reversion) require notification permission and fire at 9:00 local time; they include Mark done and Later actions.

**How to reach the paywall / In-App Purchases:**
1. Create 2 habits (tap +, configure, then press and hold to complete if needed).
2. Tap the + button to add a 3rd habit — the paywall appears.
3. Alternatively: Settings → Your plan → tap the Free row.
4. The paywall shows Monthly (auto-renewable), Yearly (auto-renewable), and Lifetime (one-time), each with title, billing period, price from the App Store, auto-renewal disclosure, and links to Terms of Use and Privacy Policy.

**Restore Purchases:**
Available on the paywall and in Settings → Your plan → Restore Purchases.

**Manage Subscription:**
Settings → Your plan → Manage Subscription (visible when a subscription is active).

**Architecture / privacy:**
The app is local-first with no account or login. Habit data is stored on-device with SwiftData and is never uploaded. Notifications are local only (UserNotifications). In-app purchases are processed by Apple; the app does not collect payment data. The app sends anonymous product analytics to PostHog (aggregate usage, no habit content or personal identifiers), including masked session replay (text inputs and images masked). A minimal Firebase Analytics event set (first_open, purchase) is used for Google Ads conversion measurement; default consent keys are set in Info.plist (no ATT / IDFA prompt).

**Legal links:**
Terms of Use (EULA): https://habit-ring.lovable.app/terms
Privacy Policy: https://habit-ring.lovable.app/privacy

**Sandbox test account:**
Email: *(paste your Sandbox Apple ID)*
Password: *(paste your Sandbox password)*

**Support:**
Support URL: https://habit-ring.lovable.app
Email: habit-tracker@fooshi.co

#### Spanish (Spain) — es

**Cómo completar un hábito:**
Mantén pulsado un círculo de hábito unos 1,4 segundos. Un anillo de progreso se llena; al completarse, recibes retroalimentación háptica y la tarea se marca como hecha.

**Cómo abrir los detalles del hábito (nuevo en 2.3.0):**
Un toque corto abre la ficha resumen (fuerza, etapa, cuadrícula, enlace Gestionar completados, Estadísticas / Editar / Eliminar). No completa el hábito.

**Fuerza del hábito (nuevo en 2.3.0):**
Tras 3 completados acreditados, cada hábito muestra una puntuación (0–100) y una etapa de formación. Un anillo interior refleja el progreso. Al cruzar una etapa puede aparecer una celebración a pantalla completa (máximo una cada 12 h por hábito).

**Primer inicio:**
Los nuevos usuarios ven un breve onboarding. Toca "Omitir" para ir directamente a la lista. En una instalación nueva la app muestra el plan Gratuito.

**Recordatorios:**
El interruptor de Recordatorio está activado por defecto al crear un hábito. Tras el primer completado aparece un aviso de felicitación. Las notificaciones de fuerza requieren permiso y se envían a las 9:00 con acciones Marcar hecho / Más tarde.

**Paywall / compras:**
Crea 2 hábitos, luego intenta añadir un 3.º, o ve a Ajustes → Tu plan → fila Gratuito. Restaurar compras en el paywall o en Ajustes.

**Arquitectura / privacidad:**
Local, sin cuenta. Analítica anónima (PostHog, replay enmascarado) y Firebase mínimo para conversiones de anuncios. Sin IDFA.

**Legal:** https://habit-ring.lovable.app/terms · https://habit-ring.lovable.app/privacy
**Soporte:** https://habit-ring.lovable.app · habit-tracker@fooshi.co

#### Portuguese (Portugal) — pt-PT

**Como concluir um hábito:**
Mantenha premido um círculo de hábito cerca de 1,4 segundos. Um anel de progresso enche-se; ao completar, recebe feedback háptico e a tarefa fica marcada como feita.

**Como abrir detalhes do hábito (novo em 2.3.0):**
Um toque curto abre a ficha resumo (força, fase, grelha, Gerir conclusões, Estatísticas / Editar / Remover). Não conclui o hábito.

**Força do hábito (novo em 2.3.0):**
Após 3 conclusões creditadas, cada hábito mostra uma pontuação (0–100) e uma fase de formação. Um anel interior reflete o progresso. Ao avançar de fase pode aparecer uma celebração em ecrã completo (máximo uma a cada 12 h por hábito).

**Primeiro arranque:**
Onboarding breve; toque "Ignorar" para ir à lista. Instalação nova mostra plano Gratuito.

**Lembretes:**
Lembretes ativos por predefinição ao criar um hábito. Notificações de força às 9:00 com Marcar feito / Mais tarde.

**Paywall:** Crie 2 hábitos e tente adicionar um 3.º, ou Definições → O seu plano → linha Gratuito. Restaurar compras no paywall ou Definições.

**Arquitetura / privacidade:** Local, sem conta. Analítica anónima e Firebase mínimo. Sem IDFA.

**Legal:** https://habit-ring.lovable.app/terms · https://habit-ring.lovable.app/privacy
**Suporte:** https://habit-ring.lovable.app · habit-tracker@fooshi.co

#### French — fr

**Comment terminer une habitude :**
Maintenez un cercle d'habitude environ 1,4 seconde. Un anneau de progression se remplit ; à la fin, retour haptique et tâche marquée comme faite.

**Ouvrir les détails (nouveau en 2.3.0) :**
Un toucher court ouvre la fiche résumé (force, étape, grille, Gérer les complétions, Stats / Modifier / Supprimer). Ne termine pas l'habitude.

**Force de l'habitude (nouveau en 2.3.0) :**
Après 3 complétions créditées, score 0–100 et étape de formation. Anneau intérieur sur le tableau de bord. Célébration plein écran possible (max. une par habitude / 12 h).

**Premier lancement :** Onboarding court ; « Ignorer » pour la liste. Plan Gratuit sur installation neuve.

**Rappels :** Activés par défaut à la création. Notifications de force à 9h avec Marquer fait / Plus tard.

**Paywall :** Créez 2 habitudes puis tentez une 3e, ou Réglages → Votre forfait → ligne Gratuit. Restaurer les achats sur le paywall ou dans Réglages.

**Architecture / confidentialité :** Local, sans compte. Analytique anonyme et Firebase minimal. Pas d'IDFA.

**Legal :** https://habit-ring.lovable.app/terms · https://habit-ring.lovable.app/privacy
**Support :** https://habit-ring.lovable.app · habit-tracker@fooshi.co

#### German — de

**Gewohnheit abschließen:**
Halte einen Gewohnheitskreis etwa 1,4 Sekunden gedrückt. Ein Fortschrittsring füllt sich; bei Abschluss haptisches Feedback und Aufgabe als erledigt markiert.

**Details öffnen (neu in 2.3.0):**
Ein kurzer Tippen öffnet die Übersicht (Stärke, Stufe, Raster, Erledigungen verwalten, Statistiken / Bearbeiten / Entfernen). Schließt die Gewohnheit nicht ab.

**Gewohnheitsstärke (neu in 2.3.0):**
Nach 3 gutgeschriebenen Abschlüssen Score 0–100 und Entwicklungsstufe. Innerer Ring im Dashboard. Vollbild-Feier möglich (max. eine pro Gewohnheit / 12 h).

**Erster Start:** Kurzes Onboarding; „Überspringen“ zur Liste. Neues Install → Gratis-Plan.

**Erinnerungen:** Standardmäßig an beim Erstellen. Stärke-Benachrichtigungen um 9:00 mit Als erledigt markieren / Später.

**Paywall:** 2 Gewohnheiten erstellen, dann 3. versuchen, oder Einstellungen → Dein Plan → Gratis-Zeile. Käufe wiederherstellen im Paywall oder Einstellungen.

**Architektur / Datenschutz:** Lokal, kein Konto. Anonyme Analytik und minimales Firebase. Kein IDFA.

**Legal:** https://habit-ring.lovable.app/terms · https://habit-ring.lovable.app/privacy
**Support:** https://habit-ring.lovable.app · habit-tracker@fooshi.co

#### Italian — it

**Completare un'abitudine:**
Tieni premuto un cerchio abitudine per circa 1,4 secondi. Un anello di progresso si riempie; al termine feedback aptico e attività segnata come fatta.

**Aprire i dettagli (novità in 2.3.0):**
Un tocco breve apre la scheda riepilogo (forza, fase, griglia, Gestisci completamenti, Statistiche / Modifica / Rimuovi). Non completa l'abitudine.

**Forza dell'abitudine (novità in 2.3.0):**
Dopo 3 completamenti accreditati, punteggio 0–100 e fase di formazione. Anello interno nella dashboard. Celebrazione a schermo intero possibile (max. una ogni 12 h per abitudine).

**Primo avvio:** Onboarding breve; "Salta" per la lista. Piano Gratuito su installazione nuova.

**Promemoria:** Attivi per impostazione predefinita alla creazione. Notifiche di forza alle 9:00 con Segna fatto / Più tardi.

**Paywall:** Crea 2 abitudini poi prova la 3a, oppure Impostazioni → Il tuo piano → riga Gratuito. Ripristina acquisti nel paywall o Impostazioni.

**Architettura / privacy:** Locale, nessun account. Analitica anonima e Firebase minimo. Nessun IDFA.

**Legal:** https://habit-ring.lovable.app/terms · https://habit-ring.lovable.app/privacy
**Supporto:** https://habit-ring.lovable.app · habit-tracker@fooshi.co

#### Dutch — nl

**Gewoonte voltooien:**
Houd een gewoontecirkel ongeveer 1,4 seconden ingedrukt. Een voortgangsring vult zich; bij voltooiing haptische feedback en taak als voltooid gemarkeerd.

**Details openen (nieuw in 2.3.0):**
Eén korte tik opent het overzicht (sterkte, fase, raster, Voltooiingen beheren, Statistieken / Bewerken / Verwijderen). Voltooit de gewoonte niet.

**Gewoontesterkte (nieuw in 2.3.0):**
Na 3 gecrediteerde voltooiingen score 0–100 en vormingsfase. Binnenste ring op dashboard. Volledig scherm viering mogelijk (max. één per gewoonte / 12 u).

**Eerste start:** Korte onboarding; "Overslaan" naar lijst. Gratis plan bij nieuwe installatie.

**Herinneringen:** Standaard aan bij aanmaken. Sterktemeldingen om 9:00 met Markeer klaar / Later.

**Paywall:** Maak 2 gewoontes en probeer een 3e, of Instellingen → Jouw plan → Gratis rij. Aankopen herstellen in paywall of Instellingen.

**Architectuur / privacy:** Lokaal, geen account. Anonieme analytics en minimaal Firebase. Geen IDFA.

**Legal:** https://habit-ring.lovable.app/terms · https://habit-ring.lovable.app/privacy
**Support:** https://habit-ring.lovable.app · habit-tracker@fooshi.co

---

### Subscription — Monthly (`co.fooshi.habitring.premium.monthly`)

> IAP metadata unchanged from 2.2.0 — verify in App Store Connect; no update required unless you changed copy.

| Locale | Display Name (30) | Description (45) |
|--------|-------------------|------------------|
| English (U.S.) | Monthly | Unlimited habits, billed monthly. |
| Spanish (Spain) | Mensual | Hábitos ilimitados, facturación mensual. |
| Portuguese (Portugal) | Mensal | Hábitos ilimitados, faturação mensal. |
| French | Mensuel | Habitudes illimitées, facturation mensuelle. |
| German | Monatlich | Unbegrenzte Gewohnheiten, monatliche Abrechnung. |
| Italian | Mensile | Abitudini illimitate, fatturazione mensile. |
| Dutch | Maandelijks | Onbeperkte gewoontes, maandelijkse facturering. |

### Subscription — Yearly (`co.fooshi.habitring.premium.yearly`)

| Locale | Display Name (30) | Description (45) |
|--------|-------------------|------------------|
| English (U.S.) | Yearly | Unlimited habits, billed yearly. |
| Spanish (Spain) | Anual | Hábitos ilimitados, facturación anual. |
| Portuguese (Portugal) | Anual | Hábitos ilimitados, faturação anual. |
| French | Annuel | Habitudes illimitées, facturation annuelle. |
| German | Jährlich | Unbegrenzte Gewohnheiten, jährliche Abrechnung. |
| Italian | Annuale | Abitudini illimitate, fatturazione annuale. |
| Dutch | Jaarlijks | Onbeperkte gewoontes, jaarlijkse facturering. |

### Subscription — Lifetime (`co.fooshi.habitring.premium.lifetime`)

| Locale | Display Name (30) | Description (45) |
|--------|-------------------|------------------|
| English (U.S.) | Lifetime | Unlock unlimited habits forever. |
| Spanish (Spain) | De por vida | Hábitos ilimitados para siempre. |
| Portuguese (Portugal) | Vitalício | Hábitos ilimitados para sempre. |
| French | À vie | Habitudes illimitées pour toujours. |
| German | Lebenslang | Unbegrenzte Gewohnheiten für immer. |
| Italian | A vita | Abitudini illimitate per sempre. |
| Dutch | Levenslang | Onbeperkte gewoontes voor altijd. |

### Subscription Group — Premium

| Locale | Display Name |
|--------|--------------|
| English (U.S.) | Premium |
| Spanish (Spain) | Premium |
| Portuguese (Portugal) | Premium |
| French | Premium |
| German | Premium |
| Italian | Premium |
| Dutch | Premium |

---

## 6. App Store Connect — version page assets

> **Goal:** Attach the build and complete the version page (screenshots, metadata, review info).
> **Where you'll work:** App Store Connect, Device or Simulator (screenshots)
> **Outcome:** Build selected, all locales filled, review notes pasted, age rating and privacy confirmed.

> **Dependency:** Section 4 version exists. Section 5 text ready to paste.

### 6.a Screenshots

| # | Where | Action |
|---|-------|--------|
| 1 | Device / Simulator | Capture per device size required by ASC (6.9", 6.7", 6.5", 5.5" iPhone). |
| 2 | Device / Simulator | Per **localized** listing if screenshots contain text. |
| 3 | Device / Simulator | **New for 2.3.0:** habit summary sheet (strength ring + grid), dashboard with inner strength ring and stage badge, optional stage celebration overlay. Retain: task list, onboarding, habit config, stats, paywall. |
| 4 | App Store Connect | Upload screenshots on the version page per locale. |

### 6.b Paste localized metadata

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | On the version page, select each locale from the language dropdown. |
| 2 | App Store Connect | Paste **What's New** from Section 5. |
| 3 | App Store Connect | Paste updated **Description** (all locales — Habit Strength copy). |
| 4 | App Store Connect | Optionally update **Promotional Text** from Section 5. |

### 6.c Select build

> **Dependency:** Section 3.d — build **Ready to Submit** in **Activity** (not only visible in TestFlight).

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Open the version page (**App Store** → **2.3.0**). |
| 2 | App Store Connect | Scroll to **Build**. |
| 3a | App Store Connect | Click **+** (or **Select a build**) → choose **2.3.0 (7)**. |
| 3b | App Store Connect | **Resubmission — old rejected build still attached:** remove the previous build first, then add the new one. |
| 4 | App Store Connect | If the new build does not appear: confirm **Activity** shows **Ready to Submit**, marketing version matches **2.3.0**, export compliance complete — wait 10–30 minutes and refresh. |
| 5 | App Store Connect | After selecting, verify the version page shows build **7**. |

### 6.d App Review Information (language-agnostic fields)

| Field | Where | Value |
|-------|-------|--------|
| Sign-in required | App Store Connect | No |
| Contact — First name | App Store Connect | *(your name)* |
| Contact — Last name | App Store Connect | *(your name)* |
| Contact — Phone | App Store Connect | *(your phone)* |
| Contact — Email | App Store Connect | habit-tracker@fooshi.co |
| Notes | App Store Connect | Paste **English** Notes for Reviewer from Section 5 (fill in Sandbox credentials) |

### 6.e Age Rating & Privacy

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Reconfirm **Age Rating** questionnaire (notifications, IAP unchanged in nature; still declare purchases). |
| 2 | App Store Connect | **App Privacy** nutrition labels must match collection: Usage Data / Product Interaction for **Analytics** (PostHog, including masked session replay) and **Advertising** (Firebase for Google Ads conversion). Data not linked to identity. No IDFA / no ATT prompt in this build. |
| 3 | App Store Connect | Confirm Privacy Policy URL: `https://habit-ring.lovable.app/privacy` — policy should mention analytics, session replay, and Firebase conversion measurement. |

---

## 7. App Store Connect — app-level settings

> **Goal:** Verify app-level settings that persist across versions (EULA, subscriptions, privacy).
> **Where you'll work:** App Store Connect, Browser (hosted terms URL)
> **Outcome:** IAP group, EULA, and app information confirmed.

### 7.a App Information

| Field | Where | Value |
|-------|-------|-------|
| Name | App Store Connect | Ring Habits – Streak & Reward |
| Subtitle | App Store Connect | *(localized — Section 5 Subtitle table)* |
| Privacy Policy URL | App Store Connect | https://habit-ring.lovable.app/privacy |
| Support URL | App Store Connect | https://habit-ring.lovable.app |
| Category | App Store Connect | Lifestyle (primary) |
| Content Rights | App Store Connect | Does not contain third-party content |
| Copyright | App Store Connect | © 2026 Fooshi |

### 7.b App Store server & EULA

| Field | Where | Value |
|-------|-------|-------|
| License Agreement | App Store Connect | Apple's Standard EULA **or** custom EULA URL |
| EULA (if subscriptions) | App Store Connect + Browser | Link to terms: https://habit-ring.lovable.app/terms — verify URL loads |

### 7.c Subscriptions (freemium)

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | **Subscriptions** → group **Premium** → verify metadata + pricing for all 3 products. |
| 2 | App Store Connect | **Subscription Group Localization** → display name localized (all 7 languages). |
| 3 | App Store Connect | Confirm each IAP is **Ready to Submit** and attached to version **2.3.0**. |
| 4 | App Store Connect | Confirm **Review Information** screenshot for paywall if requested. |

### 7.d Sandbox testers

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | **Users and Access → Sandbox → Testers**. |
| 2 | App Store Connect | Create or reuse a dedicated Sandbox Apple ID for review. |
| 3 | App Store Connect | Paste credentials into Notes for Reviewer (Section 6.d). |

---

## 8. Submit for review

> **Goal:** Final checklist and submit to App Review.
> **Where you'll work:** App Store Connect
> **Outcome:** Version in **Waiting for Review**; monitoring and rejection recovery plan documented.

> **Dependency:** Sections 2–7 complete. Build selected. All required locales filled.

### 8.a Final review on version page

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Confirm build **2.3.0 (7)** attached. |
| 2 | App Store Connect | Confirm **What's New** filled for all 7 locales. |
| 3 | App Store Connect | Confirm **Description** updated (all locales). |
| 4 | App Store Connect | Confirm screenshots current (include Habit Strength UI). |
| 5 | App Store Connect | Export compliance answered (typically: No encryption beyond HTTPS → exempt). |
| 6 | App Store Connect | Content rights, advertising identifier (No), IDFA (No) confirmed. |
| 7 | App Store Connect | Paid Apps Agreement active; Sandbox credentials in notes. |

### 8.b Submit

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Click **Add for Review** (or **Submit for Review**). |
| 2 | App Store Connect | Answer submission questionnaire (release type: manual or automatic). |
| 3 | App Store Connect | Confirm **Submit**. |

### 8.c After submission

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Monitor **App Review** status. |
| 2 | Codebase + Xcode + App Store Connect | If **Rejected**: read Resolution Center notes, fix in Codebase, increment build in Xcode (e.g. to **8**), re-upload (Section 3), reuse version **2.3.0** (Section 4.b), **remove the old build and attach the new build** (Section 6.c), resubmit. |
| 3 | App Store Connect | On **Approved**, release manually or wait for automatic release per your setting. |

---

## Open risks before submit

| Risk | Severity | Action |
|------|----------|--------|
| Version numbers not bumped in repo | **High** | Repo still shows 2.2.0 / 6 (same as live). Bump to **2.3.0 / 7** before archiving (Section 2.b). |
| Hosted privacy policy may not mention Habit Strength notifications | Medium | Confirm policy covers local notifications including strength proximity / reversion nudges. |
| App Privacy labels still say "no data" / omit analytics | **High** | Update ASC App Privacy for PostHog + Firebase + replay (unchanged from 2.2.0 requirement). |
| Sandbox credentials blank in reviewer notes | **High** | Create/paste Sandbox tester before submit. |
| Reviewer notes still say "2 s hold" / "context menu on tap" | Medium | This guide updates to **1.4 s hold** and **summary sheet on tap** — paste Section 5 Notes. |
| Simulator App Review prompt Submit disabled | Low | Expected in Simulator; real-device TestFlight build is the real test. |
| Firebase default consent keys (new) | Medium | Reviewers may ask about ad measurement — Notes explain Info.plist defaults; no ATT / IDFA. |
| Screenshot set still shows old tap-to-menu UI | Medium | Recapture with summary sheet and strength ring before submit. |
