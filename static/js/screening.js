/**
 * DRISHTI Retinal Screening Workflow (screening.js)
 * Manages: Image upload, sample benchmark loading, camera snapshot acquisition,
 * image switching (Original, CLAHE, Heatmap, Overlay), and real-time UI updates.
 */

window.currentCase = null;
let cameraStream = null;

function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    const dz = document.getElementById('dropZone');
    if (dz) dz.classList.add('drop-active');
}

function handleDragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    const dz = document.getElementById('dropZone');
    if (dz) dz.classList.remove('drop-active');
}

function handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    const dz = document.getElementById('dropZone');
    if (dz) dz.classList.remove('drop-active');
    if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) {
        processUploadedFile(e.dataTransfer.files[0]);
    }
}

function handleFileUpload(e) {
    const file = e.target.files[0];
    if (file) processUploadedFile(file);
}

function showLoading(active) {
    const el = document.getElementById('loadingOverlay');
    if (el) el.style.display = active ? 'flex' : 'none';
}

function processUploadedFile(file) {
    showLoading(true);
    const formData = new FormData();
    formData.append('file', file);
    formData.append('patient_id', document.getElementById('patId').value || 'PT-2026-4401');
    formData.append('patient_name', document.getElementById('patName').value || 'Rajesh Patel');
    formData.append('age', document.getElementById('patAge').value || '56');
    formData.append('eye', document.getElementById('patEye').value || 'OD');
    formData.append('diabetes_duration', document.getElementById('patDuration').value || '8');
    formData.append('hba1c', document.getElementById('patHba1c').value || '7.8');

    fetch('/api/screenings/upload', { method: 'POST', body: formData })
        .then(async r => {
            if (!r.ok) {
                const text = await r.text();
                throw new Error("HTTP " + r.status + ": " + text.slice(0, 150));
            }
            return r.json();
        })
        .then(data => {
            showLoading(false);
            updateScreeningUI(data);
            if (typeof refreshQueueTable === 'function') refreshQueueTable();
            if (typeof refreshReportsTable === 'function') refreshReportsTable();
        })
        .catch(err => {
            showLoading(false);
            alert("Inference Notice: " + err.message);
        });
}

function setMainView(view) {
    ['orig', 'enh', 'cam', 'overlay'].forEach(v => {
        const btn = document.getElementById('viewBtn' + v.charAt(0).toUpperCase() + v.slice(1));
        if (btn) btn.className = (v === view) ? 'btn btn-sm' : 'btn btn-outline btn-sm';
    });
    if (!window.currentCase) return;
    const img = document.getElementById('origImg');
    if (view === 'orig') img.src = window.currentCase.originalImgB64 || '';
    else if (view === 'enh') img.src = window.currentCase.enhancedImgB64 || window.currentCase.originalImgB64 || '';
    else if (view === 'cam') img.src = window.currentCase.camImgB64 || '';
    else if (view === 'overlay') img.src = window.currentCase.overlayImgB64 || '';
}

function addFinding(text) {
    const input = document.getElementById('clinicianRationale');
    if (!input.value || input.value === 'Verified. Findings consistent with clinical grade.') {
        input.value = text;
    } else {
        input.value += '; ' + text;
    }
}

function loadBenchmarkSample() {
    const s = document.getElementById('sampleSelect').value;
    if (!s) return;
    showLoading(true);
    fetch('/api/screenings/sample_run?sample=' + encodeURIComponent(s))
        .then(async r => {
            if (!r.ok) {
                const text = await r.text();
                throw new Error("HTTP " + r.status + ": " + text.slice(0, 150));
            }
            return r.json();
        })
        .then(data => {
            showLoading(false);
            updateScreeningUI(data);
            if (typeof refreshQueueTable === 'function') refreshQueueTable();
            if (typeof refreshReportsTable === 'function') refreshReportsTable();
        })
        .catch(err => {
            showLoading(false);
            alert("Error loading sample: " + err.message);
        });
}

