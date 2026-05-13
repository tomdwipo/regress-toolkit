# Speaker Notes — How LLMs Work & Why This Framework Exists

> Teks bacaan per-slide untuk seminar mentorship (~25–30 menit total · 26 slide).
> Tone: percakapan natural, campur Bahasa + istilah teknis Inggris seperti yang biasa dipakai engineer Indonesia.

---

## Slide 1 — Title (Mentorship Overview) · ~30 detik

Selamat datang. Saya Tommy Dwi, Mobile Engineer di {{ORG_NAME}}.

Selama dua minggu ke depan kita akan belajar **Claude Code** dan **Auto-Workflow Framework**. Tapi tujuannya bukan sekadar bisa pakai AI buat autocomplete — kita akan bangun pipeline end-to-end dari Jira ticket sampai Pull Request, dengan **6 gate manusia** yang melindungi kualitas di setiap langkah irreversible.

Hari ini kita mulai dari fondasinya: bagaimana LLM bekerja, kenapa framework ini ada, dan bagaimana pola **RPI** membentuk semua slash command yang kita pakai sehari-hari.

---

## Slide 2 — What is an LLM · ~45 detik

Sebelum kita ngobrol soal framework, kita harus paham **LLM itu apa**.

Jawaban paling jujurnya: dia bukan otak. Dia adalah **next-token predictor**. Yang dia lakukan cuma menghitung kata berikutnya yang paling mungkin, berdasarkan semua yang ada di **context window** saat itu.

Tidak ada memori antar session. Setiap chat baru = blank slate.

Lihat contoh di slide. Tanpa konteks: "Fix the validation bug in transfer screen" → Claude tidak tahu apa-apa, hasilnya tebakan, kemungkinan besar hallucinate.

Dengan konteks: dia sudah explore `TransferScreen.kt`, sudah tahu use case-nya, sudah baca API contract — hasilnya production-quality.

**Same model, same prompt — yang beda cuma konteks.**

---

## Slide 3 — The Secret · ~50 detik

Ini rahasia yang banyak orang nggak sadar: **CLAUDE.md, memory, slash commands, agents, MCP — semuanya cuma text yang di-paste ke context window.**

Tidak ada magic. Tidak ada database. Tidak ada mekanisme khusus.

Lihat tabel di slide:
- **CLAUDE.md** = file teks yang otomatis di-paste di awal setiap conversation. Ibarat README yang dibaca colleague baru sebelum mulai kerja.
- **Memory** = sticky note di monitor — selalu kelihatan saat duduk.
- **Slash command** = macro — Anda ketik `/plan-first`, dia expand jadi instruksi penuh.
- **Agent** = colleague dengan ekspertise spesifik.
- **MCP result** = sama seperti paste output `curl` ke chat.

Semuanya ujung-ujungnya: text di dalam box yang sama. Message ke-50 masih bisa baca message ke-1, karena semuanya tetap di context.

---

## Slide 4 — It's all just chat · ~30 detik

Kalau ada **satu kalimat** yang harus Anda bawa pulang dari sesi ini, ini saja cukup:

> *It's all just chat. Context is the only thing that matters.*

CLAUDE.md = halaman pertama dari sebuah percakapan.
`/plan-first` = prompt yang ditulis dengan baik.
"Remembering" = membaca chat history sendiri.

Sekali Anda paham ini, semua fitur Claude Code jadi masuk akal.

---

## Slide 4.5 — Four Context Types · ~60 detik

Sekarang pertanyaan praktis: **konten apa yang harus ada di CLAUDE.md?**

Ada empat tipe konteks yang harus dipenuhi:

1. **Architecture** — blueprint. Di mana code tinggal, bagaimana komponen connect, batasan modul. Tanpa ini, AI taruh kode di tempat yang salah.
2. **Conventions** — aturan main. Coding standard, naming, pattern, gotcha yang kita pernah kena. Tanpa ini, AI hasilkan kode yang gaya-nya inkonsisten.
3. **API Contracts** — kamus. Endpoint, format request/response, auth. Tanpa ini, AI mengarang nama API yang nggak ada.
4. **Intent** — alasan kenapa. PRD, TRD, acceptance criteria. Tanpa ini, AI bangun yang salah.

