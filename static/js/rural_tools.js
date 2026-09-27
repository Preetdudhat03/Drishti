/**
 * DRISHTI Rural Usability & Frontline Tools (rural_tools.js)
 * Includes: Mode switcher, Traffic light card updater, Spoken patient audio guidance,
 * Bilingual referral slip generator, Navigation and chart initialization.
 */

let appMode = localStorage.getItem('drishti_app_mode') || 'simple';
let voiceGuideActive = false;
let currentTab = 'tab-screening';
let probChart = null;

function setAppMode(mode) {
    appMode = mode;
    localStorage.setItem('drishti_app_mode', mode);
    const btnSimple = document.getElementById('btnModeSimple');
    const btnExpert = document.getElementById('btnModeExpert');

    if (mode === 'simple') {
        document.body.classList.add('mode-simple');
        if (btnSimple) {
            btnSimple.classList.add('active');
            btnSimple.style.background = '#10b981';
            btnSimple.style.color = '#ffffff';
        }
        if (btnExpert) {
            btnExpert.classList.remove('active');
            btnExpert.style.background = 'transparent';
            btnExpert.style.color = '#94a3b8';
        }
    } else {
        document.body.classList.remove('mode-simple');
        if (btnSimple) {
            btnSimple.classList.remove('active');
            btnSimple.style.background = 'transparent';
            btnSimple.style.color = '#94a3b8';
        }
        if (btnExpert) {
            btnExpert.classList.add('active');
            btnExpert.style.background = '#6366f1';
            btnExpert.style.color = '#ffffff';
        }
    }
}

function toggleSidebar(show) {
    const sidebar = document.getElementById('sidebar');
    const backdrop = document.getElementById('sidebarBackdrop');
    if (sidebar) {
        if (show) sidebar.classList.add('open');
        else sidebar.classList.remove('open');
    }
    if (backdrop) {
        if (show) backdrop.classList.add('active');
        else backdrop.classList.remove('active');
    }
}

function switchTab(tabId) {
    currentTab = tabId;
    document.querySelectorAll('.tab-view').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
    
    const targetTab = document.getElementById(tabId);
    if (targetTab) {
        targetTab.classList.add('active');
    }
    
    const navKey = 'nav-item-' + tabId.replace('tab-', '');
    const navItem = document.getElementById(navKey);
    if (navItem) {
        navItem.classList.add('active');
    }
    
    const d = (typeof I18N_FULL !== 'undefined') ? I18N_FULL[currentLang] : null;
    if (d && d.titles && d.titles[tabId]) {
        document.getElementById('viewTitle').innerText = d.titles[tabId][0];
        document.getElementById('viewSubtitle').innerText = d.titles[tabId][1];
    }
    
    const cb = document.querySelector('.content-body');
    if (cb) cb.scrollTop = 0;
    
    if (tabId === 'tab-queue' && typeof refreshQueueTable === 'function') {
        refreshQueueTable();
    } else if (tabId === 'tab-reports' && typeof refreshReportsTable === 'function') {
        refreshReportsTable();
    }
}