function updateScreeningUI(data) {
    window.currentCase = data;
    logApiInspector(data);

    // Reset to Original preview
    setMainView('orig');

    // 1. Original Retinal Image
    if (data.originalImgB64) {
        document.getElementById('origImg').src = data.originalImgB64;
        document.getElementById('origImg').style.display = 'block';
        document.getElementById('origPlaceholder').style.display = 'none';
    }

    // 2. Optical Quality Gate Assessment
    const q = data.quality;
    if (q) {
        const qb = document.getElementById('qualityBadge');
        qb.innerText = "QUALITY: " + q.status;
        qb.className = "badge badge-" + q.status.toLowerCase();
        document.getElementById('qualityScoreText').innerText = "Score: " + (q.overallScore || 0).toFixed(2) + " / 1.00";
        document.getElementById('metricSharp').innerText = (q.sharpness || 0).toFixed(2);
        document.getElementById('metricIllum').innerText = (q.illumination || 0).toFixed(2);
        document.getElementById('metricFOV').innerText = (q.fov || 0).toFixed(2);
        document.getElementById('recaptureGuidance').innerText = (q.recaptureFeedback || []).join(' ');
        if (typeof updateVisualChecklist === 'function') updateVisualChecklist(q);
    }

    if (data.enhancedImgB64) {
        document.getElementById('enhancedImg').src = data.enhancedImgB64;
        document.getElementById('enhancedImg').style.display = 'block';
        document.getElementById('enhPlaceholder').style.display = 'none';
    }

    // 3. Safety Gate: Ungradable blocks AI
    if (q && q.status === 'UNGRADABLE') {
        document.getElementById('drLevelBadge').innerText = "DR LEVEL: BLOCKED (UNGRADABLE)";
        document.getElementById('drLevelBadge').style.background = "#fee2e2";
        document.getElementById('referableBadge').innerText = "UNGRADABLE";
        document.getElementById('referableBadge').className = "badge badge-ungradable";
        document.getElementById('drDescription').innerText = "Automated DR grading blocked by Quality Safety Gate.";
        document.getElementById('probText').innerText = "Inference halted to protect patient safety.";
        document.getElementById('recActionText').innerText = "Image quality inadequate. Recapture fundus photo per optical instructions.";
        if (probChart) {
            probChart.data.datasets[0].data = [0, 0, 0, 0, 0];
            probChart.update();
        }
        document.getElementById('camImg').style.display = 'none';
        document.getElementById('overlayImg').style.display = 'none';
        document.getElementById('caseStatusBadge').innerText = "RECAPTURE REQUIRED";
        document.getElementById('caseStatusBadge').style.background = "#fee2e2";
        document.getElementById('caseStatusBadge').style.color = "#991b1b";
        if (typeof updateRuralTrafficLight === 'function') updateRuralTrafficLight(data, currentLang);
        return;
    }

    // 4. AI DR Grade Classification
    const c = data.classification;
    if (c) {
        const colors = ['#71717a', '#eab308', '#f59e0b', '#ea580c', '#e11d48'];
        const drBadge = document.getElementById('drLevelBadge');
        drBadge.innerText = "DR LEVEL: " + c.level;
        drBadge.style.background = colors[c.level] || '#f59e0b';
        drBadge.style.color = '#fff';

        const refBadge = document.getElementById('referableBadge');
        if (c.isReferable) {
            refBadge.innerText = (currentLang === 'en') ? "REFERABLE DR: YES" : "रेफरेबल: हाँ";
            refBadge.className = "badge badge-ref-yes";
        } else {
            refBadge.innerText = (currentLang === 'en') ? "REFERABLE DR: NO" : "रेफरेबल: नहीं";
            refBadge.className = "badge badge-ref-no";
        }

        document.getElementById('drDescription').innerText = c.severityText;
        document.getElementById('probText').innerText = "Model Probability: " + ((c.probability || 0) * 100).toFixed(1) + "%";
        document.getElementById('recActionText').innerHTML = "<b>Action:</b> " + (c.recommendation || '') + "<br><b>Clinical Note:</b> " + (c.findings || '');

        if (c.probabilities && probChart) {
            probChart.data.datasets[0].data = c.probabilities.map(p => p * 100);
            probChart.update();
        }
    }

    // 5. Grad-CAM Explainability Attention
    if (data.camImgB64) {
        document.getElementById('camImg').src = data.camImgB64;
        document.getElementById('camImg').style.display = 'block';
        document.getElementById('camPlaceholder').style.display = 'none';
    }
    if (data.overlayImgB64) {
        document.getElementById('overlayImg').src = data.overlayImgB64;
        document.getElementById('overlayImg').style.display = 'block';
        document.getElementById('overlayPlaceholder').style.display = 'none';
    }

    // 6. Case Status Sync Badge
    const currentStatus = data.status || "PENDING_CLINICIAN_REVIEW";
    const statusBadge = document.getElementById('caseStatusBadge');
    if (currentStatus === 'CLINICIAN_VALIDATED') {
        statusBadge.innerText = "CLINICIAN VALIDATED";
        statusBadge.style.background = "#dcfce7";
        statusBadge.style.color = "#166534";
    } else if (currentStatus === 'RECAPTURE_REQUIRED') {
        statusBadge.innerText = "RECAPTURE REQUIRED";
        statusBadge.style.background = "#fee2e2";
        statusBadge.style.color = "#991b1b";
    } else {
        statusBadge.innerText = "PENDING REVIEW";
        statusBadge.style.background = "#fef3c7";
        statusBadge.style.color = "#92400e";
    }

    // Update traffic light hero card
    if (typeof updateRuralTrafficLight === 'function') {
        updateRuralTrafficLight(data, currentLang);
    }
}

function openCameraModal() {
    const modal = document.getElementById('cameraModal');
    if (modal) modal.style.display = 'flex';
    navigator.mediaDevices.getUserMedia({ video: { width: 640, height: 480 } })
        .then(stream => {
            cameraStream = stream;
            document.getElementById('webcamVideo').srcObject = stream;
        })
        .catch(err => {
            alert("No physical camera detected. You can use benchmark test samples or file upload.");
            closeCameraModal();
        });
}

function closeCameraModal() {
    if (cameraStream) {
        cameraStream.getTracks().forEach(t => t.stop());
    }
    const modal = document.getElementById('cameraModal');
    if (modal) modal.style.display = 'none';
}

function snapCameraFrame() {
    const video = document.getElementById('webcamVideo');
    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    const b64 = canvas.toDataURL('image/png');
    closeCameraModal();

    fetch('/api/screenings/camera_capture', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ image_b64: b64 })
    })
    .then(r => r.json())
    .then(data => {
        updateScreeningUI(data);
        if (typeof refreshQueueTable === 'function') refreshQueueTable();
        if (typeof refreshReportsTable === 'function') refreshReportsTable();
    });
}
