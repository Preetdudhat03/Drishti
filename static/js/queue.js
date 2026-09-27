/**
 * DRISHTI Clinician Review Queue & Human-in-the-Loop Actions (queue.js)
 * Interacts with Supabase PostgreSQL cloud tables: screenings, clinician_reviews, audit_events.
 */

function clinicianValidate() {
    if (!window.currentCase) return;
    const sid = window.currentCase.screeningId || window.currentCase.screening_id;
    const notes = document.getElementById('clinicianRationale').value || 'Validated. Findings consistent with AI grade.';
    const finalLvl = window.currentCase.classification ? window.currentCase.classification.level : 0;

    fetch('/api/screenings/' + encodeURIComponent(sid) + '/review', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            action: 'VALIDATE_AI',
            final_dr_level: finalLvl,
            clinical_notes: notes,
            clinician_name: 'Dr. Rajesh Kumar, MD (Ophthalmology)'
        })
    })
    .then(r => r.json())
    .then(res => {
        const dVal = (typeof I18N_FULL !== 'undefined') ? I18N_FULL[currentLang] : null;
        document.getElementById('caseStatusBadge').innerText = "CLINICIAN VALIDATED";
        document.getElementById('caseStatusBadge').style.background = "#dcfce7";
        document.getElementById('caseStatusBadge').style.color = "#166534";
        document.getElementById('provReviewStatus').innerText = "VALIDATED BY CLINICIAN (SYNCED TO SUPABASE)";
        alert("AI screening result officially confirmed, validated, and synced to Supabase Cloud.");
        refreshQueueTable();
        if (typeof refreshReportsTable === 'function') refreshReportsTable();
    })
    .catch(err => alert("Sync error: " + err.message));
}

function clinicianOverride() {
    if (!window.currentCase) return;
    const sid = window.currentCase.screeningId || window.currentCase.screening_id;
    const lvl = parseInt(document.getElementById('overrideLvl').value);
    const notes = document.getElementById('clinicianRationale').value || ('Overridden to Level ' + lvl + ' by specialist.');

    fetch('/api/screenings/' + encodeURIComponent(sid) + '/review', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            action: 'OVERRIDE_GRADE',
            final_dr_level: lvl,
            clinical_notes: notes,
            clinician_name: 'Dr. Rajesh Kumar, MD (Ophthalmology)'
        })
    })
    .then(r => r.json())
    .then(res => {
        document.getElementById('caseStatusBadge').innerText = "OVERRIDDEN (L" + lvl + ")";
        document.getElementById('caseStatusBadge').style.background = "#ffedd5";
        document.getElementById('caseStatusBadge').style.color = "#c2410c";
        document.getElementById('provReviewStatus').innerText = "OVERRIDDEN TO LEVEL " + lvl + " (SYNCED TO SUPABASE)";
        alert("Result overridden to Level " + lvl + ". Decision and rationale saved to Supabase.");
        refreshQueueTable();
        if (typeof refreshReportsTable === 'function') refreshReportsTable();
    })
    .catch(err => alert("Sync error: " + err.message));
}

function clinicianReject() {
    if (!window.currentCase) return;
    const sid = window.currentCase.screeningId || window.currentCase.screening_id;
    const notes = document.getElementById('clinicianRationale').value || 'Image quality inadequate. Recapture requested by ophthalmologist.';

    fetch('/api/screenings/' + encodeURIComponent(sid) + '/review', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            action: 'REJECT_RECAPTURE',
            final_dr_level: null,
            clinical_notes: notes,
            clinician_name: 'Dr. Rajesh Kumar, MD (Ophthalmology)'
        })
    })
    .then(r => r.json())
    .then(res => {
        document.getElementById('caseStatusBadge').innerText = "RECAPTURE REQUIRED";
        document.getElementById('caseStatusBadge').style.background = "#fee2e2";
        document.getElementById('caseStatusBadge').style.color = "#991b1b";
        alert("Image rejected by specialist. Recapture event logged to Supabase.");
        refreshQueueTable();
        if (typeof refreshReportsTable === 'function') refreshReportsTable();
    })
    .catch(err => alert("Sync error: " + err.message));
}

function submitToQueue() {
    if (!window.currentCase) return;
    const sid = window.currentCase.screeningId || window.currentCase.screening_id;
    fetch('/api/screenings/' + encodeURIComponent(sid) + '/submit_queue', { method: 'POST' })
        .then(r => r.json())
        .then(res => {
            alert("Case " + sid + " successfully submitted and synced to the Supabase Review Queue.");
            refreshQueueTable();
        });
}

function refreshQueueTable() {
    fetch('/api/queue')
        .then(r => r.json())
        .then(cases => {
            const tbody = document.getElementById('queueTableBody');
            if (!tbody) return;
            tbody.innerHTML = '';
            if (!cases || cases.length === 0) {
                const emptyMsg = (currentLang === 'hi') ? 'सुपाबेस डेटाबेस में कोई मामला नहीं मिला।' : 'No cases found in Supabase database. Run a screening to create one.';
                tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; color: var(--text-muted);">${emptyMsg}</td></tr>`;
                return;
            }
            cases.forEach(c => {
                const tr = document.createElement('tr');
                const isVal = c.status === 'CLINICIAN_VALIDATED' || c.status === 'COMPLETED';
                const isRec = c.status === 'RECAPTURE_REQUIRED' || c.status === 'UNGRADABLE';
                const statusClass = isVal ? 'badge-good' : (isRec ? 'badge-ungradable' : 'badge-borderline');
                const inspectText = (currentLang === 'hi') ? 'जांचें (Inspect)' : 'Inspect';
                const yesText = (currentLang === 'hi') ? 'हाँ' : 'YES';
                const noText = (currentLang === 'hi') ? 'नहीं' : 'NO';

                tr.innerHTML = `
                    <td><b>${c.screening_id}</b></td>
                    <td>${c.patient_id} (${c.patient_name || 'Patient'})</td>
                    <td>${c.eye || 'OD'}</td>
                    <td><b>${c.dr_level >= 0 ? 'L' + c.dr_level : '--'}</b></td>
                    <td><span class="badge ${c.is_referable ? 'badge-ref-yes' : 'badge-ref-no'}">${c.dr_level >= 0 ? (c.is_referable ? yesText : noText) : 'N/A'}</span></td>
                    <td><span class="badge badge-${(c.quality_status || 'GOOD').toLowerCase()}">${c.quality_status || 'GOOD'}</span></td>
                    <td><span class="badge ${statusClass}">${c.status}</span></td>
                    <td>${c.created_at || '--'}</td>
                    <td><button class="btn btn-outline btn-sm" onclick="loadCaseFromQueue('${c.screening_id}')">${inspectText}</button></td>
                `;
                tbody.appendChild(tr);
            });
        })
        .catch(err => {
            console.error('Queue load error:', err);
        });
}

function loadCaseFromQueue(id) {
    if (typeof showLoading === 'function') showLoading(true);
    fetch('/api/screenings/' + encodeURIComponent(id))
        .then(r => r.json())
        .then(data => {
            if (typeof showLoading === 'function') showLoading(false);
            if (typeof switchTab === 'function') switchTab('tab-screening');
            if (typeof updateScreeningUI === 'function') updateScreeningUI(data);
        })
        .catch(err => {
            if (typeof showLoading === 'function') showLoading(false);
            alert("Error loading case from Supabase: " + err.message);
        });
}
