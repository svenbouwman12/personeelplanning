// Demo gebruikers
const users = {
    'admin': { password: 'admin123', role: 'admin', name: 'Admin' },
    'sven': { password: 'sven123', role: 'employee', name: 'Sven' },
    'anna': { password: 'anna123', role: 'employee', name: 'Anna' },
    'tom': { password: 'tom123', role: 'employee', name: 'Tom' }
};

// Tijdsloten voor het rooster
const timeSlots = [
    '09:00-13:00',
    '13:00-17:00',
    '17:00-21:00'
];

// Huidige gebruiker
let currentUser = null;

// Initializeer de applicatie wanneer de pagina laadt
document.addEventListener('DOMContentLoaded', function() {
    // Controleer of er een gebruiker is ingelogd
    const loggedInUser = localStorage.getItem('currentUser');
    if (loggedInUser) {
        currentUser = JSON.parse(loggedInUser);
        updateUserDisplay();
        
        // Redirect naar juiste pagina als niet op login pagina
        if (window.location.pathname.includes('index.html') || window.location.pathname === '/') {
            redirectAfterLogin();
        }
    } else {
        // Als geen gebruiker ingelogd en niet op login pagina, redirect naar login
        if (!window.location.pathname.includes('index.html') && window.location.pathname !== '/') {
            window.location.href = 'index.html';
        }
    }
    
    // Initializeer specifieke functionaliteit per pagina
    if (window.location.pathname.includes('index.html') || window.location.pathname === '/') {
        initLoginPage();
    } else if (window.location.pathname.includes('admin.html')) {
        initAdminPage();
    } else if (window.location.pathname.includes('employee.html')) {
        initEmployeePage();
    }
});

// Login pagina functionaliteit
function initLoginPage() {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }
}

function handleLogin(e) {
    e.preventDefault();
    
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorMessage = document.getElementById('errorMessage');
    
    // Controleer gebruikersgegevens
    if (users[username] && users[username].password === password) {
        currentUser = {
            username: username,
            role: users[username].role,
            name: users[username].name
        };
        
        // Sla gebruiker op in localStorage
        localStorage.setItem('currentUser', JSON.stringify(currentUser));
        
        // Clear error message
        errorMessage.style.display = 'none';
        
        // Redirect naar juiste pagina
        redirectAfterLogin();
    } else {
        errorMessage.textContent = 'Ongeldige gebruikersnaam of wachtwoord';
        errorMessage.style.display = 'block';
    }
}

function redirectAfterLogin() {
    if (currentUser.role === 'admin') {
        window.location.href = 'admin.html';
    } else {
        window.location.href = 'employee.html';
    }
}

// Logout functionaliteit
function handleLogout() {
    localStorage.removeItem('currentUser');
    currentUser = null;
    window.location.href = 'index.html';
}

function updateUserDisplay() {
    const currentUserElement = document.getElementById('currentUser');
    const logoutBtn = document.getElementById('logoutBtn');
    
    if (currentUserElement) {
        currentUserElement.textContent = `Welkom, ${currentUser.name}`;
    }
    
    if (logoutBtn) {
        logoutBtn.addEventListener('click', handleLogout);
    }
}

// Admin pagina functionaliteit
function initAdminPage() {
    const weekSelect = document.getElementById('weekSelect');
    const saveScheduleBtn = document.getElementById('saveSchedule');
    
    // Set huidige week als default
    if (weekSelect) {
        const today = new Date();
        const currentWeek = getWeekString(today);
        weekSelect.value = currentWeek;
        
        weekSelect.addEventListener('change', loadSchedule);
        generateScheduleTable();
        loadSchedule();
    }
    
    if (saveScheduleBtn) {
        saveScheduleBtn.addEventListener('click', saveSchedule);
    }
}

function getWeekString(date) {
    const year = date.getFullYear();
    const week = getWeekNumber(date);
    return `${year}-W${week.toString().padStart(2, '0')}`;
}

function getWeekNumber(date) {
    const firstJan = new Date(date.getFullYear(), 0, 1);
    const pastDaysOfYear = (date - firstJan) / 86400000;
    return Math.ceil((pastDaysOfYear + firstJan.getDay() + 1) / 7);
}

function generateScheduleTable() {
    const scheduleBody = document.getElementById('scheduleBody');
    if (!scheduleBody) return;
    
    scheduleBody.innerHTML = '';
    
    timeSlots.forEach(slot => {
        const row = document.createElement('tr');
        
        // Tijd kolom
        const timeCell = document.createElement('td');
        timeCell.textContent = slot;
        timeCell.className = 'time-cell';
        row.appendChild(timeCell);
        
        // Dagen kolommen (maandag t/m zondag)
        const days = ['maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'];
        days.forEach(day => {
            const cell = document.createElement('td');
            
            const select = document.createElement('select');
            select.className = 'employee-select';
            select.setAttribute('data-day', day);
            select.setAttribute('data-timeslot', slot);
            
            // Voeg opties toe
            const emptyOption = document.createElement('option');
            emptyOption.value = '';
            emptyOption.textContent = 'Niemand';
            select.appendChild(emptyOption);
            
            Object.keys(users).forEach(username => {
                if (users[username].role === 'employee') {
                    const option = document.createElement('option');
                    option.value = username;
                    option.textContent = users[username].name;
                    select.appendChild(option);
                }
            });
            
            cell.appendChild(select);
            row.appendChild(cell);
        });
        
        scheduleBody.appendChild(row);
    });
}

