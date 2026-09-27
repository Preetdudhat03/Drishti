/**
 * DRISHTI Multilingual Internationalization Engine (i18n.js)
 * Supports: English (en), Hindi (hi), Marathi (mr), Gujarati (gu), Tamil (ta)
 * Guarantees 100% clean English default and strict regional translation on selection.
 */

const I18N_FULL = {
    en: {
        brand: { title: "👁 DRISHTI", sub: "Explainable AI Retinal Screening (SIH 2026)", engine: "<b>Model Engine:</b> PyTorch ResNet-18", statusReal: "● REAL MODEL ACTIVE", statusSupa: "☁ SUPABASE CONNECTED", role: "Role:" },
        modes: { simple: "🟢 Simple Mode (ASHA)", expert: "🩺 Doctor Mode" },
        roles: { clinician: "🩺 Clinician / Doctor", healthworker: "👤 Health Worker (PHC)", evaluator: "🔬 SIH Evaluator" },
        langLabel: "🌐 Language:",
        audioBtn: "🔊 Audio",
        nav: {
            screening: "🏥 1. New Screening",
            queue: "📋 2. Clinician Review Queue",
            val: "🧪 3. Model Validation Suite",
            sim: "📊 4. District Telemed Sim",
            reports: "📄 5. Screening Reports",
            dev: "⚙ System & API Inspector"
        },
        titles: {
            'tab-screening': ['New Retinal Screening Workflow', 'Patient intake, optical quality gating, AI inference, Grad-CAM XAI & Supabase cloud sync.'],
            'tab-queue': ['Clinician Tele-Ophthalmology Review Queue (Supabase Cloud)', 'Real-time clinical cases synchronized from Supabase cloud database awaiting qualified specialist sign-off.'],
            'tab-validation': ['Model Validation & Batch Testing Suite', 'Evaluation on held-out APTOS 2019 dataset and multi-image throughput triage.'],
            'tab-sim': ['District-Scale Telemedicine Simulation (120,000 Patients / Year)', 'Simulating patient arrival, bandwidth constraints, AI pre-filtering throughput, queue waiting times, and ophthalmologist capacity across a district network.'],
            'tab-reports': ['Structured Clinical Screening Reports Archive (Supabase)', 'Separates (1) AI Screening Result, (2) Grad-CAM Explainability, and (3) Clinician Final Decision into printable clinical reports fetched dynamically from Supabase.'],
            'tab-developer': ['System Status & REST API Contract Inspector', 'Live inspect JSON payloads matching EYEXPERT_API_CONTRACT_V1.md and Supabase Cloud sync status.']
        },
        ribbon: {
            step1: "1. Patient Intake & Context",
            step2: "2. Capture Retinal Image",
            step3: "3. Result & Referral Slip"
        },
        card1: {
            header: "1. Image Acquisition & Context",
            sampleLabel: "SELECT BENCHMARK TEST SAMPLE:",
            dragText: "DRAG & DROP RETINAL IMAGE HERE OR CLICK TO BROWSE",
            dragSub: "Supports smartphone fundus adapters, Topcon, Zeiss, Remidio (PNG/JPG)",
            btnCam: "📷 Use Mobile / Device Camera",
            viewOrig: "Original",
            viewEnh: "Enhanced (CLAHE)",
            viewCam: "Grad-CAM",
            viewOver: "Overlay",
            patHeader: "PATIENT CONTEXT (STORED IN SUPABASE):",
            patIdPlh: "Patient ID (e.g. PT-2026-4401)",
            patNamePlh: "Full Name (e.g. Rajesh Patel)",
            patAgePlh: "Age"
        },
        card2: {
            header: "2. Optical Quality Gate (ISO 10940 Compliant)",
            chkTitle: "Camera Photo Quality Check:",
            chkClarity: "👁️ Clarity: <span id='valClarity' style='color:#16a34a;'>✅ Clear</span>",
            chkLight: "💡 Light: <span id='valLight' style='color:#16a34a;'>✅ Good</span>",
            chkCenter: "🎯 Center: <span id='valCenter' style='color:#16a34a;'>✅ Centered</span>",
            enhancedLabel: "ENHANCED PREVIEW (ADAPTIVE CLAHE):",
            metricsHeader: "Automated Quality Metrics:"
        },
        card3: {
            header: "3. AI Screening & Grad-CAM XAI",
            speakAdvice: "📢 Speak Guidance to Patient",
            printSlip: "🖨️ Patient Referral Slip",
            attentionHeader: "Layer4 Grad-CAM Model Attention",
            heatmapTitle: "Grad-CAM Heatmap",
            overlayTitle: "Evidence Overlay"
        },
        provenance: {
            header: "Model & Evidence Provenance",
            qwkBadge: "Validated Test QWK: 0.870"
        },
        clinician: {
            header: "Clinician Decision Support & Supabase Sync",
            recHeader: "Clinical Recommendation:",
            btnValidate: "✔ Validate AI Result",
            btnReject: "✖ Reject (Recapture Required)",
            btnOverride: "⚠ Override Grade",
            btnSubmit: "📥 Submit to Review Queue",
            btnExport: "📄 Export 3-Part Report",
            findingsLabel: "QUICK FINDINGS:"
        },
        queue: {
            header: "Clinician Tele-Ophthalmology Review Queue (Supabase Cloud)",
            refreshBtn: "↻ Refresh Live Queue"
        },
        validation: {
            header: "Model Validation & Batch Testing Suite",
            btnDemo: "1. Demonstration Batch",
            btnBench: "2. Benchmark Test Set (Ground Truth)",
            btnRun: "🚀 Run Batch Triage",
            btnLoad: "📦 Load 10 Demo Samples"
        },
        simulation: {
            header: "District-Scale Telemedicine Simulation (120,000 Patients / Year)",
            recalcBtn: "↻ Recalculate Model"
        },
        reports: {
            header: "Structured Clinical Screening Reports Archive (Supabase)",
            refreshBtn: "↻ Refresh Reports Archive"
        },
        developer: {
            header: "System Status & REST API Contract Inspector"
        },
        slip: {
            title: "DRISHTI — Tele-Retinal Screening & Referral Slip",
            subtitle: "National Programme for Control of Blindness (NPCB) Support | SIH 2026",
            lblName: "Patient Name:",
            lblId: "Patient ID:",
            lblAge: "Age / Gender:",
            lblEye: "Examined Eye:",
            lblDate: "Screening Date:",
            lblCenter: "Center:",
            tipsTitle: "Key Health Guidance for Patient and Family:",
            tip1: "🩸 <b>1. Sugar Control:</b> Regular fasting and post-prandial blood glucose checks (HbA1c < 7.0%).",
            tip2: "💊 <b>2. Daily Medication:</b> Continue prescribed diabetes and hypertension medications on time.",
            tip3: "🏥 <b>3. Hospital Visit:</b> Bring this referral slip to the District Hospital Eye Department.",
            footerDoc: "<b>Verified Tele-Ophthalmologist:</b> Dr. Rajesh Kumar, MD (Ophthalmology)",
            footerNotice: "*This is a computer-verified tele-screening slip. No physical signature is required.",
            qrLabel: "QR Verify",
            btnClose: "✕ Close",
            btnPrint: "🖨️ Print Slip"
        }
    },

    hi: {
        brand: { title: "👁 दृष्टि (DRISHTI)", sub: "स्पष्टीकरणीय एआई रेटिना जांच (एसआईएच 2026)", engine: "<b>मॉडल इंजन:</b> PyTorch ResNet-18", statusReal: "● मॉडल सक्रिय (ACTIVE)", statusSupa: "☁ सुपाबेस क्लाउड कनेक्टेड", role: "भूमिका:" },
        modes: { simple: "🟢 सरल मोड (ASHA)", expert: "🩺 डॉक्टर मोड" },
        roles: { clinician: "🩺 विशेषज्ञ डॉक्टर (Doctor)", healthworker: "👤 स्वास्थ्य कार्यकर्ता (ASHA/PHC)", evaluator: "🔬 एसआईएच मूल्यांकनकर्ता" },
        langLabel: "🌐 भाषा:",
        audioBtn: "🔊 आवाज",
        nav: {
            screening: "🏥 1. नई स्क्रीनिंग (Screening)",
            queue: "📋 2. डॉक्टर समीक्षा कतार (Queue)",
            val: "🧪 3. मॉडल सत्यापन (Validation)",
            sim: "📊 4. टेलीमेडिसिन सिमुलेशन (Sim)",
            reports: "📄 5. स्क्रीनिंग रिपोर्ट (Reports)",
            dev: "⚙ सिस्टम और एपीआई (System)"
        },
        titles: {
            'tab-screening': ['नई रेटिना स्क्रीनिंग कार्यप्रणाली (Screening)', 'मरीज पंजीकरण, गुणवत्ता जांच, एआई विश्लेषण, ग्रैड-कैम स्पष्टीकरण और क्लाउड सिंक।'],
            'tab-queue': ['विशेषज्ञ नेत्र रोग विशेषज्ञ समीक्षा कतार (Queue)', 'सुपाबेस क्लाउड डेटाबेस से प्राथमिकता के अनुसार मामलों की लाइव सूची।'],
            'tab-validation': ['मॉडल सत्यापन और परीक्षण सुइट (Validation)', 'प्रमाणित परीक्षण डेटासेट पर संवेदनशीलता एवं सटीकता का मूल्यांकन।'],
            'tab-sim': ['जिला टेलीमेडिसिन सिमुलेशन (Telemed Sim)', 'डॉक्टर उपयोग दर एवं मरीज प्रतीक्षा समय विश्लेषण मॉडल।'],
            'tab-reports': ['स्क्रीनिंग रिपोर्ट अभिलेखागार (Reports)', 'सुपाबेस क्लाउड स्टोरेज से प्रमाणित त्रि-स्तरीय मेडिकल रिपोर्ट।'],
            'tab-developer': ['सिस्टम स्थिति एवं एपीआई निरीक्षक (Inspector)', 'हार्डवेयर विनिर्देश और रेस्ट एपीआई अनुबंध अनुपालन।']
        },
        ribbon: {
            step1: "1. मरीज विवरण दर्ज करें (Intake)",
            step2: "2. रेटिना फोटो लें (Photo)",
            step3: "3. सरल परिणाम और पर्ची (Result & Slip)"
        },
        card1: {
            header: "1. रेटिना छवि अधिग्रहण एवं मरीज विवरण",
            sampleLabel: "परीक्षण हेतु मानक सैंपल चुनें:",
            dragText: "रेटिना छवि खींचकर छोड़ें या ब्राउज़ करने के लिए क्लिक करें",
            dragSub: "स्मार्टफोन फंडस अडैप्टर, टॉपकॉन, ज़ीस, रेमिडियो से संगत (PNG/JPG)",
            btnCam: "📷 मोबाइल / डिवाइस कैमरा का उपयोग करें",
            viewOrig: "मूल छवि",
            viewEnh: "संवर्द्धित (CLAHE)",
            viewCam: "ग्रैड-कैम",
            viewOver: "साक्ष्य ओवरले",
            patHeader: "मरीज विवरण (सुपाबेस क्लाउड में सुरक्षित):",
            patIdPlh: "मरीज आईडी (जैसे PT-2026-4401)",
            patNamePlh: "मरीज का पूरा नाम (जैसे राजेश पटेल)",
            patAgePlh: "आयु"
        },
        card2: {
            header: "2. ऑप्टिकल गुणवत्ता जांच (ISO 10940 मानक)",
            chkTitle: "कैमरा फोटो गुणवत्ता जांच:",
            chkClarity: "👁️ स्पष्टता: <span id='valClarity' style='color:#16a34a;'>✅ स्पष्ट</span>",
            chkLight: "💡 रोशनी: <span id='valLight' style='color:#16a34a;'>✅ पर्याप्त</span>",
            chkCenter: "🎯 केंद्र: <span id='valCenter' style='color:#16a34a;'>✅ सही केंद्र</span>",
            enhancedLabel: "संवर्द्धित पूर्वावलोकन (CLAHE):",
            metricsHeader: "स्वचालित गुणवत्ता पैरामीटर:"
        },
        card3: {
            header: "3. एआई जांच परिणाम एवं ग्रैड-कैम स्पष्टीकरण",
            speakAdvice: "📢 मरीज को बोलकर सुनाएं",
            printSlip: "🖨️ मरीज परामर्श पर्ची",
            attentionHeader: "लेयर-4 ग्रैड-कैम मॉडल ध्यान (Attention)",
            heatmapTitle: "ग्रैड-कैम हीटमैप",
            overlayTitle: "साक्ष्य ओवरले"
        },
        provenance: {
            header: "मॉडल एवं साक्ष्य उत्पत्ति (Provenance)",
            qwkBadge: "प्रमाणित टेस्ट QWK: 0.870"
        },
        clinician: {
            header: "डॉक्टर निर्णय समर्थन एवं क्लाउड सिंक",
            recHeader: "नैदानिक सलाह:",
            btnValidate: "✔ एआई परिणाम सत्यापित करें",
            btnReject: "✖ अस्वीकार (पुनः फोटो आवश्यक)",
            btnOverride: "⚠ ग्रेड संशोधित करें",
            btnSubmit: "📥 समीक्षा कतार में भेजें",
            btnExport: "📄 3-स्तरीय रिपोर्ट निकालें",
            findingsLabel: "त्वरित निष्कर्ष:"
        },
        queue: {
            header: "विशेषज्ञ नेत्र रोग विशेषज्ञ समीक्षा कतार (Supabase Cloud)",
            refreshBtn: "↻ लाइव कतार रीफ्रेश करें"
        },
        validation: {
            header: "मॉडल सत्यापन और परीक्षण सुइट",
            btnDemo: "1. परीक्षण बैच स्क्रीनिंग",
            btnBench: "2. बेंचमार्क टेस्ट सेट",
            btnRun: "🚀 बैच स्क्रीनिंग शुरू करें",
            btnLoad: "📦 10 डेमो सैंपल लोड करें"
        },
        simulation: {
            header: "जिला स्तरीय टेलीमेडिसिन सिमुलेशन (1,20,000 मरीज/वर्ष)",
            recalcBtn: "↻ मॉडल पुनर्गणना करें"
        },
        reports: {
            header: "स्क्रीनिंग रिपोर्ट अभिलेखागार (Supabase)",
            refreshBtn: "↻ रिपोर्ट अभिलेखागार रीफ्रेश करें"
        },
        developer: {
            header: "सिस्टम स्थिति एवं एपीआई अनुबंध निरीक्षक"
        },
        slip: {
            title: "दृष्टि — टेली-रेटिना जांच एवं परामर्श पर्ची",
            subtitle: "राष्ट्रीय अंधापन नियंत्रण कार्यक्रम (NPCB) सहयोग | SIH 2026",
            lblName: "मरीज का नाम:",
            lblId: "मरीज आईडी:",
            lblAge: "आयु / लिंग:",
            lblEye: "जांची गई आंख:",
            lblDate: "स्क्रीनिंग दिनांक:",
            lblCenter: "केंद्र:",
            tipsTitle: "मरीज और परिवार हेतु मुख्य सावधानियां (Important Advice):",
            tip1: "🩸 <b>1. शुगर नियंत्रण:</b> खाली पेट और खाने के बाद ब्लड शुगर की नियमित जांच कराएं (HbA1c < 7.0%)।",
            tip2: "💊 <b>2. नियमित दवा:</b> डॉक्टर द्वारा बताई गई मधुमेह और बीपी की दवा समय पर लें।",
            tip3: "🏥 <b>3. अस्पताल जाएं:</b> यह पर्ची अपने साथ जिला अस्पताल / मेडिकल कॉलेज नेत्र विभाग ले जाएं।",
            footerDoc: "<b>सत्यापित टेली-नेत्र विशेषज्ञ:</b> डॉ. राजेश कुमार, MD (नेत्र रोग)",
            footerNotice: "*यह कम्प्यूटरीकृत टेली-स्क्रीनिंग पर्ची है, किसी भौतिक हस्ताक्षर की आवश्यकता नहीं है।",
            qrLabel: "QR सत्यापन",
            btnClose: "✕ बंद करें",
            btnPrint: "🖨️ पर्ची प्रिंट करें"
        }
    },

    mr: {
        brand: { title: "👁 दृष्टी (DRISHTI)", sub: "स्पष्टीकरणीय एआय डोळ्यांची तपासणी (SIH 2026)", engine: "<b>मॉडेल इंजिन:</b> PyTorch ResNet-18", statusReal: "● मॉडेल सक्रिय (ACTIVE)", statusSupa: "☁ सुपाबेस क्लाउड जोडलेले", role: "भूमिका:" },
        modes: { simple: "🟢 सोपा मोड (ASHA)", expert: "🩺 डॉक्टर मोड" },
        roles: { clinician: "🩺 तज्ज्ञ डॉक्टर (Doctor)", healthworker: "👤 आरोग्य सेवक (ASHA/PHC)", evaluator: "🔬 एसआयएच परीक्षक" },
        langLabel: "🌐 भाषा:",
        audioBtn: "🔊 आवाज",
        nav: {
            screening: "🏥 1. नवीन तपासणी (Screening)",
            queue: "📋 2. डॉक्टर पुनरावलोकन रांग",
            val: "🧪 3. मॉडेल प्रमाणीकरण सुइट",
            sim: "📊 4. टेलिमेडिसीन सिम्युलेशन",
            reports: "📄 5. तपासणी अहवाल (Reports)",
            dev: "⚙ सिस्टीम आणि एपीआय (System)"
        },
        titles: {
            'tab-screening': ['नवीन रेटिना तपासणी कार्यप्रवाह (Screening)', 'रुग्ण नोंदणी, फोटो गुणवत्ता तपासणी, एआय विश्लेषण आणि क्लाउड सिंक.'],
            'tab-queue': ['नेत्रतज्ज्ञ पुनरावलोकन रांग (Review Queue)', 'सुपाबेस क्लाउडवरून तज्ज्ञ डॉक्टरांच्या अंतिम मान्यतेसाठी प्रकरणांची यादी.'],
            'tab-validation': ['मॉडेल पडताळणी सुइट (Model Validation)', 'प्रमाणित चाचणी डेटासेटवर मॉडेल अचूकता आणि संवेदनशीलता मूल्यमापन.'],
            'tab-sim': ['जिल्हा पातळीवरील टेलिमेडिसीन सिम्युलेशन', 'रुग्ण प्रतीक्षा वेळ आणि नेत्रतज्ज्ञांच्या कार्यक्षमतेचे विश्लेषण मॉडेल.'],
            'tab-reports': ['तपासणी अहवाल संग्रह (Screening Reports)', 'सुपाबेस क्लाउडवरून प्रमाणित क्लिनिकल अहवाल डाउनलोड करा.'],
            'tab-developer': ['सिस्टीम आणि रेस्ट एपीआय इन्स्पेक्टर', 'हार्डवेअर आणि एपीआय v1.0 मानकांची पडताळणी.']
        },
        ribbon: {
            step1: "1. रुग्णाची माहिती नोंदवा",
            step2: "2. रेटिना फोटो काढा",
            step3: "3. निकाल आणि संदर्भ स्लिप"
        },
        card1: {
            header: "1. रेटिना फोटो संपादन आणि रुग्णाची माहिती",
            sampleLabel: "चाचणीसाठी नमुना निवडा:",
            dragText: "रेटिना फोटो येथे ओढा किंवा अपलोड करण्यासाठी क्लिक करा",
            dragSub: "स्मार्टफोन अडॅप्टर, टॉपकॉन, झीस, रेमिडिओ सुसंगत (PNG/JPG)",
            btnCam: "📷 मोबाईल / डिव्हाइस कॅमेरा वापरा",
            viewOrig: "मूळ फोटो",
            viewEnh: "सुधारित (CLAHE)",
            viewCam: "ग्रॅड-कॅम",
            viewOver: "साक्ष्य आच्छादन",
            patHeader: "रुग्णाची माहिती (सुपाबेस क्लाउड):",
            patIdPlh: "रुग्ण आयडी (उदा. PT-2026-4401)",
            patNamePlh: "रुग्णाचे पूर्ण नाव (उदा. राजेश पटेल)",
            patAgePlh: "वय"
        },
        card2: {
            header: "2. ऑप्टिकल गुणवत्ता तपासणी (ISO 10940)",
            chkTitle: "कॅमेरा फोटो गुणवत्ता तपासणी:",
            chkClarity: "👁️ स्पष्टता: <span id='valClarity' style='color:#16a34a;'>✅ स्पष्ट</span>",
            chkLight: "💡 प्रकाश: <span id='valLight' style='color:#16a34a;'>✅ पुरेसा</span>",
            chkCenter: "🎯 केंद्र: <span id='valCenter' style='color:#16a34a;'>✅ योग्य केंद्र</span>",
            enhancedLabel: "सुधारित पूर्वावलोकन (CLAHE):",
            metricsHeader: "स्वयंचलित गुणवत्ता मापदंड:"
        },
        card3: {
            header: "3. एआय तपासणी निकाल आणि ग्रॅड-कॅम स्पष्टीकरण",
            speakAdvice: "📢 रुग्णाला आवाजात ऐकवा",
            printSlip: "🖨️ रुग्ण संदर्भ स्लिप",
            attentionHeader: "लेयर-4 ग्रॅड-कॅम मॉडेल लक्ष (Attention)",
            heatmapTitle: "ग्रॅड-कॅम हीटमॅप",
            overlayTitle: "साक्ष्य आच्छादन"
        },
        provenance: {
            header: "मॉडेल आणि साक्ष्य उत्पत्ती (Provenance)",
            qwkBadge: "प्रमाणित चाचणी QWK: 0.870"
        },
        clinician: {
            header: "डॉक्टर निर्णय समर्थन आणि क्लाउड सिंक",
            recHeader: "क्लिनिकल शिफारस:",
            btnValidate: "✔ एआय निकाल सत्यापित करा",
            btnReject: "✖ नाकारा (पुन्हा फोटो काढा)",
            btnOverride: "⚠ ग्रेड बदला",
            btnSubmit: "📥 पुनरावलोकन रांगेत पाठवा",
            btnExport: "📄 3-भागांचा अहवाल काढा",
            findingsLabel: "त्वरित निष्कर्ष:"
        },
        queue: {
            header: "नेत्रतज्ज्ञ पुनरावलोकन रांग (Supabase Cloud)",
            refreshBtn: "↻ थेट रांग रीफ्रेश करा"
        },
        validation: {
            header: "मॉडेल पडताळणी सुइट",
            btnDemo: "1. चाचणी बॅच तपासणी",
            btnBench: "2. बेंचमार्क चाचणी संच",
            btnRun: "🚀 बॅच तपासणी सुरू करा",
            btnLoad: "📦 10 नमुने लोड करा"
        },
        simulation: {
            header: "जिल्हा टेलिमेडिसीन सिम्युलेशन (1,20,000 रुग्ण/वर्ष)",
            recalcBtn: "↻ मॉडेल पुन्हा मोजा"
        },
        reports: {
            header: "तपासणी अहवाल संग्रह (Supabase)",
            refreshBtn: "↻ अहवाल संग्रह रीफ्रेश करा"
        },
        developer: {
            header: "सिस्टीम स्थिती आणि एपीआय निरीक्षक"
        },
        slip: {
            title: "दृष्टी — टेली-रेटिना तपासणी आणि संदर्भ स्लिप",
            subtitle: "राष्ट्रीय अंधत्व नियंत्रण कार्यक्रम (NPCB) सहकार्य | SIH 2026",
            lblName: "रुग्णाचे नाव:",
            lblId: "रुग्ण आयडी:",
            lblAge: "वय / लिंग:",
            lblEye: "तपासलेला डोळा:",
            lblDate: "तपासणी दिनांक:",
            lblCenter: "केंद्र:",
            tipsTitle: "रुग्ण आणि कुटुंबासाठी महत्त्वाची काळजी:",
            tip1: "🩸 <b>1. साखर नियंत्रण:</b> उपाशीपोटी आणि जेवणानंतर रक्तातील साखरेची नियमित तपासणी करा (HbA1c < 7.0%).",
            tip2: "💊 <b>2. नियमित औषधे:</b> डॉक्टरांनी दिलेली मधुमेहाची आणि बीपीची औषधे वेळेवर घ्या.",
            tip3: "🏥 <b>3. रुग्णालयात जा:</b> ही संदर्भ स्लिप सोबत घेऊन जिल्हा रुग्णालयातील नेत्र विभागात जा.",
            footerDoc: "<b>प्रमाणित टेली-नेत्रतज्ज्ञ:</b> डॉ. राजेश कुमार, MD (नेत्ररोग)",
            footerNotice: "*ही संगणकीकृत टेली-स्क्रीनिंग स्लिप आहे, कोणत्याही प्रत्यक्ष स्वाक्षरीची आवश्यकता नाही.",
            qrLabel: "QR पडताळणी",
            btnClose: "✕ बंद करा",
            btnPrint: "🖨️ स्लिप प्रिंट करा"
        }
    },

    gu: {
        brand: { title: "👁 દ્રષ્ટિ (DRISHTI)", sub: "સમજૂતીત્મક AI આંખ તપાસ પ્લેટફોર્મ (SIH 2026)", engine: "<b>મોડેલ એન્જિન:</b> PyTorch ResNet-18", statusReal: "● મોડેલ સક્રિય (ACTIVE)", statusSupa: "☁ સુપાબેસ ક્લાઉડ કનેક્ટેડ", role: "ભૂમિકા:" },
        modes: { simple: "🟢 સરળ મોડ (ASHA)", expert: "🩺 ડૉક્ટર મોડ" },
        roles: { clinician: "🩺 નિષ્ણાત ડૉક્ટર (Doctor)", healthworker: "👤 આરોગ્ય કાર્યકર (ASHA/PHC)", evaluator: "🔬 SIH મૂલ્યાંકનકાર" },
        langLabel: "🌐 ભાષા:",
        audioBtn: "🔊 અવાજ",
        nav: {
            screening: "🏥 1. નવી તપાસ (Screening)",
            queue: "📋 2. ડૉક્ટર સમીક્ષા કતાર",
            val: "🧪 3. મોડેલ માન્યતા સ્યુટ",
            sim: "📊 4. ટેલિમેડિસિન સિમ્યુલેશન",
            reports: "📄 5. તપાસ અહેવાલો (Reports)",
            dev: "⚙ સિસ્ટમ અને API ઇન્સ્પેક્ટર"
        },
        titles: {
            'tab-screening': ['નવી રેટિના સ્ક્રિનિંગ કાર્યપ્રણાલી', 'દર્દી નોંધણી, ઇમેજ ક્વોલિટી ચેક, AI વિશ્લેષણ અને ક્લાઉડ સિંક.'],
            'tab-queue': ['નેત્ર નિષ્ણાત સમીક્ષા કતાર (Review Queue)', 'સુપાબેસ ક્લાઉડ પરથી પ્રમાણિત ડૉક્ટરની મંજૂરી માટે કેસોની યાદી.'],
            'tab-validation': ['મોડેલ માન્યતા સ્યુટ (Validation Suite)', 'ચકાસાયેલ પરીક્ષણ ડેટાસેટ પર ચોકસાઈ અને સંવેદનશીલતાનું મૂલ્યાંકન.'],
            'tab-sim': ['જિલ્લા કક્ષાનું ટેલિમેડિસિન સિમ્યુલેશન', 'દર્દી રાહ જોવાનો સમય અને આંખના ડૉક્ટરોની ક્ષમતાનું વિશ્લેષણ મોડેલ.'],
            'tab-reports': ['તપાસ અહેવાલ આર્કાઇવ (Screening Reports)', 'સુપાબેસ ક્લાઉડમાંથી પ્રમાણિત મેડિકલ રિપોર્ટ્સ મેળવો.'],
            'tab-developer': ['સિસ્ટમ સ્થિતિ અને REST API ઇન્સ્પેક્ટર', 'હાર્ડવેર અને API v1.0 ધોરણોનું પાલન તપાસો.']
        },
        ribbon: {
            step1: "1. દર્દીની વિગત દાખલ કરો",
            step2: "2. રેટિનાનો ફોટો લો",
            step3: "3. પરિણામ અને રેફરલ સ્લિપ"
        },
        card1: {
            header: "1. રેટિના ફોટો અને દર્દીની વિગત",
            sampleLabel: "પરીક્ષણ માટે નમૂનો પસંદ કરો:",
            dragText: "રેટિના ફોટો અહીં ખેંચો અથવા અપલોડ કરવા ક્લિક કરો",
            dragSub: "સ્માર્ટફોન એડેપ્ટર, ટોપકોન, ઝીસ, રેમિડિયો સુસંગત (PNG/JPG)",
            btnCam: "📷 મોબાઇલ / ડિવાઇસ કેમેરાનો ઉપયોગ કરો",
            viewOrig: "મૂળ ફોટો",
            viewEnh: "સંવર્ધિત (CLAHE)",
            viewCam: "Grad-CAM",
            viewOver: "પુરાવા ઓવરલે",
            patHeader: "દર્દીની વિગત (સુપાબેસ ક્લાઉડ):",
            patIdPlh: "દર્દી ID (દા.ત. PT-2026-4401)",
            patNamePlh: "દર્દીનું પૂરું નામ (દા.ત. રાજેશ પટેલ)",
            patAgePlh: "ઉંમર"
        },
        card2: {
            header: "2. ઓપ્ટિકલ ગુણવત્તા ચકાસણી (ISO 10940)",
            chkTitle: "કેમેરા ફોટો ગુણવત્તા ચકાસણી:",
            chkClarity: "👁️ સ્પષ્ટતા: <span id='valClarity' style='color:#16a34a;'>✅ સ્પષ્ટ</span>",
            chkLight: "💡 પ્રકાશ: <span id='valLight' style='color:#16a34a;'>✅ પૂરતો</span>",
            chkCenter: "🎯 કેન્દ્ર: <span id='valCenter' style='color:#16a34a;'>✅ યોગ્ય કેન્દ્ર</span>",
            enhancedLabel: "સંવર્ધિત પૂર્વાવલોકન (CLAHE):",
            metricsHeader: "સ્વચાલિત ગુણવત્તા પરિમાણો:"
        },
        card3: {
            header: "3. AI તપાસ પરિણામ અને Grad-CAM સમજૂતી",
            speakAdvice: "📢 દર્દીને બોલીને સંભળાવો",
            printSlip: "🖨️ દર્દી રેફરલ સ્લિપ",
            attentionHeader: "લેયર-4 Grad-CAM મોડેલ ધ્યાન (Attention)",
            heatmapTitle: "Grad-CAM હીટમેપ",
            overlayTitle: "પુરાવા ઓવરલે"
        },
        provenance: {
            header: "મોડેલ અને પુરાવા મૂળ (Provenance)",
            qwkBadge: "પ્રમાણિત ટેસ્ટ QWK: 0.870"
        },
        clinician: {
            header: "ડૉક્ટર નિર્ણય સહાય અને ક્લાઉડ સિંક",
            recHeader: "ક્લિનિકલ ભલામણ:",
            btnValidate: "✔ AI પરિણામ માન્ય કરો",
            btnReject: "✖ અસ્વીકાર (ફરી ફોટો લો)",
            btnOverride: "⚠ ગ્રેડ બદલો",
            btnSubmit: "📥 સમીક્ષા કતારમાં મોકલો",
            btnExport: "📄 3-ભાગનો અહેવાલ કાઢો",
            findingsLabel: "ઝડપી તારણો:"
        },
        queue: {
            header: "નેત્ર નિષ્ણાત સમીક્ષા કતાર (Supabase Cloud)",
            refreshBtn: "↻ લાઇવ કતાર રીફ્રેશ કરો"
        },
        validation: {
            header: "મોડેલ માન્યતા સ્યુટ",
            btnDemo: "1. ડેમો બેચ સ્ક્રિનિંગ",
            btnBench: "2. બેંચમાર્ક ટેસ્ટ સેટ",
            btnRun: "🚀 બેચ સ્ક્રિનિંગ શરૂ કરો",
            btnLoad: "📦 10 નમૂના લોડ કરો"
        },
        simulation: {
            header: "જિલ્લા કક્ષાનું ટેલિમેડિસિન સિમ્યુલેશન (1,20,000 દર્દીઓ/વર્ષ)",
            recalcBtn: "↻ મોડેલ પુનઃ ગણતરી કરો"
        },
        reports: {
            header: "તપાસ અહેવાલ આર્કાઇવ (Supabase)",
            refreshBtn: "↻ અહેવાલ આર્કાઇવ રીફ્રેશ કરો"
        },
        developer: {
            header: "સિસ્ટમ સ્થિતિ અને API ઇન્સ્પેક્ટર"
        },
        slip: {
            title: "દ્રષ્ટિ — ટેલી-રેટિના તપાસ અને રેફરલ સ્લિપ",
            subtitle: "રાષ્ટ્રીય અંધત્વ નિયંત્રણ કાર્યક્રમ (NPCB) સહયોગ | SIH 2026",
            lblName: "દર્દીનું નામ:",
            lblId: "દર્દી ID:",
            lblAge: "ઉંમર / જાતિ:",
            lblEye: "તપાસેલી આંખ:",
            lblDate: "તપાસ તારીખ:",
            lblCenter: "કેન્દ્ર:",
            tipsTitle: "દર્દી અને પરિવાર માટે મહત્વપૂર્ણ સલાહ:",
            tip1: "🩸 <b>1. શુગર નિયંત્રણ:</b> ભૂખ્યા પેટે અને જમ્યા પછી બ્લડ શુગરની નિયમિત તપાસ કરાવો (HbA1c < 7.0%).",
            tip2: "💊 <b>2. નિયમિત દવા:</b> ડૉક્ટર દ્વારા આપેલી ડાયાબિટીસ અને બીપીની દવાઓ સમયસર લો.",
            tip3: "🏥 <b>3. હોસ્પિટલ જાઓ:</b> આ સ્લિપ સાથે જિલ્લા હોસ્પિટલના આંખના વિભાગમાં તપાસ કરાવો.",
            footerDoc: "<b>પ્રમાણિત ટેલી-આંખના નિષ્ણાત:</b> ડૉ. રાજેશ કુમાર, MD (ઓપ્થેલ્મોલોજી)",
            footerNotice: "*આ કમ્પ્યુટરાઇઝ્ડ ટેલી-સ્ક્રિનિંગ સ્લિપ છે, કોઈ ભૌતિક સહીની જરૂર નથી.",
            qrLabel: "QR ચકાસણી",
            btnClose: "✕ બંધ કરો",
            btnPrint: "🖨️ સ્લિપ પ્રિન્ટ કરો"
        }
    },

    ta: {
        brand: { title: "👁 திருஷ்டி (DRISHTI)", sub: "விளக்கக்கூடிய AI விழித்திரை பரிசோதனை (SIH 2026)", engine: "<b>மாதிரி இயந்திரம்:</b> PyTorch ResNet-18", statusReal: "● மாதிரி செயலில் உள்ளது", statusSupa: "☁ சுபாபேஸ் இணைக்கப்பட்டுள்ளது", role: "பங்கு:" },
        modes: { simple: "🟢 எளிய முறை (ASHA)", expert: "🩺 மருத்துவர் முறை" },
        roles: { clinician: "🩺 கண் மருத்துவர் (Doctor)", healthworker: "👤 சுகாதார பணியாளர் (ASHA/PHC)", evaluator: "🔬 SIH மதிப்பீட்டாளர்" },
        langLabel: "🌐 மொழி:",
        audioBtn: "🔊 குரல்",
        nav: {
            screening: "🏥 1. புதிய பரிசோதனை (Screening)",
            queue: "📋 2. மருத்துவர் மதிப்பாய்வு வரிசை",
            val: "🧪 3. மாதிரி சரிபார்ப்பு தொகுப்பு",
            sim: "📊 4. தொலைமருத்துவ உருவகப்படுத்துதல்",
            reports: "📄 5. பரிசோதனை அறிக்கைகள்",
            dev: "⚙ கணினி & API ஆய்வாளர்"
        },
        titles: {
            'tab-screening': ['புதிய விழித்திரை பரிசோதனை பணிப்பாய்வு', 'நோயாளி பதிவு, படத் தர சோதனை, AI பகுப்பாய்வு மற்றும் கிளவுட் ஒத்திசைவு.'],
            'tab-queue': ['கண் மருத்துவர் மதிப்பாய்வு வரிசை (Supabase Cloud)', 'நிபுணர் மருத்துவர் ஒப்புதலுக்காக கிளவுட் தரவுத்தளத்திலிருந்து நேரலை வழக்குகள்.'],
            'tab-validation': ['மாதிரி சரிபார்ப்பு தொகுப்பு (Validation Suite)', 'சோதனை தரவுத்தொகுப்பில் துல்லியம் மற்றும் உணர்திறன் மதிப்பீடு.'],
            'tab-sim': ['மாவட்ட அளவிலான தொலைமருத்துவ உருவகப்படுத்துதல்', 'நோயாளி காத்திருப்பு நேரம் மற்றும் மருத்துவர் பணிச்சுமை மாதிரி.'],
            'tab-reports': ['பரிசோதனை அறிக்கை காப்பகம் (Screening Reports)', 'கிளவுட் சேமிப்பகத்திலிருந்து மருத்துவ அறிக்கைகளைப் பெறுங்கள்.'],
            'tab-developer': ['கணினி நிலை மற்றும் REST API ஆய்வாளர்', 'வன்பொருள் மற்றும் API v1.0 தரநிலைகளின் இணக்கத்தை சரிபார்க்கவும்.']
        },
        ribbon: {
            step1: "1. நோயாளி விவரங்களை உள்ளிடவும்",
            step2: "2. விழித்திரை படம் எடுக்கவும்",
            step3: "3. முடிவு மற்றும் பரிந்துரை சீட்டு"
        },
        card1: {
            header: "1. விழித்திரை படம் மற்றும் நோயாளி விவரங்கள்",
            sampleLabel: "மாதிரி பரிசோதனை வழக்கை தேர்வு செய்யவும்:",
            dragText: "விழித்திரை படத்தை இழுத்து விடவும் அல்லது பதிவேற்ற கிளிக் செய்யவும்",
            dragSub: "ஸ்மார்ட்போன் அடாப்டர், டாப்கான், ஜெய்ஸ், ரெமிடியோ இணக்கமானது (PNG/JPG)",
            btnCam: "📷 கேமராவை பயன்படுத்தவும்",
            viewOrig: "அசல் படம்",
            viewEnh: "மேம்படுத்தப்பட்டது (CLAHE)",
            viewCam: "Grad-CAM",
            viewOver: "மேலடுக்கு",
            patHeader: "நோயாளி விவரங்கள் (சுபாபேஸ் கிளவுட்):",
            patIdPlh: "நோயாளி ID (எ.கா. PT-2026-4401)",
            patNamePlh: "முழு பெயர் (எ.கா. ராஜேஷ் படேல்)",
            patAgePlh: "வயது"
        },
        card2: {
            header: "2. படத் தர சரிபார்ப்பு (ISO 10940)",
            chkTitle: "கேமரா படத் தர சரிபார்ப்பு:",
            chkClarity: "👁️ தெளிவு: <span id='valClarity' style='color:#16a34a;'>✅ தெளிவானது</span>",
            chkLight: "💡 வெளிச்சம்: <span id='valLight' style='color:#16a34a;'>✅ போதுமானது</span>",
            chkCenter: "🎯 மையம்: <span id='valCenter' style='color:#16a34a;'>✅ சரியான மையம்</span>",
            enhancedLabel: "மேம்படுத்தப்பட்ட படம் (CLAHE):",
            metricsHeader: "தானியங்கி தர அளவீடுகள்:"
        },
        card3: {
            header: "3. AI பரிசோதனை முடிவு மற்றும் Grad-CAM விளக்கம்",
            speakAdvice: "📢 நோயாளிக்கு குரலில் கேட்கவும்",
            printSlip: "🖨️ நோயாளி பரிந்துரை சீட்டு",
            attentionHeader: "அடுக்கு-4 Grad-CAM மாதிரி கவனம்",
            heatmapTitle: "Grad-CAM வெப்ப வரைபடம்",
            overlayTitle: "சான்று மேலடுக்கு"
        },
        provenance: {
            header: "மாதிரி மற்றும் சான்று தோற்றம் (Provenance)",
            qwkBadge: "சரிபார்க்கப்பட்ட சோதனை QWK: 0.870"
        },
        clinician: {
            header: "மருத்துவர் முடிவு ஆதரவு மற்றும் கிளவுட் ஒத்திசைவு",
            recHeader: "மருத்துவ பரிந்துரை:",
            btnValidate: "✔ AI முடிவை சரிபார்க்கவும்",
            btnReject: "✖ நிராகரி (மீண்டும் படம் எடுக்கவும்)",
            btnOverride: "⚠ நிலையை மாற்றவும்",
            btnSubmit: "📥 மதிப்பாய்வு வரிசைக்கு அனுப்பவும்",
            btnExport: "📄 3-பகுதி அறிக்கையை ஏற்றுமதி செய்",
            findingsLabel: "விரைவான கண்டுபிடிப்புகள்:"
        },
        queue: {
            header: "கண் மருத்துவர் மதிப்பாய்வு வரிசை (Supabase Cloud)",
            refreshBtn: "↻ நேரலை வரிசையை புதுப்பிக்கவும்"
        },
        validation: {
            header: "மாதிரி சரிபார்ப்பு தொகுப்பு",
            btnDemo: "1. மாதிரி தொகுதி பரிசோதனை",
            btnBench: "2. ஒப்பீட்டு சோதனை தொகுப்பு",
            btnRun: "🚀 தொகுதி பரிசோதனையைத் தொடங்கவும்",
            btnLoad: "📦 10 மாதிரி படங்களை ஏற்றவும்"
        },
        simulation: {
            header: "மாவட்ட அளவிலான தொலைமருத்துவ உருவகப்படுத்துதல் (1,20,000 நோயாளிகள்/ஆண்டு)",
            recalcBtn: "↻ மாதிரியை மீண்டும் கணக்கிடுங்கள்"
        },
        reports: {
            header: "பரிசோதனை அறிக்கை காப்பகம் (Supabase)",
            refreshBtn: "↻ அறிக்கை காப்பகத்தை புதுப்பிக்கவும்"
        },
        developer: {
            header: "கணினி நிலை மற்றும் API ஆய்வாளர்"
        },
        slip: {
            title: "திருஷ்டி — டெலி-விழித்திரை பரிசோதனை & பரிந்துரை சீட்டு",
            subtitle: "தேசிய பார்வையிழப்பு தடுப்பு திட்டம் (NPCB) ஆதரவு | SIH 2026",
            lblName: "நோயாளி பெயர்:",
            lblId: "நோயாளி ID:",
            lblAge: "வயது / பாலினம்:",
            lblEye: "பரிசோதிக்கப்பட்ட கண்:",
            lblDate: "பரிசோதனை தேதி:",
            lblCenter: "மையம்:",
            tipsTitle: "நோயாளி மற்றும் குடும்பத்திற்கான முக்கிய வழிகாட்டுதல்:",
            tip1: "🩸 <b>1. சர்க்கரை கட்டுப்பாடு:</b> இரத்த சர்க்கரை அளவை தவறாமல் பரிசோதிக்கவும் (HbA1c < 7.0%).",
            tip2: "💊 <b>2. தினசரி மருந்துகள்:</b> மருத்துவர் பரிந்துரைத்த சர்க்கரை மற்றும் இரத்த அழுத்த மருந்துகளை தவறாமல் உட்கொள்ளவும்.",
            tip3: "🏥 <b>3. மருத்துவமனைக்குச் செல்லுங்கள்:</b> இந்த சீட்டுடன் மாவட்ட மருத்துவமனை கண் மருத்துவ பிரிவுக்குச் செல்லவும்.",
            footerDoc: "<b>சரிபார்க்கப்பட்ட கண் மருத்துவர்:</b> டாக்டர் ராஜேஷ் குமார், MD (கண் மருத்துவம்)",
            footerNotice: "*இது கணினி சரிபார்க்கப்பட்ட டெலி-ஸ்கிரீனிங் சீட்டு, கையொப்பம் தேவையில்லை.",
            qrLabel: "QR சரிபார்ப்பு",
            btnClose: "✕ மூடு",
            btnPrint: "🖨️ சீட்டை அச்சிடுக"
        }
    }
};

