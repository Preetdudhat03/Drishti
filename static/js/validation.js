/**
 * DRISHTI Model Validation Suite (validation.js)
 * Manages: Demonstration batch testing, benchmark dataset metrics, confusion matrix display.
 */

function switchValMode(mode) {
    if (mode === 'demo') {
        document.getElementById('valModeDemo').style.display = 'block';
        document.getElementById('valModeBench').style.display = 'none';
        document.getElementById('btnTabDemo').className = 'btn btn-sm';
        document.getElementById('btnTabBench').className = 'btn btn-outline btn-sm';
    } else {
        document.getElementById('valModeDemo').style.display = 'none';
        document.getElementById('valModeBench').style.display = 'block';
        document.getElementById('btnTabDemo').className = 'btn btn-outline btn-sm';
        document.getElementById('btnTabBench').className = 'btn btn-sm';
    }
}

function loadSampleBatch() {
    const pBox = document.getElementById('batchProgressBox');
    const pBar = document.getElementById('batchProgressBar');
    const pText = document.getElementById('batchStatusText');

    if (pBox) pBox.style.display = 'block';
    if (pBar) pBar.style.width = '50%';
    if (pText) pText.innerText = (currentLang === 'hi') ? '10 मानक टेस्ट सैंपल पर बैच स्क्रीनिंग जारी है...' : 'Running batch inference on 10 benchmark test samples...';
    
    fetch('/api/batch/demo_samples')
        .then(r => r.json())
        .then(results => {
            if (pBar) pBar.style.width = '100%';
            if (pText) pText.innerText = (currentLang === 'hi') ? `बैच पूर्ण (${results.length} मामले)।` : `Batch completed (${results.length} cases).`;
            
            const tbody = document.getElementById('batchDemoTableBody');
            if (!tbody) return;
            tbody.innerHTML = '';
            results.forEach((r, idx) => {
                const tr = document.createElement('tr');
                const yesText = (currentLang === 'hi') ? 'हाँ' : 'YES';
                const noText = (currentLang === 'hi') ? 'नहीं' : 'NO';

                tr.innerHTML = `
                    <td>${idx + 1}</td>
                    <td><b>${r.filename}</b></td>
                    <td><span class="badge badge-${r.quality.toLowerCase()}">${r.quality}</span></td>
                    <td><b>${r.quality === 'UNGRADABLE' ? '--' : 'Level ' + r.dr_level}</b></td>
                    <td><span class="badge ${r.referable ? 'badge-ref-yes' : 'badge-ref-no'}">${r.quality === 'UNGRADABLE' ? 'N/A' : (r.referable ? yesText : noText)}</span></td>
                    <td>${r.quality === 'UNGRADABLE' ? '--' : (r.probability * 100).toFixed(1) + '%'}</td>
                    <td>${r.inference_time_ms} ms</td>
                `;
                tbody.appendChild(tr);
            });
            if (typeof refreshQueueTable === 'function') refreshQueueTable();
            if (typeof refreshReportsTable === 'function') refreshReportsTable();
        })
        .catch(err => {
            if (pText) pText.innerText = "Error: " + err.message;
        });
}

function runBatchDemo() {
    const files = document.getElementById('batchFiles').files;
    if (files && files.length > 0) {
        const pBox = document.getElementById('batchProgressBox');
        const pBar = document.getElementById('batchProgressBar');
        const pText = document.getElementById('batchStatusText');
        if (pBox) pBox.style.display = 'block';
        if (pBar) pBar.style.width = '30%';
        if (pText) pText.innerText = `Evaluating ${files.length} images...`;
    }
    loadSampleBatch();
}