function loadSchedule() {
    const weekSelect = document.getElementById('weekSelect');
    if (!weekSelect) return;
    
    const selectedWeek = weekSelect.value;
    const scheduleData = JSON.parse(localStorage.getItem('schedule') || '{}');
    const weekSchedule = scheduleData[selectedWeek] || {};
    
    // Reset alle selecties
    const selects = document.querySelectorAll('.employee-select');
    selects.forEach(select => {
        select.value = '';
    });
    
    // Laad opgeslagen rooster
    Object.keys(weekSchedule).forEach(key => {
        const [day, timeslot] = key.split('_');
        const select = document.querySelector(`[data-day="${day}"][data-timeslot="${timeslot}"]`);
        if (select) {
            select.value = weekSchedule[key];
        }
    });
}

function saveSchedule() {
    const weekSelect = document.getElementById('weekSelect');
    if (!weekSelect) return;
    
    const selectedWeek = weekSelect.value;
    const scheduleData = JSON.parse(localStorage.getItem('schedule') || '{}');
    
    const weekSchedule = {};
    const selects = document.querySelectorAll('.employee-select');
    
    selects.forEach(select => {
        const day = select.getAttribute('data-day');
        const timeslot = select.getAttribute('data-timeslot');
        const employee = select.value;
        
        if (employee) {
            weekSchedule[`${day}_${timeslot}`] = employee;
        }
    });
    
    scheduleData[selectedWeek] = weekSchedule;
    localStorage.setItem('schedule', JSON.stringify(scheduleData));
    
    // Toon bevestiging
    alert('Rooster opgeslagen!');
}

// Employee pagina functionaliteit
function initEmployeePage() {
    const weekSelect = document.getElementById('weekSelect');
    const clockInBtn = document.getElementById('clockInBtn');
    const clockOutBtn = document.getElementById('clockOutBtn');
    
    // Set huidige week als default
    if (weekSelect) {
        const today = new Date();
        const currentWeek = getWeekString(today);
        weekSelect.value = currentWeek;
        
        weekSelect.addEventListener('change', loadMySchedule);
        loadMySchedule();
    }
    
    if (clockInBtn) {
        clockInBtn.addEventListener('click', handleClockIn);
    }
    
    if (clockOutBtn) {
        clockOutBtn.addEventListener('click', handleClockOut);
    }
    
    // Update clock status
    updateClockStatus();
    loadClockHistory();
}

function loadMySchedule() {
    const weekSelect = document.getElementById('weekSelect');
    const myScheduleBody = document.getElementById('myScheduleBody');
    
    if (!weekSelect || !myScheduleBody) return;
    
    const selectedWeek = weekSelect.value;
    const scheduleData = JSON.parse(localStorage.getItem('schedule') || '{}');
    const weekSchedule = scheduleData[selectedWeek] || {};
    
    myScheduleBody.innerHTML = '';
    
    const days = ['maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'];
    
    days.forEach(day => {
        timeSlots.forEach(slot => {
            const key = `${day}_${slot}`;
            if (weekSchedule[key] === currentUser.username) {
                const row = document.createElement('tr');
                
                const dayCell = document.createElement('td');
                dayCell.textContent = day.charAt(0).toUpperCase() + day.slice(1);
                row.appendChild(dayCell);
                
                const timeCell = document.createElement('td');
                timeCell.textContent = slot;
                row.appendChild(timeCell);
                
                const statusCell = document.createElement('td');
                statusCell.textContent = 'Ingeroosterd';
                statusCell.className = 'status-scheduled';
                row.appendChild(statusCell);
                
                myScheduleBody.appendChild(row);
            }
        });
    });
    
    if (myScheduleBody.children.length === 0) {
        const row = document.createElement('tr');
        const cell = document.createElement('td');
        cell.colSpan = 3;
        cell.textContent = 'Geen diensten ingeroosterd voor deze week';
        cell.style.textAlign = 'center';
        cell.style.fontStyle = 'italic';
        cell.style.color = '#6c757d';
        row.appendChild(cell);
        myScheduleBody.appendChild(row);
    }
}

function handleClockIn() {
    const now = new Date();
    const clockingData = JSON.parse(localStorage.getItem('clockings') || '{}');
    const userClockings = clockingData[currentUser.username] || [];
    
    // Controleer of er al een actieve sessie is
    const activeSession = userClockings.find(session => !session.clockOut);
    if (activeSession) {
        alert('Je bent al ingeklokt! Klok eerst uit voordat je opnieuw inklokt.');
        return;
    }
    
    // Voeg nieuwe clock-in toe
    const newSession = {
        clockIn: now.toISOString(),
        clockOut: null
    };
    
    userClockings.push(newSession);
    clockingData[currentUser.username] = userClockings;
    localStorage.setItem('clockings', JSON.stringify(clockingData));
    
    updateClockStatus();
    loadClockHistory();
}