Ketika empat tipe ini lengkap, AI berubah dari "tool" jadi "teammate". **Documentation is your AI's API.**

---

## Slide 4.6 — Mistake-Learning Loop + TOC · ~75 detik

Slide ini soal **disiplin sesi** — bagaimana setiap sesi bikin sistem makin pintar tanpa membengkakkan context.

Ada **dua gate** setiap sesi:

**Lookup gate** — di message pertama. Saya pattern-match pertanyaan ke subject yang sudah dicatalog. Saya jawab dari index dulu, sebelum re-discover apa yang sudah pernah dipecahkan. Hemat waktu, hindari kesalahan ulang.

**Save gate** — sebelum sesi selesai. Kalau ada koreksi yang landing → save. Kalau ada approach yang divalidasi tanpa pushback → juga save (ini yang sering dilewatkan: konfirmasi itu sunyi, koreksi itu ramai). Kalau ada incident yang reveal gotcha → save.

Sekarang soal **token optimization**, ini yang penting:

CLAUDE.md cuma berisi **index** — judul + satu baris hint, sekitar 150 char per item. Detail lengkap tinggal di `.docs/common-issues/{subject}.md` — file detail di-load **hanya kalau pertanyaan menyentuh subject itu**.

Hard rule kami: setelah edit CLAUDE.md, run `wc -c`. Kalau lebih dari **40 ribu char**, **trim sebelum stop**. Kenapa? Karena bloat = context budget terbakar untuk **setiap** future session.

Setiap mistake yang disimpan permanen mengajar setiap session berikutnya. Framework jadi makin pintar tanpa prompt-nya membesar.

---

## Slide 5 — Key Concepts + Tradeoff · ~50 detik

Lima istilah yang harus dipahami:

- **Tokens** — unit yang diproses model. "Implementation" = 1 token; "TransferValidationUseCase" = 4 token. Class name panjang makan budget cepat.
- **Context Window** — maximum token yang bisa dilihat sekaligus. Claude bisa sampai 200K atau 1M token.
- **Attention** — mekanisme yang fokuskan model ke bagian relevan.
- **Hallucination** — model PD-nya tinggi tapi salah.
- **Grounding** — kasih data nyata supaya output berbasis fakta, bukan tebakan.

Tradeoff fundamentalnya ada tiga: lebih banyak context → lebih sedikit hallucination, tapi lebih mahal. Task lebih kecil → akurasi lebih tinggi, tapi butuh planning. Prompt yang structured → output predictable, tapi butuh effort di awal.

**Framework ini ada justru untuk mengelola tradeoff ini secara sistematis.**

---

## Slide 6 — MCP · ~50 detik

**MCP itu curl untuk LLM.** Bukan teknologi sakti, cuma thin wrapper yang panggil REST API dan response-nya jadi context.

Bedanya dengan curl manual: Anda nggak perlu copy-paste. Tradisional: Anda curl Jira, baca JSON, paste ke prompt. Dengan MCP: Claude panggil `getJiraIssue()` — response langsung jadi context, dia bisa langsung reasoning soal ticket-nya.

Kita pakai 5 server di {{ORG_NAME}}:
- **Atlassian** — Jira + Confluence
- **Bitbucket** — Pull Request
- **Figma** — design spec
- **Jira-Attachment** — gambar dan video dari ticket
- **Video-to-Image** — extract frame 1fps dari video bug

Setiap MCP call = API call yang response-nya feed ke LLM.

---

## Slide 7 — Build Your Own MCP · ~45 detik

Yang banyak orang nggak sadar: **MCP server bisa Anda buat sendiri dalam 10 baris Python.**

Lihat contoh: decorator `@mcp.tool`, function yang return string, run dengan stdio transport. Daftarkan di `.mcp.json` di root project — Claude auto-discover, no restart, no registration.

Kalau Anda punya internal API yang sering Anda copy-paste ke chat, atau ada operasi yang berulang dilakukan tim — bungkus jadi MCP server. Produktivitas Anda lompat dramatis.

**Itu saja. Tidak ada apa-apa lagi.**