function updateVisualChecklist(q) {
    const elClarity = document.getElementById('chkClarity');
    const elLight = document.getElementById('chkLight');
    const elCenter = document.getElementById('chkCenter');
    if (!elClarity || !elLight || !elCenter) return;

    if (!q) {
        elClarity.innerHTML = `👁️ ${currentLang === 'hi' ? 'स्पष्टता' : 'Clarity'}: <span style="color:#16a34a;">✅ OK</span>`;
        elLight.innerHTML = `💡 ${currentLang === 'hi' ? 'रोशनी' : 'Light'}: <span style="color:#16a34a;">✅ OK</span>`;
        elCenter.innerHTML = `🎯 ${currentLang === 'hi' ? 'केंद्र' : 'Center'}: <span style="color:#16a34a;">✅ OK</span>`;
        return;
    }

    const sharpOk = (q.sharpness || 0) >= 0.20;
    const lightOk = (q.illumination || 0) >= 0.25;
    const centerOk = (q.fov || 0) >= 0.35;

    const passText = (currentLang === 'hi') ? '✅ ठीक' : ((currentLang === 'mr') ? '✅ ठीक' : ((currentLang === 'gu') ? '✅ બરાબર' : ((currentLang === 'ta') ? '✅ சரி' : '✅ Clear')));
    const warnText = (currentLang === 'hi') ? '⚠️ कम' : ((currentLang === 'mr') ? '⚠️ कमी' : ((currentLang === 'gu') ? '⚠️ ઓછું' : ((currentLang === 'ta') ? '⚠️ குறைவு' : '⚠️ Low')));
    const badText = (currentLang === 'hi') ? '❌ अस्पष्ट' : ((currentLang === 'mr') ? '❌ अस्पष्ट' : ((currentLang === 'gu') ? '❌ અસ્પષ્ટ' : ((currentLang === 'ta') ? '❌ மோசம்' : '❌ Blur')));

    const lblClarity = (currentLang === 'hi') ? 'स्पष्टता' : ((currentLang === 'mr') ? 'स्पष्टता' : ((currentLang === 'gu') ? 'સ્પષ્ટતા' : ((currentLang === 'ta') ? 'தெளிவு' : 'Clarity')));
    const lblLight = (currentLang === 'hi') ? 'रोशनी' : ((currentLang === 'mr') ? 'प्रकाश' : ((currentLang === 'gu') ? 'પ્રકાશ' : ((currentLang === 'ta') ? 'வெளிச்சம்' : 'Light')));
    const lblCenter = (currentLang === 'hi') ? 'केंद्र' : ((currentLang === 'mr') ? 'केंद्र' : ((currentLang === 'gu') ? 'કેન્દ્ર' : ((currentLang === 'ta') ? 'மையம்' : 'Center')));

    elClarity.innerHTML = `👁️ ${lblClarity}: <span style="color:${sharpOk ? '#16a34a' : '#ef4444'};">${sharpOk ? passText : badText}</span>`;
    elLight.innerHTML = `💡 ${lblLight}: <span style="color:${lightOk ? '#16a34a' : '#f59e0b'};">${lightOk ? passText : warnText}</span>`;
    elCenter.innerHTML = `🎯 ${lblCenter}: <span style="color:${centerOk ? '#16a34a' : '#f59e0b'};">${centerOk ? passText : warnText}</span>`;
}

