; =============================================================================
; DotPhrases.ahk - type the abbreviation followed by Space/Enter/Tab to expand.
; Expansion pastes through the clipboard (fast, keeps formatting of the report)
; and restores whatever was on the clipboard before.
; "_" marks a blank to fill in.
; =============================================================================

DP_Paste(text) {
    saved := ClipboardAll
    Clipboard := ""
    Clipboard := text
    ClipWait, 1
    Send, ^v
    Sleep, 250
    Clipboard := saved
}

; ---- History / exam ---------------------------------------------------------
:X:.ex4nl::DP_Paste("Brief neurological exam shows 5/5 strength throughout all extremities. Sensation is intact to light touch throughout. Reflexes are 2+ throughout. EDX is performed for evaluation of _")
:X:.exupnl::DP_Paste("Brief neurological exam shows 5/5 strength throughout the upper extremities. Sensation is intact to light touch throughout. Reflexes are 2+ biceps, brachioradialis, triceps bilaterally. EDX is performed for evaluation of _")
:X:.exlownl::DP_Paste("Brief neurological exam shows 5/5 strength throughout the lower extremities. Sensation is intact to light touch throughout. Reflexes are 2+ patellae, achilles bilaterally. EDX is performed for evaluation of _")

; ---- Summary ------------------------------------------------------------------
:X:.concnl::DP_Paste("All sensory and motor responses were normal. F-wave latencies were normal.")
:X:.fw::DP_Paste("All F-wave latencies were normal.")
:X:.emgnl::DP_Paste("All muscles tested showed normal insertional activity, no abnormal spontaneous activity, normal motor unit amplitudes and durations, and normal recruitment patterns.")

; ---- Impression -----------------------------------------------------------------
:X:.impnl::DP_Paste("This is a normal electrodiagnostic study. No electrophysiological evidence of _ was found.")
:X:.impabn::DP_Paste("This is an abnormal electrodiagnostic study of the _ which shows evidence of:")

:X:.leftulnarmild::DP_Paste("A left, mild ulnar neuropathy at the elbow, demyelinating. In this clinical context, this is consistent with a left, mild cubital tunnel syndrome.")
:X:.rightulnarmild::DP_Paste("A right, mild ulnar neuropathy at the elbow, demyelinating. In this clinical context, this is consistent with a right, mild cubital tunnel syndrome.")
:X:.leftulnarmod::DP_Paste("A left, moderate ulnar neuropathy at the elbow, demyelinating. In this clinical context, this is consistent with a left, moderate cubital tunnel syndrome.")
:X:.rightulnarmod::DP_Paste("A right, moderate ulnar neuropathy at the elbow, demyelinating. In this clinical context, this is consistent with a right, moderate cubital tunnel syndrome.")
:X:.leftulnarsev::DP_Paste("A left, severe ulnar neuropathy at the elbow, demyelinating and axonal. In this clinical context, this is consistent with a left, severe cubital tunnel syndrome.")
:X:.rightulnarsev::DP_Paste("A right, severe ulnar neuropathy at the elbow, demyelinating and axonal. In this clinical context, this is consistent with a right, severe cubital tunnel syndrome.")

:X:.leftctsmild::DP_Paste("A left, mild median neuropathy at the wrist, demyelinating. In this clinical context, this is consistent with a left, mild carpal tunnel syndrome.")
:X:.rightctsmild::DP_Paste("A right, mild median neuropathy at the wrist, demyelinating. In this clinical context, this is consistent with a right, mild carpal tunnel syndrome.")
:X:.leftctsmod::DP_Paste("A left, moderate median neuropathy at the wrist, demyelinating. In this clinical context, this is consistent with a left, moderate carpal tunnel syndrome.")
:X:.rightctsmod::DP_Paste("A right, moderate median neuropathy at the wrist, demyelinating. In this clinical context, this is consistent with a right, moderate carpal tunnel syndrome.")
:X:.leftctssev::DP_Paste("A left, severe median neuropathy at the wrist, demyelinating and axonal. In this clinical context, this is consistent with a left, severe carpal tunnel syndrome.")
:X:.rightctssev::DP_Paste("A right, severe median neuropathy at the wrist, demyelinating and axonal. In this clinical context, this is consistent with a right, severe carpal tunnel syndrome.")
:X:.bilctsmild::DP_Paste("Bilateral, mild median neuropathies at the wrist, demyelinating. In this clinical context, this is consistent with bilateral, mild carpal tunnel syndrome.")
:X:.bilctsmod::DP_Paste("Bilateral, moderate median neuropathies at the wrist, demyelinating. In this clinical context, this is consistent with bilateral, moderate carpal tunnel syndrome.")