---

## Slide 8 — Why a Framework · ~50 detik

Tanpa framework, kerja dengan AI sering kelihatan seperti loop frustrasi.

Lihat dialog di slide. Developer: "Build the transfer validation feature." LLM hasilkan 500 baris yang plausible tapi salah. Developer: "Bukan begitu codebase kita." LLM hasilkan 500 baris berbeda — masih salah. Developer akhirnya nyerah, nulis manual.

Masalahnya **bukan di LLM**-nya. Masalahnya di **prompt**-nya. Solusinya tiga langkah:

1. **Constrain** solution space sebelum minta kode (`/plan-first`)
2. **Break** ke atomic task dengan diff exact (`/breakdown-design`)
3. **Provide max context** saat eksekusi (`/do-implementation`)

Itu fondasi framework kita.

---

## Slide 8.5 — L0–L3 Autonomy · ~75 detik

Industri mobil punya skala SAE 0 sampai 5 untuk tingkat self-driving. Kita adopsi konsep yang sama untuk AI di software.

- **L0** — manual coding. Manusia tulis semua.
- **L1** — Copilot. Autocomplete suggestion, manusia approve setiap line.
- **L2** — Task Agent. AI tulis kode dari ticket, tapi manusia review setiap output.
- **L3** — Workflow Agent. AI handle planning, implementing, testing, reporting end-to-end. Manusia supervise di gate.
- **L4** — Full automation. Tidak kita pursue.

Kita ada di **L3 — by design, bukan stepping stone ke L4.**

Tiga alasan kenapa L3 itu ceiling, bukan langkah sementara:

Pertama — **compliance.** Banking di Indonesia (OJK/BI) butuh akuntabilitas manusia untuk setiap kode yang masuk produksi. Merge adalah keputusan deployment. Itu harus tetap manusia.

Kedua — **risiko hallucination.** Di level kode, hallucination ketangkap test dan PR review. Di level **keputusan** — apa yang dibangun, apa yang di-release — hallucination itu fatal. L3 memisahkan dua kategori risiko ini.

Ketiga — **trust earned incrementally.** L3 sudah deliver 40+ ticket per minggu dengan 1.5 jam human effort. Marginal benefit dari L4 nggak sebanding dengan risk-nya.

---

## Slide 8.6 — 6 Human Gates · ~75 detik

Enam gate ini adalah **minimum viable governance** — bukan birokrasi sembarang, tapi titik-titik di mana judgment manusia tidak bisa digantikan.

- **Gate 1 Vision & Direction** — manusia define requirement atau pilih option dari `/plan-first`.
- **Gate 2 Start Control** — Bug atau Story dipindah manual ke "In Progress".
- **Gate 3 Mid-Work Feedback** — Jira comment selama AI build.
- **Gate 4 Code Review** — manusia review PR diff.
- **Gate 5 Merge Decision** — manusia merge PR. **Mesin tidak pernah merge.**
- **Gate 6 QA & Release** — `/feature-report` + `/qa-align` + manual testing.

Kolom kanan slide — yang **mesin TIDAK PERNAH** lakukan: merge PR, skip review, push ke production, override decision, pindah Bug/Story ke In Progress, approve release.

Total human effort: 5 menit planning + 2 menit per PR review + 30 detik untuk trigger release. Mesin handle semua di antaranya.

---

## Slide 8.7 — RPI Pattern · ~75 detik

Sekarang lineage-nya. Pipeline 3 command kita — `/plan-first`, `/breakdown-design`, `/do-implementation` — **bukan rancangan kami sendiri.** Ini implementasi domain-specific dari pola **RPI** yang dipublish Kilo Path.

**Research → Plan → Implement.**

Research divalidasi dengan **FAR**:
- **F**actual — based on actual code, no assumption
- **A**ctionable — clarity tentang apa yang dibangun
- **R**elevant — solve real user need

Plan divalidasi dengan **FACTS**:
- **F**easible — bisa dikerjakan dengan tools yang ada
- **A**tomic — single focused unit, no context overflow
- **C**lear — instruction tidak ambigu
- **T**estable — punya success criteria
- **S**coped — properly bounded