function updateRuralTrafficLight(data, lang) {
    const card = document.getElementById('simpleTrafficLightCard');
    const icon = document.getElementById('trafficIcon');
    const title = document.getElementById('trafficStatusTitle');
    const dir = document.getElementById('trafficActionDirective');
    if (!card || !icon || !title || !dir) return;

    if (!data) {
        card.style.background = '#f0fdf4';
        card.style.borderColor = '#16a34a';
        icon.innerText = '🟢';
        if (lang === 'hi') {
            title.innerText = "सुरक्षित / सामान्य (NO DIABETIC RETINOPATHY)";
            title.style.color = "#166534";
            dir.innerText = "रेटिना पूरी तरह सामान्य है। प्राथमिक स्वास्थ्य केंद्र (PHC) पर वार्षिक जांच कराएं।";
            dir.style.color = "#15803d";
        } else {
            title.innerText = "NORMAL / LOW RISK (NO DIABETIC RETINOPATHY)";
            title.style.color = "#166534";
            dir.innerText = "Retina is healthy. Recommend routine annual eye screening at local PHC.";
            dir.style.color = "#15803d";
        }
        return;
    }

    const q = data.quality;
    if (q && q.status === 'UNGRADABLE') {
        card.style.background = '#fffbeb';
        card.style.borderColor = '#f59e0b';
        icon.innerText = '⚠️';
        if (lang === 'hi') {
            title.innerText = "अमान्य फोटो (सुरक्षा गेट)";
            title.style.color = "#92400e";
            dir.innerText = "फोटो की गुणवत्ता पर्याप्त नहीं है। कृपया कैमरा स्थिर रखें और लेंस साफ करके दोबारा साफ फोटो लें।";
            dir.style.color = "#b45309";
        } else if (lang === 'mr') {
            title.innerText = "अस्पष्ट फोटो (सुरक्षा गेट)";
            title.style.color = "#92400e";
            dir.innerText = "फोटोची गुणवत्ता अपुरी आहे. कृपया डोळा स्थिर ठेवा आणि पुन्हा स्पष्ट फोटो काढा.";
            dir.style.color = "#b45309";
        } else if (lang === 'gu') {
            title.innerText = "અસ્પષ્ટ ફોટો (સુરક્ષા ગેટ)";
            title.style.color = "#92400e";
            dir.innerText = "ફોટો સ્પષ્ટ નથી. કૃપા કરીને આંખ સ્થિર રાખીને ફરીથી સ્પષ્ટ ફોટો લો.";
            dir.style.color = "#b45309";
        } else if (lang === 'ta') {
            title.innerText = "தெளிவற்ற படம் (நிராகரிப்பு)";
            title.style.color = "#92400e";
            dir.innerText = "படத்தின் தரம் போதுமானதாக இல்லை. மீண்டும் தெளிவான புகைப்படம் எடுக்கவும்.";
            dir.style.color = "#b45309";
        } else {
            title.innerText = "UNGRADABLE PHOTO (SAFETY GATE)";
            title.style.color = "#92400e";
            dir.innerText = "Image quality inadequate for reliable AI analysis. Please stabilize eye and recapture.";
            dir.style.color = "#b45309";
        }
        return;
    }

    const c = data.classification;
    const lvl = c ? c.level : (data.pred_level || 0);

    if (lvl === 0) {
        // Green
        card.style.background = '#f0fdf4';
        card.style.borderColor = '#22c55e';
        icon.innerText = '🟢';
        if (lang === 'hi') {
            title.innerText = "सुरक्षित / सामान्य (NO DIABETIC RETINOPATHY)";
            title.style.color = "#166534";
            dir.innerText = "रेटिना पूरी तरह सामान्य है। प्राथमिक स्वास्थ्य केंद्र (PHC) पर वार्षिक जांच कराएं।";
            dir.style.color = "#15803d";
        } else if (lang === 'mr') {
            title.innerText = "सुरक्षित / सामान्य (कोणतीही हानी नाही)";
            title.style.color = "#166534";
            dir.innerText = "रेटिना सामान्य आहे. प्राथमिक आरोग्य केंद्रात वार्षिक डोळ्यांची तपासणी करा.";
            dir.style.color = "#15803d";
        } else if (lang === 'gu') {
            title.innerText = "સામાન્ય / સુરક્ષિત (કોઈ નુકસાન નથી)";
            title.style.color = "#166534";
            dir.innerText = "રેટિના સામાન્ય છે. દર વર્ષે પ્રાથમિક આરોગ્ય કેન્દ્ર (PHC) પર આંખની તપાસ કરાવો.";
            dir.style.color = "#15803d";
        } else if (lang === 'ta') {
            title.innerText = "பாதுகாப்பானது / இயல்பானது";
            title.style.color = "#166534";
            dir.innerText = "விழித்திரை இயல்பாக உள்ளது. ஆரம்ப சுகாதார நிலையத்தில் வருடாந்திர பரிசோதனை செய்யவும்.";
            dir.style.color = "#15803d";
        } else {
            title.innerText = "NORMAL / LOW RISK (NO DIABETIC RETINOPATHY)";
            title.style.color = "#166534";
            dir.innerText = "Retina is clear. Recommend routine annual eye screening at local PHC.";
            dir.style.color = "#15803d";
        }
    } else if (lvl === 1) {
        // Yellow
        card.style.background = '#fefce8';
        card.style.borderColor = '#eab308';
        icon.innerText = '🟡';
        if (lang === 'hi') {
            title.innerText = "सावधानी / प्रारंभिक लक्षण (MILD NPDR)";
            title.style.color = "#854d0e";
            dir.innerText = "प्रारंभिक लक्षण दिखे हैं। शुगर और बीपी नियंत्रित रखें और 6-12 महीने में दोबारा जांच कराएं।";
            dir.style.color = "#a16207";
        } else if (lang === 'mr') {
            title.innerText = "काळजी घ्या / सौम्य लक्षणे (MILD NPDR)";
            title.style.color = "#854d0e";
            dir.innerText = "किरकोळ लक्षणे आढळली आहेत. साखर नियंत्रणात ठेवा आणि ६ ते १२ महिन्यांत पुन्हा तपासणी करा.";
            dir.style.color = "#a16207";
        } else if (lang === 'gu') {
            title.innerText = "સાવચેતી / શરૂઆતી લક્ષણ (MILD NPDR)";
            title.style.color = "#854d0e";
            dir.innerText = "શરૂઆતી લક્ષણો જોવા મળ્યા છે. શુગર નિયંત્રણમાં રાખો અને ૬-૧૨ મહિનામાં ફરી તપાસ કરાવો.";
            dir.style.color = "#a16207";
        } else if (lang === 'ta') {
            title.innerText = "எச்சரிக்கை / லேசான பாதிப்பு (MILD NPDR)";
            title.style.color = "#854d0e";
            dir.innerText = "லேசான அறிகுறிகள். சர்க்கரையை கட்டுக்குள் வைத்து 6-12 மாதங்களில் மீண்டும் பரிசோதிக்கவும்.";
            dir.style.color = "#a16207";
        } else {
            title.innerText = "CAUTION / EARLY SIGNS (MILD NPDR)";
            title.style.color = "#854d0e";
            dir.innerText = "Early microaneurysms detected. Maintain strict glycemic control and repeat screening in 6-12 months.";
            dir.style.color = "#a16207";
        }
    } else {
        // Red
        card.style.background = '#fef2f2';
        card.style.borderColor = '#ef4444';
        icon.innerText = '🔴';
        const lvlStr = "LEVEL " + lvl;
        if (lang === 'hi') {
            title.innerText = `डॉक्टर परामर्श आवश्यक (${lvlStr} REFERABLE)`;
            title.style.color = "#991b1b";
            dir.innerText = "गंभीर लक्षण पाए गए हैं! कृपया तुरंत जिला अस्पताल के नेत्र विशेषज्ञ से संपर्क करें।";
            dir.style.color = "#b91c1c";
        } else if (lang === 'mr') {
            title.innerText = `डॉक्टरांचा सल्ला आवश्यक (${lvlStr} REFERABLE)`;
            title.style.color = "#991b1b";
            dir.innerText = "गंभीर लक्षणे आढळली आहेत! कृपया त्वरित जिल्हा रुग्णालयातील नेत्रतज्ज्ञांशी संपर्क साधा.";
            dir.style.color = "#b91c1c";
        } else if (lang === 'gu') {
            title.innerText = `ડૉક્ટરની સલાહ જરૂરી (${lvlStr} REFERABLE)`;
            title.style.color = "#991b1b";
            dir.innerText = "ગંભીર લક્ષણો જોવા મળ્યા છે! કૃપા કરીને તાત્કાલિક જિલ્લા હોસ્પિટલના આંખના ડૉક્ટરનો સંપર્ક કરો.";
            dir.style.color = "#b91c1c";
        } else if (lang === 'ta') {
            title.innerText = `மருத்துவர் ஆலோசனை அவசியம் (${lvlStr})`;
            title.style.color = "#991b1b";
            dir.innerText = "தீவிர பாதிப்பு கண்டறியப்பட்டுள்ளது! உடனடியாக மாவட்ட மருத்துவமனை கண் மருத்துவரை அணுகவும்.";
            dir.style.color = "#b91c1c";
        } else {
            title.innerText = `SPECIALIST REFERRAL REQUIRED (${lvlStr} REFERABLE)`;
            title.style.color = "#991b1b";
            dir.innerText = "Referable diabetic retinopathy detected. Prompt evaluation by an ophthalmologist is required.";
            dir.style.color = "#b91c1c";
        }
    }
}

