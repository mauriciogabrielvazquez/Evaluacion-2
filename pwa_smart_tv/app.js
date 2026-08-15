const API_URL = 'http://localhost:3000/api/trips';
const TV_API_URL = 'http://192.168.100.11:3000/api/tv/select-trip';
const LOGIN_API_URL = 'http://192.168.100.11:3000/api/auth/login';

let allTrips = [];
let currentPage = 0;
const pageSize = 4;
let currentIndex = 0;
let cards = [];
const FALLBACK_IMAGE = './default-trip.jpg';

let tvSocket;
let isModalOpen = false;
let ignoreTelemetry = true; 

function obtenerImagenViaje(trip) {
    if (trip && trip.imageUrl && trip.imageUrl.trim() !== '') {
        return trip.imageUrl;
    }
    return FALLBACK_IMAGE;
}

function iniciarSocketTV(userId) {
    tvSocket = io('http://192.168.100.11:3000', { query: { userId: userId } });
    
    tvSocket.on('live_trip_data', (data) => {
        if (ignoreTelemetry) return; 
        
        let modal = document.getElementById('tv-trip-modal');
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'tv-trip-modal';
            modal.style.cssText = 'position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(15, 23, 42, 0.9); display:flex; align-items:center; justify-content:center; z-index:10000;';
            
            const content = document.createElement('div');
            content.id = 'tv-modal-content';
            content.style.cssText = 'background:#1e293b; padding:50px; border-radius:20px; text-align:center; box-shadow: 0 10px 40px rgba(0,0,0,0.7); border: 2px solid #0ea5e9; width: 650px; color: white; font-family: sans-serif;';
            
            modal.appendChild(content);
            document.body.appendChild(modal);
            isModalOpen = true;
        }

        const content = document.getElementById('tv-modal-content');
        content.innerHTML = `
            <h2 style="font-size: 34px; margin-bottom: 25px; color: white;">Abordaje a <span style="color:#0ea5e9;">${data.destino}</span></h2>
            <div style="display:flex; justify-content:space-between; background:#0f172a; padding: 30px; border-radius: 15px; margin-bottom: 35px;">
                <div>
                    <div style="color: #94a3b8; font-size: 16px; margin-bottom: 10px;">Temperatura</div>
                    <div style="font-size: 28px; font-weight: bold; color: #fbc02d;">${data.temperatura}°C</div>
                </div>
                <div>
                    <div style="color: #94a3b8; font-size: 16px; margin-bottom: 10px;">Prob. Lluvia</div>
                    <div style="font-size: 28px; font-weight: bold; color: #3b82f6;">${data.probLluvia}%</div>
                </div>
                <div>
                    <div style="color: #94a3b8; font-size: 16px; margin-bottom: 10px;">Distancia</div>
                    <div style="font-size: 28px; font-weight: bold; color: #4ade80;">${data.distancia} km</div>
                </div>
            </div>
            <button style="background:#fbc02d; color:black; padding:15px 40px; font-size:22px; font-weight:bold; border:none; border-radius:10px; box-shadow: 0 0 15px rgba(251, 192, 45, 0.4);">Presiona ENTER para continuar</button>
        `;
    });
}

function mostrarLoginTV() {
    const body = document.body;
    const loginDiv = document.createElement('div');
    loginDiv.id = 'login-tv-overlay';
    loginDiv.style.cssText = 'position:fixed; top:0; left:0; width:100%; height:100%; background:#0f172a; z-index:9999; display:flex; flex-direction:column; align-items:center; justify-content:center; color:white; font-family:sans-serif;';
    
    loginDiv.innerHTML = `
        <div style="background:#1e293b; padding:40px; border-radius:15px; text-align:center; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
            <h1 style="color:#0ea5e9; margin-bottom:20px;">Vincular Smart TV</h1>
            <p style="margin-bottom:30px; color:#94a3b8;">Inicia sesión con tu cuenta de TravelApp</p>
            <input type="email" id="tv-email" placeholder="Correo electrónico" style="display:block; margin:10px auto; padding:15px; font-size:16px; width:300px; border-radius:8px; border:none; color:black;">
            <input type="password" id="tv-pass" placeholder="Contraseña" style="display:block; margin:10px auto; padding:15px; font-size:16px; width:300px; border-radius:8px; border:none; color:black;">
            <button onclick="ejecutarLoginTV()" style="margin-top:20px; padding:15px 30px; font-size:18px; background:#fbc02d; color:black; font-weight:bold; border:none; border-radius:8px; cursor:pointer; width:100%;">Entrar a la TV</button>
        </div>
    `;
    body.appendChild(loginDiv);
    document.getElementById('tv-pass').addEventListener('keypress', e => { if (e.key === 'Enter') ejecutarLoginTV(); });
}

async function ejecutarLoginTV() {
    const email = document.getElementById('tv-email').value;
    const pass = document.getElementById('tv-pass').value;
    try {
        const res = await fetch(LOGIN_API_URL, {
            method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ email, password: pass })
        });
        const data = await res.json();
        if (res.ok && data.token && data.userId) {
            localStorage.setItem('tv_userId', data.userId);
            document.getElementById('login-tv-overlay').remove(); 
            iniciarSocketTV(data.userId);
            loadTrips(); 
        } else alert('Credenciales incorrectas');
    } catch (error) { alert('Error conectando al servidor'); }
}

