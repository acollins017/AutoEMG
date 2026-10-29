# AutoEMG

AutoEMG is an AutoHotkey (v1.1) tool that drafts the **Summary** and **Impression** of an NCS/EMG report. Open the report, press **Ctrl+Q**, review the draft, and press **Enter** to insert it. The rest of the report is left untouched.

It reads every nerve conduction table (motor, sensory, F-wave, H-reflex) and the needle EMG table. Each value is compared with age-adjusted AANEM reference values. The Summary describes the abnormal findings in your house style. The Impression correlates them into electrodiagnostic diagnoses, numbered from most to least severe.

> The impression is a **draft**. Always review it before signing; the review window shows every measured value next to the limit it was judged against.

---

## Setup

1. Install **AutoHotkey v1.1** (Unicode, v1.1.33 or newer) from <https://www.autohotkey.com/download/1.1/>. v2 will not run this script.
2. Put this folder anywhere (e.g. `Documents\AutoEMG`). Keep the folder structure: `AutoEMG.ahk`, `Settings.ahk`, `lib\`.
3. Double-click **`AutoEMG.ahk`**. A green "H" tray icon appears.
4. Optional: to start it with Windows, put a shortcut to `AutoEMG.ahk` in `shell:startup`.

## Daily use

| Key | What it does |
| --- | --- |
| **Ctrl+Q** | In an open report: copies the text, analyzes it, shows the review window. |
| **Enter / Alt+I** (in the review window) | Inserts the summary under `Summary:` and the impression under `Impression:`. |
| Esc | Closes the review window without changing the report. |
| **Ctrl+Shift+Q** | Analyzes text you already copied (for editors where Ctrl+A doesn't work). Nothing is typed into the report. |
| **Ctrl+Alt+R** | Reloads the script after you edit `Settings.ahk`. |
| Dot phrases | Type `.rightctsmild`, `.impnl`, `.emgnl`, ... followed by Space/Enter. Full list in `lib\DotPhrases.ahk`. |

The review window has three tabs:

* **Draft**: the Summary and Impression. Both are editable, and your edits are what gets inserted.
* **Measured values**: each latency, amplitude, CV, amplitude drop and comparison, with its limit, the source of the limit, and normal/ABNORMAL/BORDERLINE.
* **Notes**: warnings and attributions, such as cold limbs, unrecognized muscles, fuzzy name matches, and which diagnosis "explains" each abnormal study or muscle.

Buttons: Insert, Copy summary, Copy impression, Copy both, and Copy data table (a plain-text audit of every value).

### How text is inserted

* **Microsoft Word** (detected automatically): uses Word's COM interface, so no keystrokes are sent. The text fills the blank line under each heading and the formatting resets to normal (not the bold heading).
* **Any other editor**: arrow-key navigation. Before pasting, the script copies each line back to confirm it is on the `Summary:` / `Impression:` line, so wrapped lines and tables cannot cause a misplaced paste. The impression is inserted first (it is lower in the document), so the summary heading never moves.
* If a heading can't be found, nothing is pasted. Both sections are put on the clipboard and you get a message.
* Your clipboard contents are restored afterwards.

---

## What the summary looks like

The wording follows your existing reports, for example:

> The right median sensory nerve showed a prolonged latency and slow conduction velocity. The right sural nerve showed no response. All remaining sensory responses were normal.
> The right peroneal motor nerve at the EDB showed low amplitude. The right tibial motor nerve showed low amplitude. All remaining motor responses were normal.
> The right Gastrocnemius showed increased insertional activity, abnormal spontaneous activity, reduced recruitment, and increased motor unit amplitudes and durations. ... All remaining muscles tested showed normal insertional activity, no abnormal spontaneous activity, normal motor unit amplitudes and durations, and normal recruitment patterns.

Covered: prolonged/low/slow per nerve, absent responses, segment-specific slowing ("across the elbow", "below the fibular head", "in the forearm"), relative focal slowing, conduction block, temporal dispersion, absent proximal responses, F-wave and H-reflex latency (absolute and side-to-side), and median–ulnar comparison studies. The EMG side covers insertional activity, fibrillations/PSWs, fasciculations, myotonic/CRD/myokymic discharges, recruitment (reduced, early, none), MUAP size (increased, decreased, nascent) and polyphasia.

## What the impression looks like

For the de-identified copy of your 7/2/2026 lumbosacral report, AutoEMG produces:

> This is an abnormal electrodiagnostic study of the right upper, right lower, and left lower extremities which shows evidence of:
> 1. A chronic, bilateral lumbosacral radiculopathy of the L5 and S1 myotomes, with active denervation.
> 2. A mild, length-dependent, axonal, sensory, large-fiber polyneuropathy; incidental finding.
> 3. A right, mild median neuropathy at the wrist, demyelinating. In this clinical context, this is consistent with a right, mild carpal tunnel syndrome.

The only difference from what you wrote is "Acute on Chronic" vs "chronic"; that wording is the `ChronicActiveTerm` setting.

A normal study reads: "This is a normal electrodiagnostic study. No electrophysiological evidence of *(indication)* was found." The indication is taken from "EDX is performed for evaluation of ..." in the history.

---

## Reference values

`NormalsSource := "AANEM"` (default). Every limit is shown with its source in the Measured values tab.

**AANEM Normative Data Task Force**: Chen S, Andary M, Buschbacher R, et al. *Electrodiagnostic reference values for upper and lower limb nerve conduction studies in adult populations.* Muscle Nerve 2016;54:371–377 (AANEM NDTF chart, rev. 4/2020). Upper limits are the 97th percentile and lower limits the 3rd percentile, for ages 19–79.

| Nerve | Latency (ULN) | Amplitude (LLN) | CV (LLN) | Stratified by |
| --- | --- | --- | --- | --- |
| Median sensory D2/D3, 14 cm | peak 4.0 / onset 3.3 ms | O-P 11 µV (19–49 BMI<24: 17; 19–49 ≥24: 11; 50–79 <24: 9; 50–79 ≥24: 7) | 43 | age, BMI |
| Median palm, 7 cm | peak 2.3 / onset 1.6 | O-P 6 | – | |
| Ulnar sensory D5, 14 cm | peak 4.0 / onset 3.1 | O-P 10 (14 / 11 / 10 / 5 by the same groups) | 45 | age, BMI |
| Superficial radial, 10 cm | peak 2.8 / onset 2.2 | O-P 7 | 50 | |
| Sural, 14 cm | peak 4.5 / onset 3.6 | 4 | 40 | |
| MABC / LABC, 10 cm | peak 2.6 / 2.5 | 4 / 5 | – | |
| Median motor (APB), 8 cm | 4.6 M / 4.4 F (≥50 y: 4.7 M) | 5.9 (19–39), 4.2 (40–59), 3.8 (60–79) | 49 M / 53 F (19–39); 47 M / 51 F (40–79) | age, sex |
| Ulnar motor (ADM), 8 cm | 3.7 | 7.9 | below elbow 52, across elbow 43, above elbow 50; drop across elbow >15 m/s and >23% | |
| Peroneal motor (EDB), 8 cm | 6.5 | 2.6 (19–39), 1.1 (40–79) | ankle–BFH 38 (43/37/39/36 by age and height), across FH 42; drop >6 m/s and >12% | age, height |
| Tibial motor (AH), 8 cm | 6.1 | 5.8 (19–29), 5.3 (30–59), 1.1 (60–79) | 39 (44–34 by age and height) | age, height |
| Median − ulnar | sensory peak diff ≤0.4 ms; motor DL diff ≤1.4 (<50 y) / ≤1.7 (≥50 y) | | | age |

**Amplitude-drop (conduction block) limits.** AANEM: peroneal ankle→BFH 32% and across the fibular head 25%; tibial ankle→knee 71%. Not specified by AANEM, so set here: ulnar across/above the elbow 20%, other long segments 30%. If the CMAP duration also increases more than 30%, the drop is reported as temporal dispersion instead of conduction block.

**Supplemental values** (Preston & Shapiro, *Electromyography and Neuromuscular Disorders*, 4th ed.; Buschbacher 2003) for nerves the NDTF did not cover:

* Superficial peroneal: ≤4.4 ms, ≥6 µV (≥4 µV over age 60), ≥40 m/s.
* Saphenous: ≤4.4 ms, ≥4 µV (≥2 µV over age 40).
* DUC: ≤2.5 ms, ≥8 µV.
* Ulnar motor to FDI: ≤4.5 ms, ≥7 mV.
* Peroneal motor to TA: ≤6.7 ms, ≥3 mV.
* Radial motor (EIP): ≤2.9 ms, ≥2 mV, ≥49 m/s.
* Palmar mixed: ≤2.2 ms; median−ulnar palm ≤0.3 ms; D4 ≤0.4 ms; median−radial D1 ≤0.4 ms.
* F-wave minimum latency: median ≤31, ulnar ≤32, peroneal/tibial ≤56 ms; side-to-side ≤2 ms (upper) / ≤4 ms (lower).
* H-reflex: ≤34 ms, side-to-side ≤1.5 ms.
* Anything else falls back to the **Ref.** column printed in the report.

**How the patient is matched to a group**

* **Age and sex** come from the report. If the age is missing, it is calculated from the DOB and visit date. If the sex is missing, it is inferred from "Mr./Ms./man/woman" in the history.
* **BMI and height** are used when the report has `Height:` / `Weight:` / `BMI:` fields. Otherwise `DefaultBMIGroup` (default ≥24, the more lenient row) and the whole-sample CV limits are used.
* **Sensory latency limits are scaled to your recording distance** (e.g. 4.0 ms at 14 cm becomes 3.71 ms at your 13 cm median and 3.14 ms at your 11 cm ulnar). Setting: `AdjustSensoryLatencyForDistance`.
* Set `NormalsSource := "REPORT"` to judge everything against the machine's Ref. column instead.

---

## How the impression is built

Patterns follow Preston & Shapiro and AANEM practice parameters. Each abnormal study or muscle is "explained" by at most one diagnosis, and anything left unexplained is listed as nonspecific. The Notes tab shows the attribution.

1. **Carpal tunnel syndrome.** Needs slowing at the wrist: median sensory latency or CV, an absent median SNAP with a present ulnar, median motor distal latency, or an abnormal comparison study.
   * Mild: sensory slowing with the SNAP still present (or comparison studies only).
   * Moderate: sensory plus motor distal latency, or an absent SNAP (`CTSAbsentSNAPGrade`).
   * Severe: any median motor axon loss (low or absent CMAP, or APB denervation). Worded "demyelinating and axonal".
   * Left and right are combined into one "Bilateral, ..." item when the grades match.
   * If the ulnar sensory is slowed to the same degree, the median finding is attributed to polyneuropathy instead.
2. **Ulnar neuropathy at the elbow.** Needs absolute slowing across the elbow (<43 m/s), a drop of >15 m/s **and** >23% from the forearm, or a conduction block / absent response above the elbow.
   * Mild: focal slowing only.
   * Moderate: plus a low or absent ulnar SNAP / DUC, or a conduction block.
   * Severe: plus CMAP loss or denervation in FDI/ADM/FCU/FDP.
   * Slowing that is also present in the forearm is treated as diffuse, not focal.
   * Isolated borderline focal slowing is reported as borderline, not as a neuropathy.
3. **Ulnar neuropathy at the wrist.** Isolated prolonged ulnar distal latency, with normal elbow segments and a normal median distal latency.
4. **Peroneal neuropathy at the fibular head.** The same structure using the AANEM fibular-head limits. Denervation in peroneal muscles counts as axon loss only when the short head of the biceps femoris is spared.
5. **Tarsal tunnel.** Isolated prolonged tibial distal latency with a normal sural and normal peroneal latency.
6. **Motor neuron disease / polyradiculopathy.** Active and chronic denervation in ≥3 of the bulbar, cervical, thoracic and lumbosacral regions (revised El Escorial distribution; paraspinal fibs count for the thoracic region).
7. **Myopathy.** ≥2 muscles with small/short MUAPs and/or early recruitment.
   * Labeled proximal, distal, or proximal and distal; "irritable" when fibs/PSWs are present; myotonic discharges are noted.
   * Myotonic discharges without myopathic units get their own item.
8. **Radiculopathy / plexopathy / mononeuropathy.** Neurogenic muscles are grouped by side and region (cervical vs lumbosacral). For each group:
   * **Root level**: the smallest set of 1–3 roots that covers every abnormal muscle. A cover that relies on a minor root is penalized, as is a normal muscle whose major root is in the set, and non-contiguous roots. This is what turns TA + Gastrocnemius into "L5 and S1", or triceps + FCR + PT + EDC into "C7".
   * **Mononeuropathy**: every abnormal muscle shares a nerve branch (e.g. common peroneal, radial below the spiral groove, ulnar) with no paraspinal involvement, the pattern isn't bilateral, and either a normal same-root muscle on another nerve argues against a root lesion or that nerve's SNAP is abnormal.
   * **Plexopathy**: the pattern fits one trunk/cord or the lumbar/lumbosacral plexus across ≥2 nerves, with an abnormal SNAP in that territory, normal paraspinals and root-level muscles (rhomboid, serratus), and no matching pattern on the other side.
   * **Radiculopathy**: ≥2 abnormal muscles on ≥2 nerves (or 1 limb muscle + paraspinals). Wording: "A chronic, left lumbosacral radiculopathy of the L5 myotome, with active denervation."
     * Chronicity: active + chronic = `ChronicActiveTerm`; active only = "acute"; chronic only = "..., without active denervation".
     * Right and left are merged into "bilateral".
     * Low CMAPs and late responses that the involved roots explain (e.g. EDB/AH with L5/S1) are attributed to the radiculopathy.
   * **Single abnormal muscle**: "Isolated, mild chronic neurogenic changes in the left Gastrocnemius, without active denervation. This is a nonspecific finding that does not meet electrodiagnostic criteria for a lumbosacral radiculopathy."
   * **Polyneuropathy vs bilateral L5/S1**: distal, symmetric leg denervation is attributed to polyneuropathy instead of radiculopathy when the polyneuropathy score reaches `PolyneuropathyEMGThreshold` (default 4). The score is:
     * leg SNAPs abnormal: +2 bilateral, +1 one side;
     * leg CMAPs abnormal: +2 bilateral, +1 for two nerves on one side;
     * symmetric EMG +1; foot intrinsic muscles involved +1;
     * proximal or paraspinal involvement −2; asymmetric EMG −1.
9. **Polyneuropathy.** Called from leg SNAP abnormalities that no focal lesion explains (≥2 abnormal nerves, or a clearly absent or <50% SNAP under age 70). Wording: "A *severity*, *length-dependent*, *axonal/demyelinating*, *sensory/motor/sensorimotor*, large-fiber polyneuropathy".
   * Demyelinating means ≥2 motor nerves in the demyelinating range: DL >130% ULN, CV <75% LLN, conduction block or dispersion.
   * Severity: mild = sensory only; moderate = plus leg CMAP loss or distal denervation; severe = absent leg CMAPs or ≥2 abnormal upper-limb nerves.
   * "; incidental finding" is added when the indication isn't a neuropathy question.
   * A non-length-dependent sensory pattern prompts a sensory neuronopathy comment.
10. **Leftovers.** Abnormal values not explained by any of the above become "Nonspecific abnormalities of ...". If every abnormal value is within 10% of its limit, the finding is reported as borderline instead; a study with only borderline findings reads "This is an essentially normal electrodiagnostic study ... There is borderline ...".

**Ordering** (most severe first): MND (100) > plexopathy (78–85) > severe focal neuropathy or polyneuropathy (80–85) > irritable myopathy (78) > radiculopathy with active denervation (76–80) > non-irritable myopathy (70) > moderate polyneuropathy or EMG-defined mononeuropathy (58–68) > moderate focal neuropathy (64) > chronic radiculopathy (61–65) > mild polyneuropathy (50) > mild focal neuropathy (45) > nonspecific (14–40) > borderline (10–12).

### Muscle reference table

Major (predominant) roots are in **bold**. Plexus elements: UT/MT/LT = upper/middle/lower trunk; LC/PC/MC = lateral/posterior/medial cord; LP = lumbar plexus; SP = lumbosacral (sacral) plexus. A muscle with no plexus element (rhomboid, serratus anterior, paraspinals) is innervated directly from the roots, which is what separates a radiculopathy from a plexopathy.

| Muscle | Shown in report as | Nerve (most distal branch) | Roots | Plexus |
| --- | --- | --- | --- | --- |
| Abductor Pollicis Brevis | APB | median (distal to wrist) | **C8**, **T1** | LT, MC |
| Opponens Pollicis | Opponens Pollicis | median (distal to wrist) | **C8**, **T1** | LT, MC |
| First Dorsal Interosseous | FDI | ulnar (deep branch) | **C8**, **T1** | LT, MC |
| Abductor Digiti Minimi | ADM | ulnar (deep branch) | **C8**, **T1** | LT, MC |
| Adductor Pollicis | Adductor Pollicis | ulnar (deep branch) | **C8**, **T1** | LT, MC |
| Flexor Carpi Ulnaris | FCU | ulnar | C7, **C8**, T1 | MT, LT, MC |
| Flexor Digitorum Profundus (ulnar) | FDP (4,5) | ulnar | C7, **C8**, T1 | LT, MC |
| Flexor Digitorum Profundus (median) | FDP (2,3) | anterior interosseous | C7, **C8**, T1 | MT, LT, LC, MC |
| Flexor Pollicis Longus | FPL | anterior interosseous | C7, **C8**, T1 | MT, LT, LC, MC |
| Pronator Quadratus | Pronator Quadratus | anterior interosseous | C7, **C8**, T1 | MT, LT, LC, MC |
| Flexor Digitorum Superficialis | FDS | median | C7, **C8**, T1 | MT, LT, LC, MC |
| Flexor Carpi Radialis | FCR | median | **C6**, **C7** | UT, MT, LC |
| Pronator Teres | PT | median | **C6**, **C7** | UT, MT, LC |
| Extensor Indicis Proprius | EIP | posterior interosseous | C7, **C8** | MT, LT, PC |
| Extensor Digitorum Communis | EDC | posterior interosseous | **C7**, C8 | MT, LT, PC |
| Extensor Carpi Ulnaris | ECU | posterior interosseous | **C7**, **C8** | MT, LT, PC |
| Extensor Pollicis Brevis | EPB | posterior interosseous | **C7**, **C8** | MT, LT, PC |
| Extensor Pollicis Longus | EPL | posterior interosseous | **C7**, **C8** | MT, LT, PC |
| Abductor Pollicis Longus | APL | posterior interosseous | **C7**, **C8** | MT, LT, PC |
| Supinator | Supinator | posterior interosseous | C5, **C6**, C7 | UT, PC |
| Extensor Carpi Radialis | ECR | radial (below spiral groove) | **C6**, **C7** | UT, MT, PC |
| Brachioradialis | Brachioradialis | radial (below spiral groove) | **C5**, **C6** | UT, PC |
| Triceps | Triceps | radial | C6, **C7**, C8 | UT, MT, LT, PC |
| Anconeus | Anconeus | radial | **C7**, **C8** | MT, LT, PC |
| Biceps | Biceps | musculocutaneous | **C5**, **C6** | UT, LC |
| Brachialis | Brachialis | musculocutaneous | **C5**, **C6** | UT, LC |
| Deltoid | Deltoid | axillary | **C5**, **C6** | UT, PC |
| Teres Minor | Teres Minor | axillary | **C5**, C6 | UT, PC |
| Supraspinatus | Supraspinatus | suprascapular | **C5**, **C6** | UT |
| Infraspinatus | Infraspinatus | suprascapular | **C5**, **C6** | UT |
| Rhomboid | Rhomboid | dorsal scapular | C4, **C5** | - |
| Serratus Anterior | Serratus Anterior | long thoracic | C5, **C6**, **C7** | - |
| Latissimus Dorsi | Latissimus Dorsi | thoracodorsal | C6, **C7**, C8 | UT, MT, LT, PC |
| Pectoralis Major | Pectoralis Major | pectoral | C5, **C6**, **C7**, C8, T1 | UT, MT, LT, LC, MC |
| Teres Major | Teres Major | lower subscapular | C5, **C6**, C7 | UT, MT, PC |
| Trapezius | Trapezius | accessory | C3, C4 | - |
| Sternocleidomastoid | Sternocleidomastoid | accessory | - | - |
| Cervical Paraspinals | Cervical Paraspinals | paraspinal (posterior rami) | C4, C5, C6, C7, C8, T1 | - |
| Thoracic Paraspinals | Thoracic Paraspinals | paraspinal (posterior rami) | T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12 | - |
| Lumbar Paraspinals | Lumbar Paraspinals | paraspinal (posterior rami) | L1, L2, L3, L4, L5, S1 | - |
| Rectus Abdominis | Rectus Abdominis | - | T6, T7, T8, T9, T10, T11, T12 | - |
| Genioglossus | Genioglossus | hypoglossal | - | - |
| Masseter | Masseter | trigeminal | - | - |
| Frontalis | Frontalis | facial | - | - |
| Orbicularis Oculi | Orbicularis Oculi | facial | - | - |
| Orbicularis Oris | Orbicularis Oris | facial | - | - |
| Mentalis | Mentalis | facial | - | - |
| Tibialis Anterior | TA | deep peroneal | L4, **L5** | SP |
| Extensor Hallucis Longus | EHL | deep peroneal | **L5**, S1 | SP |
| Extensor Digitorum Longus | EDL | deep peroneal | **L5**, S1 | SP |
| Extensor Digitorum Brevis | EDB | deep peroneal | **L5**, **S1** | SP |
| Peroneus Longus | Peroneus Longus | superficial peroneal | **L5**, **S1** | SP |
| Peroneus Brevis | Peroneus Brevis | superficial peroneal | **L5**, **S1** | SP |
| Tibialis Posterior | Tibialis Posterior | tibial | **L5**, S1 | SP |
| Flexor Digitorum Longus | Flexor Digitorum Longus | tibial | **L5**, **S1**, S2 | SP |
| Flexor Hallucis Longus | Flexor Hallucis Longus | tibial | L5, **S1**, S2 | SP |
| Gastrocnemius (medial head) | Gastrocnemius | tibial | **S1**, S2 | SP |
| Gastrocnemius (lateral head) | Gastrocnemius (lateral head) | tibial | L5, **S1**, S2 | SP |
| Soleus | Soleus | tibial | **S1**, S2 | SP |
| Abductor Hallucis | AH | medial plantar | **S1**, **S2** | SP |
| Abductor Digiti Quinti Pedis | ADQP | lateral plantar | **S1**, **S2** | SP |
| Biceps Femoris (short head) | Biceps Femoris (short head) | sciatic | **L5**, **S1**, S2 | SP |
| Biceps Femoris (long head) | Biceps Femoris (long head) | sciatic | L5, **S1**, S2 | SP |
| Semitendinosus | Semitendinosus | sciatic | **L5**, S1, S2 | SP |
| Semimembranosus | Semimembranosus | sciatic | **L5**, S1, S2 | SP |
| Gluteus Medius | Gluteus Medius | superior gluteal | L4, **L5**, S1 | SP |
| Tensor Fascia Lata | Tensor Fascia Lata | superior gluteal | L4, **L5**, S1 | SP |
| Gluteus Maximus | Gluteus Maximus | inferior gluteal | L5, **S1**, S2 | SP |
| Vastus Lateralis | VL | femoral | L2, **L3**, **L4** | LP |
| Vastus Medialis | VM | femoral | L2, **L3**, **L4** | LP |
| Rectus Femoris | Rectus Femoris | femoral | L2, **L3**, **L4** | LP |
| Iliopsoas | Iliopsoas | femoral | **L2**, **L3**, L4 | LP |
| Sartorius | Sartorius | femoral | **L2**, **L3** | LP |
| Adductor Longus | Adductor Longus | obturator | L2, **L3**, L4 | LP |
| Adductor Magnus | Adductor Magnus | obturator | L2, **L3**, **L4** | LP |
| Gracilis | Gracilis | obturator | **L2**, **L3** | LP |

### Muscle name matching

Names are matched against more than 400 aliases. Matching tolerates:

* side prefixes and suffixes (`R.`, `Rt`, `Right`, `(L)`, or a separate Side column);
* abbreviations (`Vast. Lat.`, `Abd. Poll. Brev.`, `Tib Ant`, `EIP`);
* word order (`Medial head gastroc`);
* typos (`Gastrocnemious`, `Interosseus`);
* qualifiers (`Deltoid (middle)`, `Lumbar paraspinals (low)`, `L5-S1 paraspinals`).

Anything fuzzy-matched is listed in the Notes tab. An unrecognized muscle is still described in the summary, gets a warning, and is left out of localization; it never interrupts you with message boxes. To teach it a new name, add an alias to the muscle's line in `lib\Anatomy.ahk` (aliases are `|`-separated).

---

## Settings (`Settings.ahk`)

| Setting | Default | Purpose |
| --- | --- | --- |
| `HotkeyRun`, `HotkeyClipboard`, `HotkeyReload` | `^q`, `^+q`, `^!r` | Hotkeys |
| `ShowPreview` | `true` | Show the review window. `false` inserts immediately, like the old script. |
| `InsertMethod` | `"auto"` | `auto` / `word` / `keys` / `clipboard` |
| `InsertImpression` | `true` | Also insert the impression |
| `NormalsSource` | `"AANEM"` | Or `"REPORT"` to use the machine's Ref. column |
| `SensoryAmpMethod` | `"OP"` | Baseline-to-peak (`OP`) or peak-to-peak (`PP`) sensory amplitudes |
| `DefaultBMIGroup` | `"high"` | BMI group used when the report has no height/weight |
| `AdjustSensoryLatencyForDistance` | `true` | Scale sensory latency limits to your recording distance |
| `BorderlineFraction` / `MinorFraction` | 0.05 / 0.10 | Thresholds for "borderline" labels and for nonspecific findings being shown as borderline |
| `ApplyTempCorrection` | `false` | Correct latency/CV of cold limbs (0.2 ms and 2 m/s per °C) |
| `PeronealTerm` | `"peroneal"` | Or `"fibular"` |
| `ChronicActiveTerm` | `"chronic"` | Or `"acute on chronic"` |
| `ReportComparisons` | `"whenNeeded"` | Show median–ulnar comparisons in the summary: `always` / `never` / only when they are what makes the median abnormal |
| `CTSAbsentSNAPGrade` | `"moderate"` | Grade for an absent median SNAP with a normal CMAP |
| `PolyneuropathyEMGThreshold` | 4 | See step 8 above |
| `MNDMinRegions` | 3 | Regions needed for the MND/polyradiculopathy statement |

---

## Recommendations for the methodology

These came up while building and testing against your reports:

1. **Limb temperature.** All three sample reports record 22.5–23.6 °C, but AANEM (and any published) normal values assume more than 32 °C in the hands and more than 31 °C in the feet. A 9 °C deficit can add about 1.8 ms to a distal latency and slow conduction velocities by 13–22 m/s, which is enough to create false CTS, false ulnar neuropathy, or "slowed CV in the forearm" (as in sample 03). If those readings are room temperature (thermistor not on the skin), fix the probe placement so the Temp column is meaningful. Otherwise warm the limbs. AutoEMG flags this in Notes. `ApplyTempCorrection` exists, but warming is more reliable than correction factors.
2. **Same distances for median and ulnar sensory studies.** You record median at 13 cm and ulnar at 11 cm, so the AANEM median–ulnar peak-latency comparison (≤0.4 ms) can't be applied. Recording both at 14 cm, the AANEM technique, lets AutoEMG catch mild CTS that the absolute values miss. For borderline cases, add a palmar mixed (8 cm) or ring-finger (D4) comparison; both are parsed and graded automatically.
3. **Put height and weight in the report header.** AANEM median/ulnar sensory amplitudes depend on BMI, and peroneal/tibial CVs on height. Without them the script has to use the more lenient whole-sample rows.
4. **Radiculopathy screens.**
   * Include paraspinals whenever possible: 6-muscle screens with paraspinals identify about 94–98% of electrodiagnostically confirmable radiculopathies (Dillingham, AANEM).
   * For L5, add a non-peroneal L5 muscle (tibialis posterior or gluteus medius). TA + EDB alone cannot separate an L5 radiculopathy from a peroneal neuropathy, and the impression will say so.
   * For S1, add the gluteus maximus or the long head of the biceps femoris.
5. **Polyneuropathy.** The AAN/AANEM case definition (England et al. 2005) wants abnormalities in at least 2 nerves, one of them the sural. When one sural is absent, test the contralateral sural or a superficial peroneal nerve; in sample 01 only the right sural was tested.
6. **Across-fibular-head segment.** Use the AANEM 10 cm above-fibular-head site. In sample 03 the 70 mm segment makes a 1 m/s difference from the 42 m/s limit meaningless.
7. **Sensory amplitude convention.** Check whether your machine's sensory "Amp" is baseline-to-peak or peak-to-peak and set `SensoryAmpMethod`; the AANEM limits differ by up to 6 µV.

### How AANEM changes the read of your sample reports

Your machine's printed Ref. values (e.g. median motor DL ≤3.9 ms, median sensory amplitude ≥20 µV, radial sensory amplitude ≥18 µV) are stricter than the AANEM 3rd/97th-percentile limits. For sample 01 this means:

* Median motor DL 4.2 ms, CV 47 m/s: normal for a 45-year-old man (AANEM ≤4.6 ms, ≥47 m/s).
* Median sensory amplitude 17.3 µV and radial sensory amplitude 13.4 µV: normal (≥11 and ≥7 µV O-P).

The draft summary therefore omits those, while the impression is the same as yours. Set `NormalsSource := "REPORT"` if you prefer the machine values.

### Fixed from the previous script

* Left tibialis anterior was stored as `"leftTA"` with literal quotes, which produced "The  showed ...".
* "L. Vastus Lateralis" was mapped to gluteus medius.
* Adductor longus was reported as adductor magnus.
* `if(curAmp = "decr" curDur = "decr")` was missing its `or`, so decreased MUAPs were never reported.
* A single-site tibial study produced a false "conduction block below the popliteal fossa".
* "R Radial - EIP" matched the left-radial label; the right superficial peroneal key was mis-cased; the saphenous keys were misspelled, so those nerves were never assessed.
* Values exactly at the limit were called abnormal (`>=`/`<=`).
* "All sensory and motor responses were normal." was printed even when motor studies were abnormal.
* The paste position came from pressing Down N times, which lands on the wrong line whenever lines wrap. Every line is now verified before pasting.
* Copying used fixed sleeps without `ClipWait`, and your clipboard was overwritten.
* An unknown muscle raised a message box for every cell.
* `.rnsabn` ended "This was a normal test." and now says "abnormal".
* The severe CTS dot phrases now read "demyelinating and axonal". New dot phrases: `.rightulnarsev`/`.leftulnarsev`, `.bilctsmild`/`.bilctsmod`, `.rightlsrad`/`.leftlsrad`, `.pnmild`/`.pnmod`, `.impabn`.

---

## Project layout

```
AutoEMG.ahk          main script: hotkeys, copy -> analyze -> review -> insert
Settings.ahk         your preferences
lib/Util.ahk         helpers (number parsing, fuzzy matching, lists)
lib/Normals.ahk      AANEM + supplemental reference values
lib/Anatomy.ahk      muscle/root/nerve/plexus table, name matching, sites/segments
lib/Parser.ahk       report text -> patient, tables (column mapping by header name)
lib/Assess.ahk       compare values with limits, interpret EMG grades, write the Summary
lib/Impression.ahk   diagnostic engine and Impression text
lib/Engine.ahk       single entry point used by the hotkey and the tests
lib/Output.ahk       review window, Word COM / keystroke insertion
lib/DotPhrases.ahk   dot phrases
tests/               fixtures, expected outputs, test runners
```

## Testing

* On Windows: `"C:\Program Files\AutoHotkey\AutoHotkeyU64.exe" /ErrorStdOut tests\RunTests.ahk` prints PASS/FAIL for every fixture plus 33 muscle-name matching checks.
* On Linux with Wine: `tests/run.sh`. `tests/e2e_notepad.sh` runs the full Ctrl+Q → review → insert flow in Wine Notepad and checks that only the two sections changed.
* `tests/fixtures/01–03` are de-identified copies of the sample reports. `04–13` are synthetic cases generated by `tests/make_fixtures.py`: bilateral CTS, cubital tunnel, C7 radiculopathy, sensorimotor polyneuropathy, irritable myopathy, MND, upper trunk plexopathy, peroneal neuropathy at the fibular head, an alternate layout with F-waves and H-reflexes, and a robustness case.
* After an intended change in wording or logic, run with `--update`, then review the diff in `tests/expected/`.

## Limitations

* Adults 19–79 only; ages outside that range use the nearest AANEM group, with a warning.
* Repetitive stimulation, single-fiber EMG, blink reflexes and comparisons with prior studies are not parsed; use the dot phrases.
* The impression is a draft built from the electrodiagnostic data alone. It does not know the clinical picture, imaging, or prior studies.
