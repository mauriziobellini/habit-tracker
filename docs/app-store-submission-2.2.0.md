# App Store Submission — v2.2.0 (build 6)

> **New marketing version** — retention experiment (opt-out reminders + first-completion return prime), stats chart data-point tap, PostHog session replay (masked). Builds on shipping freemium / weekly-monthly habits from 2.0.0.

## Pre-submission checklist

- [ ] Unit and UI tests pass on the `HabitTracker` scheme
- [ ] Confirm `MARKETING_VERSION` **2.2.0** and `CURRENT_PROJECT_VERSION` **6** in Xcode (already set in repo)
- [ ] Device: create a habit → Reminder toggle defaults **on**; can turn off before save
- [ ] Device: first habit completion shows congratulations; if reminders off, opt-in CTA works
- [ ] Device: Stats charts — tap a data point and see detail
- [ ] Sandbox: fresh install shows Free plan; paywall on 3rd habit
- [ ] Privacy Policy live: https://habit-ring.lovable.app/privacy
- [ ] Terms of Use live: https://habit-ring.lovable.app/terms
- [ ] **Paid Apps Agreement** Active in App Store Connect → Business
- [ ] IAP products still Ready: `co.fooshi.habitring.premium.monthly`, `.yearly`, `.lifetime`
- [ ] What's New filled for all 7 locales
- [ ] Description privacy copy updated (analytics + masked session replay) for all 7 locales
- [ ] Notes for Reviewer pasted (English) with Sandbox credentials
- [ ] Screenshots current (habit config with Reminder on; first-completion popup optional)
- [ ] App Privacy nutrition labels include analytics / product interaction (session replay)
- [ ] Archive validated and uploaded; Activity status **Ready to Submit**
- [ ] Build **2.2.0 (6)** selected on the new version page

---

## 1. Pre-release verification

> **Goal:** Confirm the app is technically sound and App Store-ready before archiving or uploading.
> **Where you'll work:** Terminal, Xcode, Codebase, Browser, App Store Connect (read-only checks)
> **Outcome:** Tests pass, no debug leakage, IAP IDs aligned, legal URLs live, version numbers confirmed, changelog ready for Section 5.

### 1.a Code & tests

| # | Where | Action |
|---|-------|--------|
| 1 | Terminal / Xcode | Run unit and UI tests on the `HabitTracker` scheme (Xcode → Product → Test, or `xcodebuild test`). |
| 2 | Codebase | Confirm no debug-only code paths, test launch arguments (`--uitesting-premium` / `--uitesting-free`), or placeholder content ship in Release. |
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
| 1 | Codebase | Current values in `project.yml` / `HabitTracker.xcodeproj/project.pbxproj`: already **2.2.0** / **6**. |
| 2 | — | **Marketing version:** `2.2.0`. Not `2.1.0` — that train is already approved and closed, and reusing it fails upload with error 90062 / 90186. |
| 3 | — | **Build number:** `6` (must be higher than any previously uploaded build; 2.1.0 used build 5). |
| 4 | Codebase | Recorded in this document header — no further bump needed unless you upload again. |

### 1.d Prepare release notes source

| # | Where | Action |
|---|-------|--------|
| 1 | Codebase | User-visible changes since 2.0.0 (git: `a1532b7`, `f1ae7ea`, experiment doc): |
| — | — | • Reminders default **on** when creating a habit (opt-out); editing existing habits does not force-enable. |
| — | — | • After the very first habit completion, a congratulations popup appears; if that habit has reminders off, a CTA can enable them. |
| — | — | • Stats charts: tap a data point for clearer day-by-day detail. |
| 2 | — | This list becomes **What's New** in Section 5. |

---

## 2. Xcode — version bump & build

> **Goal:** Confirm marketing version and build number match App Store Connect before archiving.
> **Where you'll work:** Xcode, Codebase (`project.yml`)
> **Outcome:** `MARKETING_VERSION` = 2.2.0 and `CURRENT_PROJECT_VERSION` = 6; signing verified; device destination selected.

> **Dependency:** Complete Section 1 first.

### 2.a Open project

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | Open `HabitTracker.xcodeproj`. |
| 2 | Xcode | Select the **HabitTracker** target → **General** tab. |

### 2.b Set version fields

| # | Where | Action |
|---|-------|--------|
| 1 | Xcode | Confirm **Version** is `2.2.0` (already set). |
| 2 | Xcode | Confirm **Build** is `6` (already set; must stay higher than any prior upload). |
| 3 | Codebase | `project.yml` already has `MARKETING_VERSION: "2.2.0"` and `CURRENT_PROJECT_VERSION: "6"` — keep in sync if you regenerate via XcodeGen. |

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
| 3 | App Store Connect | If status is **Missing Compliance**, open the build → answer the export-encryption questionnaire (typically **No** — app uses only standard HTTPS). Apple re-processes after you submit; wait again. |
| 4 | — | **TestFlight ≠ version page:** a build can appear in TestFlight before it is selectable on the App Store version page. Only proceed to Section 6.c when **Activity** shows **Ready to Submit**. |
| 5 | — | **Do not proceed to Section 6.c until processing completes.** |