function speakGuidance(text, lang) {
    if (!('speechSynthesis' in window)) {
        alert("Speech synthesis is not supported on this browser.");
        return;
    }
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    const langMap = { hi: 'hi-IN', mr: 'mr-IN', gu: 'gu-IN', ta: 'ta-IN', en: 'en-IN' };
    utterance.lang = langMap[lang] || 'en-US';
    utterance.rate = 0.95;
    window.speechSynthesis.speak(utterance);
}

function toggleVoiceGuide() {
    voiceGuideActive = !voiceGuideActive;
    const btn = document.getElementById('voiceGuideBtn');
    if (btn) {
        if (voiceGuideActive) {
            btn.style.background = '#0284c7';
            btn.style.color = '#ffffff';
        } else {
            btn.style.background = 'transparent';
            btn.style.color = '#cbd5e1';
            window.speechSynthesis.cancel();
        }
    }
}

function speakPatientAdvice() {
    const patName = document.getElementById('patName').value || (currentLang === 'hi' ? "मरीज" : "Patient");
    const dir = document.getElementById('trafficActionDirective');
    const adviceText = dir ? dir.innerText : (currentLang === 'hi' ? "कृपया डॉक्टर से सलाह लें।" : "Please consult doctor.");

    const speech = `${patName}, ${adviceText}`;
    speakGuidance(speech, currentLang);
}