function updateDateTime() {
    const now = new Date();
    const display = document.getElementById('datetime-display');
    if (display) display.textContent = now.toLocaleDateString('es-MX', { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

// --- FUNCIÓN MODIFICADA PARA MODO OFFLINE ---
async function loadTrips() {
    try {
        const response = await fetch(API_URL);
        if (!response.ok) throw new Error('Error de red');
        
        const trips = await response.json();
        
        // Guardar respaldo para cuando no haya internet
        localStorage.setItem('tv_datos_offline', JSON.stringify(trips));
        
        if (Array.isArray(trips)) { 
            allTrips = trips; 
            if (allTrips.length > 0) renderPage(0); 
        }
    } catch (error) {
        console.warn('Modo Offline: Cargando datos guardados...');
        // Recuperar datos si falla el fetch
        const datosGuardados = localStorage.getItem('tv_datos_offline');
        if (datosGuardados) {
            const trips = JSON.parse(datosGuardados);
            if (Array.isArray(trips)) {
                allTrips = trips;
                if (allTrips.length > 0) renderPage(0);
            }
        } else {
            console.error('No hay datos offline disponibles.');
        }
    }
}

function renderPage(pageIndex) {
    currentPage = pageIndex;
    const gridContainer = document.getElementById('grid-container');
    if (!gridContainer) return;
    gridContainer.innerHTML = '';
    const pageTrips = allTrips.slice(currentPage * pageSize, (currentPage * pageSize) + pageSize);

    pageTrips.forEach((trip, index) => {
        const card = document.createElement('div');
        card.className = 'card';
        card.tabIndex = 0;
        
        const validImageUrl = obtenerImagenViaje(trip);

        card.innerHTML = `
            <div class="card-image-container">
                <img src="${validImageUrl}" class="card-image" alt="${trip.title}" onerror="this.onerror=null; this.src='${FALLBACK_IMAGE}';">
            </div>
            <div class="card-info">
                <h1 class="main-data">$${trip.price}</h1>
                <p class="secondary-label">${trip.title}</p>
                <p class="detail-text">Destino: ${trip.destination}</p>
                <p class="description-text">${trip.description}</p>
            </div>
        `;
        card.addEventListener('click', () => selectCard(index));
        gridContainer.appendChild(card);
    });

    cards = document.querySelectorAll('.card');
    if (cards.length > 0) {
        if (currentIndex >= cards.length) currentIndex = cards.length - 1;
        updateFocus();
    }
}

function updateFocus() {
    cards.forEach(c => c.classList.remove('active'));
    if (cards[currentIndex]) {
        cards[currentIndex].classList.add('active');
        cards[currentIndex].focus();
    }
}

function selectCard(index) { currentIndex = index; updateFocus(); }

document.addEventListener('keydown', (e) => {
    if (document.getElementById('login-tv-overlay')) return;

    if (isModalOpen) {
        if (e.key === 'Enter') {
            ignoreTelemetry = true; 
            const tvUserId = localStorage.getItem('tv_userId'); 
            if (tvSocket && tvUserId) tvSocket.emit('close_trip_modal', { userId: tvUserId });
            
            const modal = document.getElementById('tv-trip-modal');
            if (modal) modal.remove();
            isModalOpen = false;
        }
        return; 
    }

    if (cards.length === 0) return;
    let row = Math.floor(currentIndex / 2), col = currentIndex % 2;

    switch (e.key) {
        case 'ArrowUp': if (row > 0) row--; else if (currentPage > 0) { renderPage(currentPage - 1); row = 1; } break;
        case 'ArrowDown': if (row < 1) row++; else if ((currentPage + 1) * pageSize < allTrips.length) { renderPage(currentPage + 1); row = 0; } break;
        case 'ArrowLeft': if (col > 0) col--; break;
        case 'ArrowRight': if (col < 1) col++; break;
        case 'Enter':
            const currentTrip = allTrips[currentPage * pageSize + currentIndex];
            const bgImage = obtenerImagenViaje(currentTrip);
            
            const bgElement = document.getElementById('app-background');
            if (bgElement) {
                const tempImg = new Image();
                tempImg.src = bgImage;
                tempImg.onload = () => bgElement.style.backgroundImage = `url(${bgImage})`;
                tempImg.onerror = () => bgElement.style.backgroundImage = `url(${FALLBACK_IMAGE})`;
            }

            const tvUserId = localStorage.getItem('tv_userId'); 
            if (currentTrip && tvUserId) {
                ignoreTelemetry = false; 
                fetch(TV_API_URL, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ destino: currentTrip.destination || currentTrip.title, asiento: '14B', userId: tvUserId })
                });
            }
            return;
    }
    currentIndex = row * 2 + col;
    if (currentIndex >= cards.length) currentIndex = cards.length - 1;
    updateFocus();
});

setInterval(updateDateTime, 1000);
updateDateTime();

const savedUserId = localStorage.getItem('tv_userId');
if (savedUserId) {
    iniciarSocketTV(savedUserId);
    loadTrips();
} else {
    mostrarLoginTV();
}

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js')
      .then(registration => {
        console.log('ServiceWorker registrado con éxito con el scope:', registration.scope);
      })
      .catch(error => {
        console.error('Error al registrar el ServiceWorker:', error);
      });
  });
}