---

## 4. App Store Connect — create version

> **Goal:** Create the App Store version row so version-specific fields and the build picker are available.
> **Where you'll work:** App Store Connect
> **Outcome:** New iOS version **2.2.0** exists matching Xcode; pricing confirmed.

> **Dependency:** Section 3 upload started (version can be created while build processes).
> **Why now:** Version-specific fields (What's New, build picker, screenshots per version) require a version row.

### 4.a Open the app

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | [App Store Connect](https://appstoreconnect.apple.com) → **My Apps**. |
| 2 | App Store Connect | Select **Ring Habits – Streak & Reward** (`co.fooshi.habitring`). |

### 4.b Create or reuse version

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Left sidebar → **App Store** (under *iOS App*). |
| 2a | App Store Connect | Click **+** / **Add Version** → enter **2.2.0** (must match Xcode marketing version). |
| 2b | — | This is a **new version**, not a resubmission of 2.0.0. |
| 3 | — | Recorded: **new version 2.2.0**. |

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

- Reminders now default on when you create a habit — turn them off anytime before saving.
- Celebrate your first completion; if reminders were off, enable them right from the congratulations popup.
- Tap chart data points in Stats for clearer day-by-day insight.

#### Spanish (Spain) — es

- Los recordatorios se activan por defecto al crear un hábito — puedes desactivarlos en cualquier momento antes de guardar.
- Celebra tu primer completado; si los recordatorios estaban desactivados, actívalos desde el aviso de felicitación.
- Toca los puntos del gráfico en Estadísticas para ver el detalle día a día.

#### Portuguese (Portugal) — pt-PT

- Os lembretes passam a estar ativos por predefinição ao criar um hábito — pode desativá-los antes de guardar.
- Celebre a sua primeira conclusão; se os lembretes estavam desligados, ative-os a partir do aviso de parabéns.
- Toque nos pontos do gráfico em Estatísticas para ver o detalhe dia a dia.

#### French — fr

- Les rappels sont désormais activés par défaut à la création d'une habitude — désactivez-les avant d'enregistrer si vous le souhaitez.
- Célébrez votre première complétion ; si les rappels étaient désactivés, activez-les depuis la fenêtre de félicitations.
- Touchez les points du graphique dans Stats pour un détail jour par jour plus clair.

#### German — de

- Erinnerungen sind beim Erstellen einer Gewohnheit standardmäßig an — jederzeit vor dem Speichern ausschaltbar.
- Feiere deinen ersten Abschluss; waren Erinnerungen aus, kannst du sie direkt im Glückwunsch-Popup einschalten.
- Tippe in den Statistiken auf Diagrammpunkte für klarere Tagesdetails.

#### Italian — it

- I promemoria sono ora attivi per impostazione predefinita quando crei un'abitudine — disattivali quando vuoi prima di salvare.
- Festeggia il primo completamento; se i promemoria erano disattivati, attivali dal popup di congratulazioni.
- Tocca i punti del grafico in Statistiche per dettagli giorno per giorno più chiari.

#### Dutch — nl

- Herinneringen staan standaard aan bij het maken van een gewoonte — zet ze uit wanneer je wilt vóór het opslaan.
- Vier je eerste voltooiing; stonden herinneringen uit, schakel ze in via het felicitatiepopup.
- Tik in Statistieken op grafiekpunten voor duidelijkere details per dag.

---

### Promotional Text

> Limit: 170 characters. Optional — update for this retention-focused release.

| Locale | Text | Chars |
|--------|------|-------|
| English (U.S.) | Reminders now help you come back. On by default when you create a habit — plus a cheer for your first completion. | 112/170 |
| Spanish (Spain) | Los recordatorios te ayudan a volver. Activos al crear un hábito, más un aviso en tu primer completado. | 99/170 |
| Portuguese (Portugal) | Os lembretes ajudam-no a regressar. Ativos ao criar um hábito, mais um aviso na primeira conclusão. | 96/170 |
| French | Les rappels vous aident à revenir. Activés à la création, plus un encouragement à la première complétion. | 103/170 |
| German | Erinnerungen holen dich zurück. Standardmäßig an beim Erstellen — plus Glückwunsch beim ersten Abschluss. | 102/170 |
| Italian | I promemoria ti aiutano a tornare. Attivi alla creazione, più un messaggio al primo completamento. | 96/170 |
| Dutch | Herinneringen helpen je terugkomen. Standaard aan bij aanmaken — plus een felicitatie bij je eerste voltooiing. | 110/170 |

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

> Limit: 4,000 characters per locale. Include legal links at the end of every locale. Privacy copy updated for anonymous analytics and masked session replay.

#### English (U.S.) — en

Ring Habits helps you build lasting habits with a simple, beautiful interface. Track daily tasks, build streaks, and stay motivated.

• Tap and hold to complete: Press and hold each habit circle for 2 seconds to mark it done. Simple and satisfying.
• Your habits, your way: Create custom habits or start from presets (fitness, health, learning, social). Set goals, reminders, and categories.
• Daily, weekly, or monthly habits: Set a target per day, week, or month and see your progress with C/N counters.
• Streaks and stats: See your completion history, current streak, and trend charts. Filter by time window and category. Tap chart points for day-level detail.
• Gentle reminders: Local notifications default on when you create a habit (you can turn them off). No account or server required.
• Rewards: Set milestone rewards (e.g. "3-day streak: treat yourself") and get a celebration when you hit them.
• Privacy-first: Your habits stay on your device; no account and no cloud sync of habit data. We use anonymous analytics to improve the app and measure ads, and masked session replay to understand usability — never your habit titles, notes, or personal identifiers.

Ring Habits is local-first: no sign-up, no ads. Optional premium unlocks unlimited habits. Perfect for daily, weekly, or monthly routines — exercise, meditation, reading, or anything you want to do consistently.

Terms of Use: https://habit-ring.lovable.app/terms
Privacy Policy: https://habit-ring.lovable.app/privacy

#### Spanish (Spain) — es

Ring Habits te ayuda a crear hábitos duraderos con una interfaz sencilla y atractiva. Registra tareas diarias, construye rachas y mantente motivado.

• Mantén pulsado para completar: Mantén pulsado cada círculo de hábito durante 2 segundos para marcarlo como hecho.
• Tus hábitos, a tu manera: Crea hábitos personalizados o empieza con plantillas (fitness, salud, aprendizaje, social). Define metas, recordatorios y categorías.
• Hábitos diarios, semanales o mensuales: Establece un objetivo por día, semana o mes y consulta tu progreso con contadores C/N.
• Rachas y estadísticas: Consulta tu historial, racha actual y gráficos de tendencia. Toca los puntos del gráfico para el detalle diario.
• Recordatorios suaves: Las notificaciones locales se activan por defecto al crear un hábito (puedes desactivarlas). Sin cuenta ni servidor.
• Recompensas: Define recompensas por hitos (p. ej. "racha de 3 días: date un capricho") y celebra cuando las alcances.
• Privacidad primero: Tus hábitos permanecen en el dispositivo; sin cuenta ni sincronización en la nube. Usamos analítica anónima para mejorar la app y medir anuncios, y reproducción de sesión enmascarada para la usabilidad — nunca títulos, notas ni identificadores personales.

Ring Habits es local: sin registro, sin anuncios. La versión premium opcional desbloquea hábitos ilimitados. Ideal para rutinas diarias, semanales o mensuales.

Términos de uso: https://habit-ring.lovable.app/terms
Política de privacidad: https://habit-ring.lovable.app/privacy

#### Portuguese (Portugal) — pt-PT

O Ring Habits ajuda-o a criar hábitos duradouros com uma interface simples e bonita. Acompanhe tarefas diárias, construa sequências e mantenha-se motivado.

• Toque e mantenha para concluir: Mantenha premido cada círculo de hábito durante 2 segundos para o marcar como feito.
• Os seus hábitos, à sua maneira: Crie hábitos personalizados ou comece com predefinições (fitness, saúde, aprendizagem, social). Defina metas, lembretes e categorias.
• Hábitos diários, semanais ou mensais: Defina uma meta por dia, semana ou mês e veja o seu progresso com contadores C/N.
• Sequências e estatísticas: Veja o histórico, a sequência atual e gráficos de tendência. Toque nos pontos do gráfico para o detalhe diário.
• Lembretes suaves: As notificações locais ficam ativas por predefinição ao criar um hábito (pode desativá-las). Sem conta nem servidor.
• Recompensas: Defina recompensas por marcos (ex.: "sequência de 3 dias: mime-se") e celebre quando as atingir.
• Privacidade em primeiro lugar: Os hábitos ficam no dispositivo; sem conta nem sincronização na nuvem. Usamos analítica anónima para melhorar a app e medir anúncios, e reprodução de sessão mascarada para usabilidade — nunca títulos, notas nem identificadores pessoais.

O Ring Habits é local: sem registo, sem anúncios. O premium opcional desbloqueia hábitos ilimitados. Perfeito para rotinas diárias, semanais ou mensais.

Termos de utilização: https://habit-ring.lovable.app/terms
Política de privacidade: https://habit-ring.lovable.app/privacy

#### French — fr

Ring Habits vous aide à créer des habitudes durables avec une interface simple et élégante. Suivez vos tâches quotidiennes, construisez des séries et restez motivé.

• Appuyez et maintenez pour terminer : Maintenez chaque cercle d'habitude pendant 2 secondes pour le marquer comme fait.
• Vos habitudes, à votre façon : Créez des habitudes personnalisées ou commencez avec des modèles (fitness, santé, apprentissage, social). Définissez objectifs, rappels et catégories.
• Habitudes quotidiennes, hebdomadaires ou mensuelles : Fixez un objectif par jour, semaine ou mois et suivez votre progression avec des compteurs C/N.
• Séries et statistiques : Consultez votre historique, série actuelle et graphiques. Touchez les points du graphique pour le détail journalier.
• Rappels doux : Les notifications locales sont activées par défaut à la création (vous pouvez les désactiver). Sans compte ni serveur.
• Récompenses : Définissez des récompenses par palier (ex. « série de 3 jours : faites-vous plaisir ») et célébrez vos réussites.
• Confidentialité d'abord : Vos habitudes restent sur l'appareil ; pas de compte ni de sync cloud. Nous utilisons une analytique anonyme pour améliorer l'app et mesurer les pubs, et une relecture de session masquée pour l'ergonomie — jamais vos titres, notes ou identifiants personnels.

Ring Habits est local : sans inscription, sans publicité. Le premium optionnel débloque des habitudes illimitées. Idéal pour les routines quotidiennes, hebdomadaires ou mensuelles.

Conditions d'utilisation : https://habit-ring.lovable.app/terms
Politique de confidentialité : https://habit-ring.lovable.app/privacy

#### German — de

Ring Habits hilft dir, dauerhafte Gewohnheiten mit einer einfachen, schönen Oberfläche aufzubauen. Verfolge tägliche Aufgaben, baue Serien auf und bleib motiviert.

• Gedrückt halten zum Abschließen: Halte jeden Gewohnheitskreis 2 Sekunden lang gedrückt, um ihn als erledigt zu markieren.
• Deine Gewohnheiten, dein Weg: Erstelle eigene Gewohnheiten oder starte mit Vorlagen (Fitness, Gesundheit, Lernen, Soziales). Setze Ziele, Erinnerungen und Kategorien.
• Tägliche, wöchentliche oder monatliche Gewohnheiten: Setze ein Ziel pro Tag, Woche oder Monat und sieh deinen Fortschritt mit C/N-Zählern.
• Serien und Statistiken: Sieh Verlauf, aktuelle Serie und Trenddiagramme. Tippe auf Diagrammpunkte für Tagesdetails.
• Sanfte Erinnerungen: Lokale Benachrichtigungen sind beim Erstellen standardmäßig an (abschaltbar). Kein Konto, kein Server.
• Belohnungen: Setze Meilenstein-Belohnungen (z. B. „3-Tage-Serie: gönn dir etwas“) und feiere deine Erfolge.
• Datenschutz zuerst: Deine Gewohnheiten bleiben auf dem Gerät; kein Konto, keine Cloud-Sync. Wir nutzen anonyme Analytik zur App-Verbesserung und Werbemessung sowie maskierte Session-Replays für Usability — niemals Titel, Notizen oder personenbezogene Kennungen.

Ring Habits ist lokal: keine Anmeldung, keine Werbung. Optionales Premium schaltet unbegrenzte Gewohnheiten frei. Perfekt für tägliche, wöchentliche oder monatliche Routinen.

Nutzungsbedingungen: https://habit-ring.lovable.app/terms
Datenschutzrichtlinie: https://habit-ring.lovable.app/privacy

#### Italian — it

Ring Habits ti aiuta a costruire abitudini durature con un'interfaccia semplice e bella. Tieni traccia delle attività quotidiane, costruisci serie e resta motivato.

• Tieni premuto per completare: Tieni premuto ogni cerchio abitudine per 2 secondi per segnarlo come fatto.
• Le tue abitudini, a modo tuo: Crea abitudini personalizzate o inizia con preset (fitness, salute, apprendimento, social). Imposta obiettivi, promemoria e categorie.
• Abitudini giornaliere, settimanali o mensili: Imposta un obiettivo per giorno, settimana o mese e vedi i progressi con contatori C/N.
• Serie e statistiche: Consulta cronologia, serie attuale e grafici. Tocca i punti del grafico per il dettaglio giornaliero.
• Promemoria delicati: Le notifiche locali sono attive per impostazione predefinita alla creazione (puoi disattivarle). Nessun account, nessun server.
• Ricompense: Imposta ricompense per traguardi (es. "serie di 3 giorni: concediti qualcosa") e festeggia i successi.
• Privacy prima di tutto: Le abitudini restano sul dispositivo; nessun account né sync cloud. Usiamo analitica anonima per migliorare l'app e misurare gli annunci, e replay di sessione mascherati per l'usabilità — mai titoli, note o identificatori personali.

Ring Habits è locale: nessuna registrazione, nessuna pubblicità. Il premium opzionale sblocca abitudini illimitate. Perfetto per routine giornaliere, settimanali o mensili.

Termini di utilizzo: https://habit-ring.lovable.app/terms
Informativa sulla privacy: https://habit-ring.lovable.app/privacy

#### Dutch — nl

Ring Habits helpt je blijvende gewoontes op te bouwen met een eenvoudige, mooie interface. Volg dagelijkse taken, bouw streaks op en blijf gemotiveerd.

• Ingedrukt houden om te voltooien: Houd elke gewoontecirkel 2 seconden ingedrukt om deze als voltooid te markeren.
• Jouw gewoontes, jouw manier: Maak aangepaste gewoontes of begin met presets (fitness, gezondheid, leren, sociaal). Stel doelen, herinneringen en categorieën in.
• Dagelijkse, wekelijkse of maandelijkse gewoontes: Stel een doel per dag, week of maand in en zie je voortgang met C/N-tellers.
• Streaks en statistieken: Bekijk geschiedenis, huidige streak en trendgrafieken. Tik op grafiekpunten voor dagdetails.
• Zachte herinneringen: Lokale meldingen staan standaard aan bij het maken van een gewoonte (uit te zetten). Geen account, geen server.
• Beloningen: Stel mijlpaalbeloningen in (bijv. "3-dagen streak: trakteer jezelf") en vier je successen.
• Privacy eerst: Je gewoontes blijven op je apparaat; geen account en geen cloud-sync. We gebruiken anonieme analytics om de app te verbeteren en ads te meten, en gemaskeerde session replay voor usability — nooit je titels, notities of persoonlijke identifiers.

Ring Habits is lokaal: geen aanmelding, geen advertenties. Optionele premium ontgrendelt onbeperkte gewoontes. Perfect voor dagelijkse, wekelijkse of maandelijkse routines.

Gebruiksvoorwaarden: https://habit-ring.lovable.app/terms
Privacybeleid: https://habit-ring.lovable.app/privacy

---

### Keywords

> Comma-separated, no spaces after commas. Max 100 characters. Unchanged from 2.0.0 unless you want ASO tweaks.

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

**Reminders (new in 2.2.0):**
When creating a habit, the Reminder toggle defaults to ON (user can turn it off before saving). After the very first successful habit completion, a congratulations popup appears. If that habit does not have reminders enabled, the popup offers a CTA to turn reminders on.

**How to reach the paywall / In-App Purchases:**
1. Create 2 habits (tap +, configure, then press and hold to complete if needed).
2. Tap the + button to add a 3rd habit — the paywall appears.
3. The paywall shows Monthly (auto-renewable), Yearly (auto-renewable), and Lifetime (one-time), each with title, billing period, price from the App Store, auto-renewal disclosure, and links to Terms of Use and Privacy Policy.

**Restore Purchases:**
Available on the paywall and in Settings → Premium → Restore Purchases.

**Manage Subscription:**
Settings → Premium → Manage Subscription (visible when a subscription is active).

**Architecture / privacy:**
The app is local-first with no account or login. Habit data is stored on-device with SwiftData and is never uploaded. Notifications are local only (UserNotifications). In-app purchases are processed by Apple; the app does not collect payment data. The app sends anonymous product analytics to PostHog (aggregate usage, no habit content or personal identifiers), including masked session replay (text inputs and images masked). A minimal Firebase Analytics event set (first_open, purchase) is used only for Google Ads conversion measurement.

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
Mantén pulsado un círculo de hábito unos 2 segundos. Un anillo de progreso se llena; al completarse, recibes retroalimentación háptica y la tarea se marca como hecha. Un toque corto abre el menú contextual (Estadísticas, Editar, Eliminar).

**Primer inicio:**
Los nuevos usuarios ven un breve onboarding. Toca "Omitir" para ir directamente a la lista. En una instalación nueva la app muestra el plan Gratuito (no Premium).

**Recordatorios (nuevo en 2.2.0):**
Al crear un hábito, el interruptor de Recordatorio está activado por defecto. Tras el primer completado exitoso aparece un aviso de felicitación; si ese hábito no tiene recordatorios, ofrece activarlos.

**Cómo llegar al paywall / compras dentro de la app:**
1. Crea 2 hábitos.
2. Toca + para añadir un 3.er hábito — aparece el paywall.
3. El paywall muestra Mensual (renovable), Anual (renovable) y De por vida (pago único), con título, periodo, precio, aviso de renovación automática y enlaces legales.

**Restaurar compras:** En el paywall y en Ajustes → Premium → Restaurar compras.

**Arquitectura:** App local-first. Sin cuenta. Datos en el dispositivo con SwiftData. Analítica anónima (PostHog, sesión enmascarada) y Firebase mínimo para medición de anuncios.

**Enlaces legales:**
Términos: https://habit-ring.lovable.app/terms
Privacidad: https://habit-ring.lovable.app/privacy

**Cuenta sandbox:** *(tu Apple ID Sandbox)* / *(contraseña)*

#### Portuguese (Portugal) — pt-PT

**Como concluir um hábito:**
Mantenha premido um círculo de hábito durante cerca de 2 segundos. Um anel de progresso enche-se; ao concluir, sente feedback háptico e a tarefa fica marcada. Um toque curto abre o menu contextual (Estatísticas, Editar, Remover).

**Primeiro arranque:**
Novos utilizadores veem um onboarding breve. Toque em "Ignorar" para ir à lista. Numa instalação nova a app mostra o plano Gratuito (não Premium).

**Lembretes (novo em 2.2.0):**
Ao criar um hábito, o interruptor de Lembrete fica ativo por predefinição. Após a primeira conclusão bem-sucedida aparece um aviso de parabéns; se esse hábito não tiver lembretes, oferece ativá-los.

**Como chegar ao paywall / compras na app:**
1. Crie 2 hábitos.
2. Toque em + para adicionar um 3.º hábito — o paywall aparece.
3. O paywall mostra Mensal (renovável), Anual (renovável) e Vitalícia (pagamento único), com título, período, preço, aviso de renovação automática e links legais.

**Restaurar compras:** No paywall e em Definições → Premium → Restaurar compras.

**Arquitetura:** App local-first. Sem conta. Dados no dispositivo com SwiftData. Analítica anónima (PostHog, sessão mascarada) e Firebase mínimo para medição de anúncios.

**Links legais:**
Termos: https://habit-ring.lovable.app/terms
Privacidade: https://habit-ring.lovable.app/privacy

**Conta sandbox:** *(o seu Apple ID Sandbox)* / *(palavra-passe)*

#### French — fr

**Comment terminer une habitude :**
Maintenez un cercle d'habitude environ 2 secondes. Un anneau de progression se remplit ; une fois terminé, vous ressentez un retour haptique et la tâche est marquée comme faite. Un appui court ouvre le menu contextuel (Stats, Modifier, Supprimer).

**Premier lancement :**
Les nouveaux utilisateurs voient un court onboarding. Appuyez sur « Ignorer » pour accéder à la liste. Sur une installation neuve, l'app affiche le plan Gratuit (pas Premium).

**Rappels (nouveau en 2.2.0) :**
À la création, le rappel est activé par défaut. Après la première complétion réussie, une fenêtre de félicitations s'affiche ; si les rappels sont désactivés pour cette habitude, un bouton permet de les activer.

**Comment accéder au paywall / achats intégrés :**
1. Créez 2 habitudes.
2. Appuyez sur + pour ajouter une 3e habitude — le paywall s'affiche.
3. Le paywall montre Mensuel (renouvelable), Annuel (renouvelable) et À vie (achat unique), avec titre, période, prix, mention de renouvellement automatique et liens légaux.

**Restaurer les achats :** Sur le paywall et dans Réglages → Premium → Restaurer les achats.

**Architecture :** App local-first. Sans compte. Données sur l'appareil avec SwiftData. Analytique anonyme (PostHog, session masquée) et Firebase minimal pour la mesure pubs.

**Liens légaux :**
Conditions : https://habit-ring.lovable.app/terms
Confidentialité : https://habit-ring.lovable.app/privacy

**Compte sandbox :** *(votre Apple ID Sandbox)* / *(mot de passe)*

#### German — de

**Gewohnheit abschließen:**
Halte einen Gewohnheitskreis etwa 2 Sekunden gedrückt. Ein Fortschrittsring füllt sich; bei Abschluss gibt es haptisches Feedback und die Aufgabe wird als erledigt markiert. Ein kurzer Tipp öffnet das Kontextmenü (Statistiken, Bearbeiten, Entfernen).

**Erster Start:**
Neue Nutzer sehen ein kurzes Onboarding. Tippe auf „Überspringen“ für die Aufgabenliste. Bei einer Neuinstallation zeigt die App den kostenlosen Plan (nicht Premium).

**Erinnerungen (neu in 2.2.0):**
Beim Erstellen ist die Erinnerung standardmäßig an. Nach dem ersten erfolgreichen Abschluss erscheint ein Glückwunsch-Popup; waren Erinnerungen für diese Gewohnheit aus, kannst du sie dort einschalten.

**Paywall / In-App-Käufe finden:**
1. Erstelle 2 Gewohnheiten.
2. Tippe auf + für eine 3. Gewohnheit — die Paywall erscheint.
3. Die Paywall zeigt Monatlich (auto-verlängernd), Jährlich (auto-verlängernd) und Lifetime (Einmalkauf) mit Titel, Zeitraum, Preis, Auto-Verlängerungshinweis und Rechtslinks.

**Käufe wiederherstellen:** In der Paywall und unter Einstellungen → Premium → Käufe wiederherstellen.

**Architektur:** Local-first. Kein Konto. Daten auf dem Gerät mit SwiftData. Anonyme Analytik (PostHog, maskiertes Session-Replay) und minimales Firebase für Werbemessung.

**Rechtslinks:**
Nutzungsbedingungen: https://habit-ring.lovable.app/terms
Datenschutz: https://habit-ring.lovable.app/privacy

**Sandbox-Konto:** *(deine Sandbox-Apple-ID)* / *(Passwort)*

#### Italian — it

**Come completare un'abitudine:**
Tieni premuto un cerchio abitudine per circa 2 secondi. Un anello di progresso si riempie; al completamento senti il feedback aptico e l'attività viene segnata come fatta. Un tocco breve apre il menu contestuale (Statistiche, Modifica, Rimuovi).

**Primo avvio:**
I nuovi utenti vedono un breve onboarding. Tocca "Salta" per andare alla lista. Su un'installazione nuova l'app mostra il piano Gratuito (non Premium).

**Promemoria (nuovo in 2.2.0):**
Alla creazione il promemoria è attivo per impostazione predefinita. Dopo il primo completamento riuscito compare un popup di congratulazioni; se i promemoria sono disattivati per quell'abitudine, puoi attivarli da lì.

**Come raggiungere il paywall / acquisti in-app:**
1. Crea 2 abitudini.
2. Tocca + per aggiungere una 3ª abitudine — appare il paywall.
3. Il paywall mostra Mensile (rinnovabile), Annuale (rinnovabile) e Lifetime (acquisto una tantum), con titolo, periodo, prezzo, informativa sul rinnovo automatico e link legali.

**Ripristina acquisti:** Nel paywall e in Impostazioni → Premium → Ripristina acquisti.

**Architettura:** App local-first. Nessun account. Dati sul dispositivo con SwiftData. Analitica anonima (PostHog, replay mascherato) e Firebase minimo per misurazione ads.

**Link legali:**
Termini: https://habit-ring.lovable.app/terms
Privacy: https://habit-ring.lovable.app/privacy

**Account sandbox:** *(il tuo Apple ID Sandbox)* / *(password)*

#### Dutch — nl

**Gewoonte voltooien:**
Houd een gewoontecirkel ongeveer 2 seconden ingedrukt. Een voortgangsring vult zich; bij voltooiing voel je haptische feedback en de taak wordt als voltooid gemarkeerd. Een korte tik opent het contextmenu (Statistieken, Bewerken, Verwijderen).

**Eerste start:**
Nieuwe gebruikers zien een korte onboarding. Tik op "Overslaan" voor de takenlijst. Bij een nieuwe installatie toont de app het Gratis abonnement (niet Premium).

**Herinneringen (nieuw in 2.2.0):**
Bij het maken staat Herinnering standaard aan. Na de eerste geslaagde voltooiing verschijnt een felicitatiepopup; stonden herinneringen uit voor die gewoonte, kun je ze daar inschakelen.

**Paywall / in-app aankopen vinden:**
1. Maak 2 gewoontes.
2. Tik op + voor een 3e gewoonte — de paywall verschijnt.
3. De paywall toont Maandelijks (automatisch verlengbaar), Jaarlijks (automatisch verlengbaar) en Lifetime (eenmalige aankoop), met titel, periode, prijs, automatische verlenging en juridische links.

**Aankopen herstellen:** Op de paywall en in Instellingen → Premium → Aankopen herstellen.

**Architectuur:** Local-first. Geen account. Gegevens op het apparaat met SwiftData. Anonieme analytics (PostHog, gemaskeerde session replay) en minimale Firebase voor ad-meting.

**Juridische links:**
Voorwaarden: https://habit-ring.lovable.app/terms
Privacy: https://habit-ring.lovable.app/privacy

**Sandbox-account:** *(jouw Sandbox Apple ID)* / *(wachtwoord)*

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

> Subscription localizations are unchanged from 2.0.0 — only re-verify in ASC if this is your first time pasting them for a locale.

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
| 3 | Device / Simulator | Capture: task list, onboarding, habit config (**Reminder on** visible), stats (chart with data point), paywall. Optional: first-completion congratulations popup. |
| 4 | App Store Connect | Upload screenshots on the version page per locale. |

### 6.b Paste localized metadata

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | On version **2.2.0**, select each locale from the language dropdown. |
| 2 | App Store Connect | Paste **What's New** from Section 5. |
| 3 | App Store Connect | Paste updated **Description** / **Promotional Text** (and Keywords / Subtitle if not already current). |

### 6.c Select build

> **Dependency:** Section 3.d — build **Ready to Submit** in **Activity** (not only visible in TestFlight).

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | Open the version page (**App Store** → **2.2.0**). |
| 2 | App Store Connect | Scroll to **Build**. |
| 3a | App Store Connect | Click **+** (or **Select a build**) → choose **2.2.0 (6)**. |
| 3b | App Store Connect | If a wrong build is attached, remove it first, then add **5**. |
| 4 | App Store Connect | If the new build does not appear: confirm **Activity** shows **Ready to Submit**, marketing version matches **2.2.0**, export compliance complete — wait 10–30 minutes and refresh. |
| 5 | App Store Connect | After selecting, verify the version page shows build **5**. |

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
| 2 | App Store Connect | **App Privacy** nutrition labels must match collection: Usage Data / Product Interaction (and Diagnostics as applicable) for **Analytics** (PostHog, including session replay) and **Advertising** (Firebase for Google Ads conversion). Data not linked to identity (anonymous). Answer "Used for Tracking" per Apple's definition for your Firebase/ODM setup. Do **not** claim "no data collected." |
| 3 | App Store Connect | Confirm Privacy Policy URL: `https://habit-ring.lovable.app/privacy` — hosted policy should mention analytics and session replay if not already. |

---

## 7. App Store Connect — app-level settings

> **Goal:** Verify app-level settings that persist across versions (EULA, subscriptions, privacy).
> **Where you'll work:** App Store Connect, Browser (hosted terms URL)
> **Outcome:** IAP group, EULA, and app information confirmed.

> Can be done any time, but verify before submit.

### 7.a App Information

| Field | Where | Value |
|-------|-------|--------|
| Name | App Store Connect | Ring Habits – Streak & Reward |
| Subtitle | App Store Connect | *(localized — Section 5 Subtitle table)* |
| Privacy Policy URL | App Store Connect | https://habit-ring.lovable.app/privacy |
| Support URL | App Store Connect | https://habit-ring.lovable.app |
| Category | App Store Connect | Lifestyle (primary) |
| Content Rights | App Store Connect | Does not contain third-party content |
| Copyright | App Store Connect | © 2026 Fooshi |

### 7.b App Store server & EULA

| Field | Where | Value |
|-------|-------|--------|
| License Agreement | App Store Connect | Apple's Standard EULA **or** custom EULA URL |
| EULA (if subscriptions) | App Store Connect + Browser | Link to terms: https://habit-ring.lovable.app/terms — verify URL loads |

### 7.c Subscriptions (freemium)

| # | Where | Action |
|---|-------|--------|
| 1 | App Store Connect | **Subscriptions** → group **Premium** → verify metadata + pricing for all 3 products. |
| 2 | App Store Connect | **Subscription Group Localization** → display name localized (all 7 languages). |
| 3 | App Store Connect | Confirm each IAP is **Ready to Submit** and attached to version **2.2.0**. |
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
| 1 | App Store Connect | Confirm build **2.2.0 (6)** attached. |
| 2 | App Store Connect | Confirm **What's New** filled for all 7 locales. |
| 3 | App Store Connect | Confirm **Description** privacy copy updated (all locales). |
| 4 | App Store Connect | Confirm screenshots current. |
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
| 2 | Codebase + Xcode + App Store Connect | If **Rejected**: read Resolution Center notes, fix in Codebase, increment build in Xcode (e.g. to **7**), re-upload (Section 3), reuse version **2.2.0** (Section 4.b), **remove the old build and attach the new build** (Section 6.c), resubmit. |
| 3 | App Store Connect | On **Approved**, release manually or wait for automatic release per your setting. |

---

## Open risks before submit

| Risk | Severity | Action |
|------|----------|--------|
| Hosted privacy policy may not mention session replay | High | Update https://habit-ring.lovable.app/privacy to cover PostHog session replay (masked) before or with this release |
| App Privacy labels still say "no data" / omit analytics | High | Update ASC App Privacy for PostHog + Firebase + replay |
| Sandbox credentials blank in reviewer notes | High | Create/paste Sandbox tester before submit |
| OS notification permission on create (default Reminder on) | Medium | Reviewers will see the system prompt sooner — Notes explain opt-out default |
| Day-rollover stale task list (experiment doc) | Low | Not claimed in What's New; fix only if in this build |
| Google Drive MCP unavailable for extra specs | Low | Guide built from vault experiment note + git history + prior ASC metadata |