Implement = **mechanical execution.**

Yang penting: setiap guard rail di framework kami adalah **jawaban defensif** terhadap cara salah satu fase bisa fail. Hallucination di Research → solved by capability ID grounding. Context overflow di Plan → solved by atomic-task constraint. Drift di Implement → solved by 6 gates.

---

## Slide 8.8 — Why RPI vs Alternatives · ~90 detik

Tapi kenapa RPI? Kilo punya 5 development pattern utama. Mari kita bandingkan.

- **Vibe Coding** — natural-language iteration tanpa banyak planning. Bagus untuk prototyping. **Risk**: tech debt menumpuk.
- **Ralph Wiggum** — loop AI sampai test pass, dengan stop hook. Bagus untuk production retry loop. **Risk**: compute cost tinggi, bisa spinning.
- **Outcome Engineering (o16g)** — manage token cost over engineer hours. Bagus untuk greenfield outcome-driven. **Risk**: sulit di-audit per fase.
- **Spec-Driven (Spec Kit)** — executable spec sebagai single source of truth. Bagus untuk high-stakes seperti payments dan healthcare. **Risk**: authoring overhead tinggi untuk spec-nya.
- **RPI ← pilihan kami**. Research → Plan → Implement dengan FAR + FACTS. Risk paling rendah: highest grounding, deterministic replay.

**Kenapa RPI menang untuk {{ORG_NAME}}:**

1. **Compliance audit trail** — setiap fase emit artifact durable (TRD, plan doc, AC). Map 1:1 ke human gate.
2. **Atomic Plan steps** map ke PR-sized changes — pas untuk Gate 4 review dan Gate 5 merge.
3. **Mechanical Implement** minimize hallucination. Kritikal karena production code kami menyentuh duit.
4. **Research-first** prevent "build-the-wrong-thing" — save engineer hours **sekaligus** save token cost.

---

## Slide 9 — Base Workflow · ~30 detik

Tiga step yang **required**, setiap fitur, setiap waktu:

```
/plan-first {context}  →  /breakdown-design option {X}  →  /do-implementation {plan-doc}
```

Semua command lain optional.

`/plan-first` untuk context priming. `/breakdown-design` untuk attention dan grounding via BEFORE/AFTER. `/do-implementation` untuk grounded generation dengan plan yang sudah jadi sebagai pegangan.

---

## Slide 10 — /breakdown-design = BEFORE/AFTER · ~50 detik

Output `/breakdown-design` bukan task list yang vague. Ini **surgical diff per file.**

Setiap step kasih empat hal: **file path** (no ambiguity), **BEFORE code** (kondisi sekarang), **AFTER code** (target), dan **✅ marker** di line yang berubah.

Lihat contoh di slide. Sebelum: function `execute()` cuma panggil repository. Sesudah: panggil `validate(request)` dulu, kalau error langsung return, baru lanjut ke repository.

Bukan instruksi — ini **grounding**. Karena starting point sudah diberi, LLM tidak perlu hallucinate file path atau function signature.

---

## Slide 11 — Why BEFORE/AFTER matters · ~45 detik

Mari kita uraikan kenapa pola ini powerful:

- **BEFORE code** = exact starting point, no guessing.
- **AFTER code** = exact target, no ambiguity.
- **✅ marker** = focus attention pada perubahan.
- **File path** = no hallucinate file mana yang harus diedit.

Pattern ini adalah bentuk **grounding**. Daripada bilang "add validation" yang abstrak, Anda kasih "kode ini ada — ubah jadi kode ini." LLM tidak hallucinate karena starting point sudah ada di tangan.

**Itu rahasianya.**

---

## Slide 12 — 20 Commands across 6 Categories · ~60 detik

Total ada **20 command** di workspace {{ORG_NAME}}, dibagi 6 kategori:

- **Planning (5)** — `/trd`, `/plan-first`, `/mini-prd`, `/breakdown-design`, `/create-jira-task`
- **Execution (3)** — `/do-implementation`, `/design`, `/wireframe-image`
- **Review (4)** — `/feature-report`, `/qa-align`, `/prd-align`, `/update-doc`
- **Quality Pipeline (2)** — `/quality-to-jira`, `/quality-publish-confluence`
- **Analysis & Search (5)** — termasuk `/search`, `/deep-analysis`, `/mobile-analysis`
- **Testing (1)** — `/ui-test`

