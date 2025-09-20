# Personeelsplanner Webapplicatie

Een moderne webapplicatie voor personeelsplanning met inklokfunctionaliteit, gebouwd met HTML, CSS en JavaScript.

## 🚀 Features

### Login Systeem
- Veilige inlogfunctionaliteit met hardcoded demo accounts
- Automatische redirect naar juiste dashboard (admin/werknemer)
- Session management met localStorage

### Admin Dashboard
- Weekrooster beheer met 3 tijdsloten per dag
- Werknemers toewijzen aan specifieke tijdsloten
- Week selector voor verschillende periodes
- Overzicht van alle werknemers

### Werknemer Dashboard
- Persoonlijk rooster overzicht
- Inklok/uitklok functionaliteit
- Inklok geschiedenis met gewerkte uren
- Real-time status updates

## 👥 Demo Accounts

| Gebruiker | Wachtwoord | Rol |
|-----------|------------|-----|
| admin | admin123 | Administrator |
| sven | sven123 | Werknemer |
| anna | anna123 | Werknemer |
| tom | tom123 | Werknemer |

## 📁 Bestandsstructuur

```
├── index.html          # Loginpagina
├── admin.html          # Admin dashboard
├── employee.html       # Werknemer dashboard
├── style.css           # Styling en layout
├── script.js           # JavaScript functionaliteit
├── database.sql        # MySQL database schema
└── README.md           # Deze documentatie
```

## 🛠️ Installatie & Gebruik

1. Clone deze repository
2. Open `index.html` in je webbrowser
3. Log in met een van de demo accounts
4. Begin met het beheren van roosters of inklokken

## 💾 Database

Het project bevat een uitgebreid MySQL database schema (`database.sql`) met:

- **users** tabel voor gebruikersbeheer
- **shifts** tabel voor roosterdata
- **clockings** tabel voor inklok/uitklok tijden
- Views, stored procedures en triggers voor optimale functionaliteit

## 🎨 Design

- Responsive design (desktop, tablet, mobiel)
- Moderne gradient achtergronden
- Professionele UI/UX
- Flexbox/Grid layout

## 🔧 Technologieën

- **Frontend:** HTML5, CSS3, JavaScript (ES6+)
- **Data opslag:** localStorage (geen backend nodig)
- **Database:** MySQL (voor toekomstige uitbreidingen)

## 📱 Browser Ondersteuning

- Chrome (aanbevolen)
- Firefox
- Safari
- Edge

## 🤝 Bijdragen

Voel je vrij om issues te rapporteren of pull requests in te dienen voor verbeteringen.

## 📄 Licentie

Dit project is open source en beschikbaar onder de MIT licentie.