let currentLang = localStorage.getItem('drishti_lang') || 'en';

function changeLanguage(lang) {
    if (!I18N_FULL[lang]) lang = 'en';
    currentLang = lang;
    localStorage.setItem('drishti_lang', lang);

    // Apply comprehensive translation to all elements
    applyFullTranslation(lang);

    // Re-translate dynamic elements if a case is currently loaded
    if (window.currentCase) {
        if (typeof updateScreeningUI === 'function') {
            updateScreeningUI(window.currentCase);
        }
        if (typeof updateRuralTrafficLight === 'function') {
            updateRuralTrafficLight(window.currentCase, lang);
        }
    }
}

function applyFullTranslation(lang) {
    const d = I18N_FULL[lang] || I18N_FULL.en;

    // Helper safely setting innerText
    const setText = (id, text) => {
        const el = document.getElementById(id);
        if (el && text !== undefined) el.innerText = text;
    };

    // Helper safely setting innerHTML
    const setHtml = (id, html) => {
        const el = document.getElementById(id);
        if (el && html !== undefined) el.innerHTML = html;
    };

    // 1. Brand & Header Actions
    setHtml('sidebarBrandTitle', d.brand.title);
    setText('sidebarBrandSub', d.brand.sub);
    setHtml('sidebarModelEngine', d.brand.engine);
    setText('sidebarStatusPill', d.brand.statusReal);
    setText('sidebarSupabasePill', d.brand.statusSupa);
    setText('roleLabel', d.brand.role);
    setText('btnModeSimple', d.modes.simple);
    setText('btnModeExpert', d.modes.expert);
    setText('langLabel', d.langLabel);
    setText('voiceGuideBtn', d.audioBtn);

    // Role dropdown options
    setText('roleOptClinician', d.roles.clinician);
    setText('roleOptHW', d.roles.healthworker);
    setText('roleOptEval', d.roles.evaluator);

    // 2. Navigation items
    setText('nav-item-screening', d.nav.screening);
    setText('nav-item-queue', d.nav.queue);
    setText('nav-item-validation', d.nav.val);
    setText('nav-item-sim', d.nav.sim);
    setText('nav-item-reports', d.nav.reports);
    setText('nav-item-developer', d.nav.dev);

    // 3. Tab Titles & Subtitles
    const activeTab = window.currentTab || 'tab-screening';
    if (d.titles[activeTab]) {
        setText('viewTitle', d.titles[activeTab][0]);
        setText('viewSubtitle', d.titles[activeTab][1]);
    }

    // 4. Step-by-Step Guided Ribbon
    setText('step1Text', d.ribbon.step1);
    setText('step2Text', d.ribbon.step2);
    setText('step3Text', d.ribbon.step3);

    // 5. Card 1: Image Acquisition & Intake
    setText('card1Header', d.card1.header);
    setText('sampleSelectLabel', d.card1.sampleLabel);
    setText('dropText', d.card1.dragText);
    setText('dropSub', d.card1.dragSub);
    setText('btnCamAcq', d.card1.btnCam);
    setText('btnViewOrig', d.card1.viewOrig);
    setText('btnViewEnh', d.card1.viewEnh);
    setText('btnViewCam', d.card1.viewCam);
    setText('btnViewOver', d.card1.viewOver);
    setText('labelPatientContext', d.card1.patHeader);
    
    const patId = document.getElementById('patId');
    if (patId) patId.placeholder = d.card1.patIdPlh;
    const patName = document.getElementById('patName');
    if (patName) patName.placeholder = d.card1.patNamePlh;
    const patAge = document.getElementById('patAge');
    if (patAge) patAge.placeholder = d.card1.patAgePlh;

    // 6. Card 2: Quality Gate & Checklist
    setText('card2Header', d.card2.header);
    setText('chkTitle', d.card2.chkTitle);
    setHtml('chkClarity', d.card2.chkClarity);
    setHtml('chkLight', d.card2.chkLight);
    setHtml('chkCenter', d.card2.chkCenter);
    setText('labelEnhanced', d.card2.enhancedLabel);
    setText('labelQualityMetrics', d.card2.metricsHeader);

    // 7. Card 3: AI Screening & Traffic Light
    setText('card3Header', d.card3.header);
    setText('lblSpeakAdvice', d.card3.speakAdvice);
    setText('lblPrintSlip', d.card3.printSlip);
    setText('labelLayer4', d.card3.attentionHeader);
    setText('labelCamHeatmap', d.card3.heatmapTitle);
    setText('labelOverlay', d.card3.overlayTitle);

    // 8. Provenance Box
    setText('provHeaderTitle', d.provenance.header);
    setText('provBadge', d.provenance.qwkBadge);

    // 9. Clinician Support
    setText('clinHeaderTitle', d.clinician.header);
    setText('recActionHeaderTitle', d.clinician.recHeader);
    setText('btnValidateAi', d.clinician.btnValidate);
    setText('btnRejectAi', d.clinician.btnReject);
    setText('btnOverrideAi', d.clinician.btnOverride);
    setText('btnSubmitQueue', d.clinician.btnSubmit);
    setText('btnExportReport', d.clinician.btnExport);
    setText('labelQuickFindings', d.clinician.findingsLabel);

    // 10. Queue Tab
    setText('queueHeaderTitle', d.queue.header);
    setText('btnRefreshQueue', d.queue.refreshBtn);

    // 11. Validation Tab
    setText('valHeaderTitle', d.validation.header);
    setText('btnTabDemo', d.validation.btnDemo);
    setText('btnTabBench', d.validation.btnBench);
    setText('btnRunBatch', d.validation.btnRun);
    setText('btnLoadDemoBatch', d.validation.btnLoad);

    // 12. Simulation Tab
    setText('simHeaderTitle', d.simulation.header);
    setText('btnRecalcSim', d.simulation.recalcBtn);

    // 13. Reports Tab
    setText('reportsHeaderTitle', d.reports.header);
    setText('btnRefreshReports', d.reports.refreshBtn);

    // 14. Developer Tab
    setText('devHeaderTitle', d.developer.header);

    // 15. Referral Slip Modal (Strict translation / restoration)
    setText('slipHeaderTitle', d.slip.title);
    setText('slipHeaderSub', d.slip.subtitle);
    setText('slipLblName', d.slip.lblName);
    setText('slipLblId', d.slip.lblId);
    setText('slipLblAge', d.slip.lblAge);
    setText('slipLblEye', d.slip.lblEye);
    setText('slipLblDate', d.slip.lblDate);
    setText('slipLblCenter', d.slip.lblCenter);
    setText('slipTipsTitle', d.slip.tipsTitle);
    setHtml('slipTip1', d.slip.tip1);
    setHtml('slipTip2', d.slip.tip2);
    setHtml('slipTip3', d.slip.tip3);
    setHtml('slipFooterDoc', d.slip.footerDoc);
    setText('slipFooterNotice', d.slip.footerNotice);
    setText('slipQrLabel', d.slip.qrLabel);
    setText('btnSlipClose', d.slip.btnClose);
    setText('btnSlipPrint', d.slip.btnPrint);
}