Yang **required** cuma 3: plan-first → breakdown-design → do-implementation. Sisanya optional, dipakai sesuai kebutuhan.

Update terbaru: `/prd-align`, `/quality-to-jira`, dan `/quality-publish-confluence` adalah tiga command paling baru.

---

## Slide 13 — The Why Summary · ~45 detik

Setiap step di framework kita solve LLM problem yang spesifik.

- `/plan-first` — solve "arbitrary approach". Tanpa ini, AI ambil approach over-engineered.
- `/breakdown-design` — solve "large scope, no diffs". Tanpa ini, implementation scattered dan incomplete.
- `/do-implementation` — solve "needs grounding". Tanpa ini, kode plausible tapi salah.
- `/trd` — solve "no tech context". Tanpa ini, API contract di-hallucinate.
- `/feature-report` — solve "requirement drift". Tanpa ini, fitur yang dibangun melenceng dari PRD.
- `/qa-align` — solve "QA blind spots". Tanpa ini, ada test coverage gap.

Setiap command itu jawaban defensif terhadap satu cara LLM bisa fail.

---

## Slide 14 — Quick Start · ~30 detik

Ini quick start kalau Anda mau coba sendiri besok.

Empat command, satu fitur:

```
/plan-first add transfer amount validation with client and server checks
/breakdown-design option B
/do-implementation transfer-validation-implementation-plan.md
/feature-report https://confluence-url/prd
/qa-align {{JIRA_KEY}}
```

Itu saja. Coba pada tiket yang Anda kerjakan minggu depan — feedback-nya kita bahas di standup.

---

## Slide 15 — Demo (1/3) Inputs & Research · ~75 detik

Sekarang demo end-to-end pada **fitur nyata**: {{APP_CODE}} Chat Widget on App.

**Input**: PRD ada di Confluence, ID 3913842689. Figma ada section judul "ADD CHAT ON LAINNYA MENU", 3 frame:
- 1:2268 — Lainnya (default state)
- 1:2379 — error bottom-sheet
- 1:2508 — webview chat (out of scope, akan saya jelaskan kenapa)

**Research phase:**

`/trd 3913842689` — fetch PRD dan BE TRD via Atlassian MCP, baca Figma frames via Figma MCP, tulis ke `.docs/.../trd-{{APP_CODE}}-chat.md`.

`/plan-first {{APP_CODE}} Chat Widget` — kasih 3 option:
- A. WebView wrapper minimal
- B. WebView + native nav bar ← **dipilih**
- C. WebView + full chat UI native

Comparison matrix ditampilkan, engineer pilih Option B.

Ini RPI Research phase: **context priming dari PRD + Figma + BE TRD sebelum kode ditulis.**

---

## Slide 16 — Demo (2/3) Plan & Implement · ~75 detik

`/breakdown-design Option B` menghasilkan **Visual Intent Map** — kontrak antara plan dan verifikasi.

Tabel di slide menunjukkan tiga row:
- Lainnya / default → **RE-RECORD**
- Lainnya / error-sheet → **RE-RECORD**
- ChatWebView / default → **SKIPPED**

Yang menarik: **WebView SKIPPED** bukan kelalaian. Ini pattern recognition dari framework — WebView content excluded sesuai gotcha di CLAUDE.md (rendering tidak deterministik). Verifikasi WebView dilakukan manual pakai `/ui-test` di real device, bukan Roborazzi.

Saat `/do-implementation` jalan:
- `gradle build` green ✅
- Roborazzi loop verify ke 0.1% threshold
- Asset `chat_bubble.xml` di-download dari Figma kalau belum ada
- Baseline PNG di-commit ke `.docs/screen/feature-lainnya/`

Self-verdict, max 3 fix attempts, no asking the user. Kalau passed dalam 3 attempt → done. Kalau tidak → halt, tulis error ke AC.

---

## Slide 17 — Demo (3/3) Verify & Ship · ~75 detik