:X:.leftcervrad::DP_Paste("A left, _, cervical radiculopathy of the _ myotomes, with_ evidence of active denervation.")
:X:.rightcervrad::DP_Paste("A right, _, cervical radiculopathy of the _ myotomes, with_ evidence of active denervation.")
:X:.leftlsrad::DP_Paste("A chronic, left lumbosacral radiculopathy of the _ myotome, with active denervation.")
:X:.rightlsrad::DP_Paste("A chronic, right lumbosacral radiculopathy of the _ myotome, with active denervation.")
:X:.pnmild::DP_Paste("A mild, length-dependent, axonal, sensory, large-fiber polyneuropathy.")
:X:.pnmod::DP_Paste("A moderate, length-dependent, axonal, sensorimotor, large-fiber polyneuropathy.")

; ---- Special studies -------------------------------------------------------------
:X:.sfeabn::DP_Paste("Single Fiber EMG: `nConcentric needle jitter analysis is performed on the _ frontalis muscle. _ different individual muscle fiber action potential pairs are studied and analysed. Individual pair jitter is abnormal in _ of _ pairs studied. This is >10% of pairs with abnormal jitter. Normal individual pair jitter is <39 microseconds. There is _ blocking. Normal mean jitter is <28 microseconds. Mean jitter is _ at _. `n`nDiagnostic Interpretation: This is an abnormal electrophysiological study which shows abnormal, increased jitter. This is consistent with a neuromuscular junction disorder, such as Myasthenia Gravis.")
:X:.sfenl::DP_Paste("Single Fiber EMG: `nConcentric needle jitter analysis is performed on the _ frontalis muscle. _ different individual muscle fiber action potential pairs are studied and analysed. Individual pair jitter is normal. Normal individual pair jitter is <39 microseconds. There is no blocking. Normal mean jitter is <28 microseconds. Mean jitter is normal. `n`nDiagnostic Interpretation: This is a normal electrophysiological study which shows no abnormal jitter. No electrophysiological evidence of a neuromuscular junction disorder was found. This was a normal test.")
:X:.rnsnl::DP_Paste("Repetitive Stimulation Study: `n`nRepetitive nerve stimulation is performed in trains of 5 stimuli at 2 Hz. Three muscle / nerve pairs ( right ADM / ulnar nerve, bilateral nasalis / facial nerves) were studied at baseline, after 1 min of exercise and in 1 min increments up to 4 increments after long exercise. Decrement is noted by subtracting the lowest amplitude in the stimulus train from the initial amplitude. We did not find significant decrement in any of the muscle /nerve pair tested above. This was a normal test.")
:X:.rnsabn::DP_Paste("Repetitive Stimulation Study: `n`nRepetitive nerve stimulation is performed in trains of 5 stimuli at 2 Hz. Three muscle / nerve pairs ( right ADM / ulnar nerve, bilateral nasalis / facial nerves) were studied at baseline, after 1 min of exercise and in 1 min increments up to 4 increments after long exercise. Decrement is noted by subtracting the lowest amplitude in the stimulus train from the initial amplitude. Decrement of more than 10% was seen in _ runs at the _ muscles. This was an abnormal test.")
:X:.mcmanis::DP_Paste("Long-Exercise Test (McManis protocol)`nA long-exercise test was performed on the _ ADM muscle. Exercise was performed for 5 minutes with 10 seconds of rest after every 30 seconds of voluntary, isometric muscle contraction. Stimulations were performed immediately after the exercise period and then every 3 minutes for a total of 30 minutes after exercise. A decrement of _ was noted. An abnormal decrement is > 40%. This was a normal test.")
:X:.als::DP_Paste("Diagnostic Interpretation: This is an abnormal electrodiagnostic study which shows active and/or chronic denervation/reinnervation in bulbar and thoracic myotomes. These electrodiagnostic findings may be due to motor neuron disease or polyradiculopathy. `n`nClinical Impression/Recommendation: Based on the revised El Escorial criteria, this patient has upper motor neuron signs in 2 regions and lower motor neuron involvement in thoracic/bulbar regions (with scattered involvement in cervical/lumbosacral regions which did not fulfill electrodiagnostic criteria for lower motor neuron involvement) (by EMG detailed above), which is consistent with probable ALS, provided other diagnoses have been excluded.")

; ---- Signature ---------------------------------------------------------------------
:X:.sig::DP_Paste("Andrew Collins, MD")
:X:.board::DP_Paste("Board Certified by the American Board of Electrodiagnostic Medicine")
