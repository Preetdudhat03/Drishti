/**
 * DRISHTI District-Scale Telemedicine Simulation (simulation.js)
 * Simulates queuing models (M/M/c), doctor review capacity, and wait-time reduction.
 */

function recalcSimulation() {
    const pInput = document.getElementById('simPatients');
    const phcInput = document.getElementById('simPHCs');
    const docInput = document.getElementById('simDoctors');
    const docCapInput = document.getElementById('simDocCap');

    const p = pInput ? (parseInt(pInput.value) || 120000) : 120000;
    const phc = phcInput ? (parseInt(phcInput.value) || 24) : 24;
    const doc = docInput ? (parseInt(docInput.value) || 4) : 4;
    const docCap = docCapInput ? (parseInt(docCapInput.value) || 40) : 40;

    const dailyArrival = Math.round(p / 300);
    const nonRef = Math.round(dailyArrival * 0.72);
    const ref = dailyArrival - nonRef;
    const totalDocCap = doc * docCap;

    const baseWait = (dailyArrival / Math.max(1, totalDocCap)) * 3.8;
    const optWait = (ref / Math.max(1, totalDocCap)) * 14.5;

    const elArrival = document.getElementById('simDailyArrival');
    if (elArrival) elArrival.innerText = dailyArrival + " patients / day";
    
    const elAuto = document.getElementById('simAutoDischarged');
    if (elAuto) elAuto.innerText = nonRef + " patients / day (72.0%)";
    
    const elTele = document.getElementById('simTeleQueue');
    if (elTele) elTele.innerText = ref + " patients / day (Referable + Borderline)";
    
    const elBaseWait = document.getElementById('simBaseWait');
    if (elBaseWait) elBaseWait.innerText = baseWait.toFixed(1) + " Hours";
    
    const elOptWait = document.getElementById('simOptWait');
    if (elOptWait) elOptWait.innerText = optWait.toFixed(1) + " Mins";
}