Setelah implementation:

- `git commit + push + PR` via `mcp__bitbucket__create_pr`
- **Gate 4** peer review — manusia
- **Gate 5** merge — manusia, **NEVER AI**

`/feature-report 3913842689` cek PRD vs implementation:
- 100% compliance ✅
- 6 AC covered
- Remote Config `{{APP_CODE}}_mobile_chat` ada
- Event tracker `btn_help_chat` ada
- WebView block external nav ✅

`/qa-align {{APP_CODE}}-CHAT-WIDGET` generate gap report — 8 dari 8 scenario QA TRD ter-cover.

**Gate 6** QA sign-off → release.

Artifact untuk reviewer ada di `.docs/roborazzi/{{APP_CODE}}-chat-widget/`: figma png, roborazzi png, diff png — diff 0.0% di kedua state. Baseline yang ter-commit ada di `.docs/screen/feature-lainnya/`.

**Tiga manusia, tiga gate. Mesin handle loop di antaranya.**

---

## Slide 17.5 — Before / After Metrics · ~75 detik

Sekarang angka-angka yang nyata. Bukan klaim, ini measured.

| Metrik | Tanpa AI | Dengan AI |
|---|---|---|
| Time per ticket | ~3 jam | ~2 menit (review only) |
| Tickets per minggu | 5–8 | 40+ |
| Human effort per minggu | 40+ jam | ~1.5 jam |
| Code placement accuracy | ~60% | ~95% |
| API hallucinations | Frequent | Near zero (MCP + contracts) |
| Repeated mistakes | Common | Zero (feedback loop) |
| Weekend detection latency | ≤7 hari | ≤24 jam (Oncall agent) |
| Cutting release branch | 30–60 menit manual | <3 menit, zero typing |

Total cerita: 41 ticket × 3 jam = **124 jam manual** versus **1.5 jam dengan pipeline**.

Itu kira-kira **80x efficiency multiplier**.

---

## Slide 17.6 — External References · ~60 detik

We're standing on shoulders. Framework ini bukan inovasi kosong — kami ngutip beberapa pattern dari komunitas:

- **Kilo Path — RPI Pattern** — canonical source untuk Research/Plan/Implement, lengkap dengan FAR/FACTS rubric.
- **Kilo Path — Trends & Patterns** — yang membandingkan RPI dengan Vibe Coding, Ralph Wiggum, Spec Kit, Outcome Engineering — slide tadi sumbernya dari sini.
- **Kilo Path — Agentic Engineering** — yang define spektrum Copilot → Task Agent → Workflow Agent. L0-L3 mapping kita berdasar ini.
- **Dex Horthy "No Vibes Allowed" (HumanLayer)** — talk 20 menit, sumber paling jelas untuk RPI in motion + intentional compaction + 40% "dumb zone" rule. Wajib tonton.
- **Internal**: AI in Mobile Engineering — Strategy & Centralized Guide di Confluence — single entry point untuk semua dokumentasi pipeline kami.
- **Open source**: `github.com/tomdwipo/Automated-Jira-to-PR` — full framework, MIT-licensed, project-agnostic. Silakan clone dan adopsi.

---

## Slide 18 — Thank You · ~20 detik

Terima kasih.

> *It's all just chat. Context is the only thing that matters.*

Sekarang waktunya pertanyaan. Selama dua minggu ke depan, kita akan latihan satu-satu di setiap standup harian — jadi kalau hari ini belum 100% kebayang, **itu wajar**. Setiap orang akan ngerasain prosesnya sendiri.

Silakan, ada yang mau ditanyakan?

---

## Estimasi total waktu

| Bagian | Durasi |
|---|---|
| Foundation (slide 1–4.6) | ~5 menit |
| LLM concepts + MCP (slide 5–7) | ~3 menit |
| Strategy & RPI (slide 8–8.8) | ~7 menit |
| Workflow & commands (slide 9–14) | ~5 menit |
| Live demo {{APP_CODE}} Chat Widget (slide 15–17) | ~5 menit |
| Closing (slide 17.5–18) | ~3 menit |
| **Total estimasi** | **~28 menit** + buffer Q&A |
