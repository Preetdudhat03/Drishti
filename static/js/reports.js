/**
 * DRISHTI Clinical Reports & API Inspector (reports.js)
 * Manages: Printable 3-part clinical reports fetched from Supabase, and JSON API payloads.
 */

function refreshReportsTable() {
    fetch('/api/reports')
        .then(r => r.json())
        .then(reports => {
            const tbody = document.getElementById('reportsTableBody');
            if (!tbody) return;
            tbody.innerHTML = '';
            if (!reports || reports.length === 0) {
                const emptyMsg = (currentLang === 'hi') ? 'सुपाबेस डेटाबेस में कोई रिपोर्ट नहीं मिली।' : 'No reports found in Supabase database. Run a screening to generate reports.';
                tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: var(--text-muted);">${emptyMsg}</td></tr>`;
                return;
            }
            reports.forEach(r => {
                const tr = document.createElement('tr');
                const isVal = r.status === 'CLINICIAN_VALIDATED' || r.status === 'COMPLETED';
                const isRec = r.status === 'RECAPTURE_REQUIRED' || r.status === 'UNGRADABLE';
                const statusClass = isVal ? 'badge-good' : (isRec ? 'badge-ungradable' : 'badge-borderline');
                const viewText = (currentLang === 'hi') ? '📄 रिपोर्ट देखें' : '📄 View Report';
                const refLabel = (currentLang === 'hi') ? 'रेफरेबल' : 'Referable';
                const nonRefLabel = (currentLang === 'hi') ? 'गैर-रेफरेबल' : 'Non-Referable';
                const lvlLabel = (currentLang === 'hi') ? 'स्तर ' : 'Level ';

                tr.innerHTML = `
                    <td><b>${r.report_id}</b></td>
                    <td>${r.patient_id} (${r.patient_name || 'Patient'})</td>
                    <td>${r.created_at || '--'}</td>
                    <td><b>${r.dr_level >= 0 ? lvlLabel + r.dr_level : 'Ungradable'}</b> ${r.dr_level >= 2 ? `<span class="badge badge-ref-yes">${refLabel}</span>` : (r.dr_level >= 0 ? `<span class="badge badge-ref-no">${nonRefLabel}</span>` : '')}</td>
                    <td><span class="badge ${statusClass}">${r.status}</span></td>
                    <td><button class="btn btn-outline btn-sm" onclick="window.open('/api/reports/' + encodeURIComponent('${r.screening_id}'), '_blank')">${viewText}</button></td>
                `;
                tbody.appendChild(tr);
            });
        })
        .catch(err => {
            console.error('Reports load error:', err);
        });
}

function exportReport() {
    if (!window.currentCase) return alert("Please run or load a screening case first.");
    const sid = window.currentCase.screeningId || window.currentCase.screening_id;
    window.open('/api/reports/' + encodeURIComponent(sid), '_blank');
}

function logApiInspector(data) {
    const inspector = document.getElementById('apiJsonInspector');
    if (!inspector) return;
    const payload = {
        timestamp: new Date().toISOString(),
        supabase_cloud_sync: {
            database: "Supabase PostgreSQL 15.1",
            tables_updated: ["screenings", "quality_assessments", "ai_predictions", "explainability_results"]
        },
        screening_id: data.screeningId || data.screening_id,
        quality_gate: data.quality,
        classification: data.classification,
        model_provenance: {
            architecture: "ResNet-18",
            weights: "EyeXpert_ResNet18_best.pth",
            xai: "layer4[1].conv2 Grad-CAM"
        }
    };
    inspector.innerText = JSON.stringify(payload, null, 2);
}