function openReferralSlipModal() {
    const modal = document.getElementById('referralSlipModal');
    if (!modal) return;

    const patName = document.getElementById('patName').value || "Rajesh Patel";
    const patId = document.getElementById('patId').value || "PT-2026-4401";
    const patAge = document.getElementById('patAge').value || "56";
    const patEye = document.getElementById('patEye').value || "OD";

    document.getElementById('slipName').innerText = patName;
    document.getElementById('slipId').innerText = patId;
    document.getElementById('slipAge').innerText = patAge + (currentLang === 'hi' ? " वर्ष / M" : " Yrs / M");
    document.getElementById('slipEye').innerText = patEye === 'OD' ? (currentLang === 'hi' ? "दाहिनी आंख (OD Right)" : "Right Eye (OD)") : (currentLang === 'hi' ? "बाईं आंख (OS Left)" : "Left Eye (OS)");
    document.getElementById('slipDate').innerText = new Date().toLocaleDateString('en-IN', { day:'2-digit', month:'2-digit', year:'numeric' }) + " | " + new Date().toLocaleTimeString('en-IN', { hour:'2-digit', minute:'2-digit' });

    if (window.currentCase) {
        if (window.currentCase.originalImgB64) {
            document.getElementById('slipFundusImg').src = window.currentCase.originalImgB64;
        }
        const sid = window.currentCase.screeningId || window.currentCase.screening_id || patId;
        document.getElementById('slipAuditCode').innerText = "DRISHTI-" + sid.slice(0, 16);

        const tTitle = document.getElementById('trafficStatusTitle');
        const tDir = document.getElementById('trafficActionDirective');
        const banner = document.getElementById('slipUrgencyBanner');
        const bannerTitle = document.getElementById('slipUrgencyTitle');
        const bannerTimeline = document.getElementById('slipUrgencyTimeline');

        if (tTitle && bannerTitle) bannerTitle.innerText = tTitle.innerText;
        if (tDir && bannerTimeline) bannerTimeline.innerText = tDir.innerText;

        const c = window.currentCase.classification;
        const lvl = c ? c.level : (window.currentCase.pred_level || 0);
        if (lvl === 0) {
            banner.style.background = '#f0fdf4';
            banner.style.borderColor = '#22c55e';
            banner.style.color = '#166534';
        } else if (lvl === 1) {
            banner.style.background = '#fefce8';
            banner.style.borderColor = '#eab308';
            banner.style.color = '#854d0e';
        } else {
            banner.style.background = '#fef2f2';
            banner.style.borderColor = '#ef4444';
            banner.style.color = '#991b1b';
        }

        const note = document.getElementById('drDescription');
        const notePrefix = (currentLang === 'hi') ? "<b>नैदानिक विवरण:</b> " : "<b>Clinical Note:</b> ";
        if (note) document.getElementById('slipDoctorNote').innerHTML = notePrefix + note.innerText;
    }

    drawSlipQrCode();
    modal.classList.add('active');
}

function closeReferralSlipModal() {
    const modal = document.getElementById('referralSlipModal');
    if (modal) modal.classList.remove('active');
}

function printReferralSlip() {
    window.print();
}

function drawSlipQrCode() {
    const canvas = document.getElementById('slipQrCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, 56, 56);
    ctx.fillStyle = '#0f172a';

    const s = 4;
    for (let r = 0; r < 14; r++) {
        for (let c = 0; c < 14; c++) {
            if ((r < 4 && c < 4) || (r < 4 && c > 9) || (r > 9 && c < 4)) {
                ctx.fillRect(c * s, r * s, s - 1, s - 1);
            } else if ((r + c * 3) % 2 === 0) {
                ctx.fillRect(c * s, r * s, s - 1, s - 1);
            }
        }
    }
}

function initChart() {
    const ctx = document.getElementById('probBarChart');
    if (!ctx) return;
    probChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['L0 (No DR)', 'L1 (Mild)', 'L2 (Moderate)', 'L3 (Severe)', 'L4 (PDR)'],
            datasets: [{
                label: 'Class Probability (%)',
                data: [0, 0, 0, 0, 0],
                backgroundColor: ['#64748b', '#eab308', '#f97316', '#ef4444', '#b91c1c'],
                borderRadius: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: { beginAtZero: true, max: 100, ticks: { font: { size: 9 } } },
                x: { ticks: { font: { size: 9 } } }
            },
            plugins: {
                legend: { display: false }
            }
        }
    });
}