function handleClockOut() {
    const now = new Date();
    const clockingData = JSON.parse(localStorage.getItem('clockings') || '{}');
    const userClockings = clockingData[currentUser.username] || [];
    
    // Zoek de actieve sessie
    const activeSessionIndex = userClockings.findIndex(session => !session.clockOut);
    if (activeSessionIndex === -1) {
        alert('Geen actieve sessie gevonden. Klok eerst in.');
        return;
    }
    
    // Update de actieve sessie met clock-out tijd
    userClockings[activeSessionIndex].clockOut = now.toISOString();
    clockingData[currentUser.username] = userClockings;
    localStorage.setItem('clockings', JSON.stringify(clockingData));
    
    updateClockStatus();
    loadClockHistory();
}

function updateClockStatus() {
    const clockStatus = document.getElementById('clockStatus');
    const lastClockTime = document.getElementById('lastClockTime');
    const clockInBtn = document.getElementById('clockInBtn');
    const clockOutBtn = document.getElementById('clockOutBtn');
    
    const clockingData = JSON.parse(localStorage.getItem('clockings') || '{}');
    const userClockings = clockingData[currentUser.username] || [];
    
    const activeSession = userClockings.find(session => !session.clockOut);
    
    if (activeSession) {
        clockStatus.textContent = 'Ingelogd';
        clockStatus.style.color = '#28a745';
        
        const clockInTime = new Date(activeSession.clockIn);
        lastClockTime.textContent = clockInTime.toLocaleString('nl-NL');
        
        clockInBtn.disabled = true;
        clockOutBtn.disabled = false;
    } else {
        clockStatus.textContent = 'Uitgelogd';
        clockStatus.style.color = '#dc3545';
        
        if (userClockings.length > 0) {
            const lastSession = userClockings[userClockings.length - 1];
            const lastTime = new Date(lastSession.clockOut || lastSession.clockIn);
            lastClockTime.textContent = lastTime.toLocaleString('nl-NL');
        } else {
            lastClockTime.textContent = '-';
        }
        
        clockInBtn.disabled = false;
        clockOutBtn.disabled = true;
    }
}

function loadClockHistory() {
    const clockHistoryBody = document.getElementById('clockHistoryBody');
    if (!clockHistoryBody) return;
    
    const clockingData = JSON.parse(localStorage.getItem('clockings') || '{}');
    const userClockings = clockingData[currentUser.username] || [];
    
    clockHistoryBody.innerHTML = '';
    
    // Sorteer op datum (nieuwste eerst)
    const sortedClockings = userClockings.sort((a, b) => 
        new Date(b.clockIn) - new Date(a.clockIn)
    );
    
    sortedClockings.slice(0, 10).forEach(session => { // Toon laatste 10 sessies
        const row = document.createElement('tr');
        
        const clockInDate = new Date(session.clockIn);
        const dateCell = document.createElement('td');
        dateCell.textContent = clockInDate.toLocaleDateString('nl-NL');
        row.appendChild(dateCell);
        
        const clockInCell = document.createElement('td');
        clockInCell.textContent = clockInDate.toLocaleTimeString('nl-NL');
        row.appendChild(clockInCell);
        
        const clockOutCell = document.createElement('td');
        if (session.clockOut) {
            const clockOutDate = new Date(session.clockOut);
            clockOutCell.textContent = clockOutDate.toLocaleTimeString('nl-NL');
        } else {
            clockOutCell.textContent = 'Actief';
            clockOutCell.style.color = '#28a745';
            clockOutCell.style.fontWeight = 'bold';
        }
        row.appendChild(clockOutCell);
        
        const hoursCell = document.createElement('td');
        if (session.clockOut) {
            const hours = (new Date(session.clockOut) - new Date(session.clockIn)) / (1000 * 60 * 60);
            hoursCell.textContent = hours.toFixed(2) + ' uur';
        } else {
            const hours = (new Date() - new Date(session.clockIn)) / (1000 * 60 * 60);
            hoursCell.textContent = hours.toFixed(2) + ' uur (lopend)';
            hoursCell.style.color = '#28a745';
        }
        row.appendChild(hoursCell);
        
        clockHistoryBody.appendChild(row);
    });
    
    if (clockHistoryBody.children.length === 0) {
        const row = document.createElement('tr');
        const cell = document.createElement('td');
        cell.colSpan = 4;
        cell.textContent = 'Geen inklok geschiedenis gevonden';
        cell.style.textAlign = 'center';
        cell.style.fontStyle = 'italic';
        cell.style.color = '#6c757d';
        row.appendChild(cell);
        clockHistoryBody.appendChild(row);
    }
}
