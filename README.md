# ArtPick - Pairwise Image Ranking Application

Een productieklare webapplicatie voor het ranken van afbeeldingen via pairwise comparison, geïnspireerd op OpinionX. Gebouwd voor een fysieke kunsttentoonstelling.

## Overzicht

ArtPick stelt bezoekers in staat om 52 verticale afbeeldingen (9:16 portret) te ranken door herhaaldelijk te kiezen tussen twee afbeeldingen. Het systeem gebruikt het **Elo-ranking algoritme** om een globale ranking te berekenen op basis van alle stemmen.

### Kernfunctionaliteit

- **Pairwise Voting**: Gebruikers kiezen tussen twee afbeeldingen
- **Elo Rating Systeem**: Intelligente ranking op basis van alle stemronde
- **Session Tracking**: Geen login vereist, sessies via cookies
- **Admin Dashboard**: Beheer afbeeldingen, bekijk rankings en statistieken
- **Uitnodigingslinks**: Genereer trackbare links voor verschillende campagnes
- **Sociale Media Delen**: Deel resultaten op Twitter/X en LinkedIn
- **Email Uitnodigingen**: Nodig gebruikers uit via email
- **Deadline Management**: Automatisch sluiten van stemmen op 8 januari 2025

## Technische Stack

- **Framework**: Ruby on Rails 8.1.1
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Authenticatie**: bcrypt (voor admin)
- **File Storage**: Active Storage
- **Email**: Action Mailer
- **Styling**: Custom CSS (mobile-first, minimalistisch)

## Database Schema

### Tables

#### Images
- `id`: Primary key
- `title`: String - Titel van de afbeelding
- `elo_score`: Float (default: 1500.0) - Elo rating
- `vote_count`: Integer (default: 0) - Aantal keer dat deze afbeelding is vergeleken
- `position`: Integer - Huidige ranking positie
- `file`: Active Storage attachment (9:16 verticaal)
- `created_at`, `updated_at`

#### Votes
- `id`: Primary key
- `winner_id`: Foreign key naar Images
- `loser_id`: Foreign key naar Images
- `voting_session_id`: Foreign key naar VotingSessions (optional)
- `invite_link_id`: Foreign key naar InviteLinks (optional)
- `created_at`, `updated_at`

#### VotingSessions
- `id`: Primary key
- `session_token`: String (unique) - Identificeert een gebruikerssessie
- `ip_address`: String
- `user_agent`: String
- `last_activity`: DateTime
- `created_at`, `updated_at`

#### InviteLinks
- `id`: Primary key
- `token`: String (unique) - URL-safe token
- `name`: String - Optionele naam voor identificatie
- `vote_count`: Integer (default: 0) - Aantal stemmen via deze link
- `active`: Boolean (default: true) - Of de link actief is
- `created_at`, `updated_at`

#### Settings
- `id`: Primary key
- `key`: String (unique) - Setting naam
- `value`: Text - Setting waarde
- `created_at`, `updated_at`

#### Users (voor admin)
- `id`: Primary key
- `email_address`: String (unique)
- `password_digest`: String
- `created_at`, `updated_at`

#### Sessions (voor admin authenticatie)
- `id`: Primary key
- `user_id`: Foreign key naar Users
- `ip_address`: String
- `user_agent`: String
- `created_at`, `updated_at`

## Ranking Algoritme: Elo Rating

Het systeem gebruikt het **Elo rating algoritme** (bekend van schaakranglijsten) om afbeeldingen te ranken.

### Hoe werkt het?

1. **Initiële Score**: Elke afbeelding start met een Elo score van 1500
2. **Expected Score Berekening**:
   ```
   E_A = 1 / (1 + 10^((R_B - R_A) / 400))
   ```
   Dit berekent de verwachte kans dat afbeelding A wint van afbeelding B

3. **Score Update na Stem**:
   ```
   New Rating = Old Rating + K * (Actual - Expected)
   ```
   - K-factor = 32 (bepaalt hoe snel ratings veranderen)
   - Actual = 1 voor winnaar, 0 voor verliezer
   - Expected = berekende verwachting

4. **Positie Update**: Na elke stem worden alle posities opnieuw berekend op basis van Elo scores

### Voordelen van Elo

- ✅ Eerlijk: Rekening houdend met sterkte van tegenstanders
- ✅ Adaptief: Ratings passen zich aan naarmate meer data binnenkomt
- ✅ Betrouwbaar: Gebruikt in vele competitieve systemen
- ✅ Transparant: Duidelijke wiskundige basis

## Installatie & Setup

### Vereisten

- Ruby 3.2+
- PostgreSQL 14+
- Node.js (voor asset compilation)
- ImageMagick of libvips (voor image processing)

### Installatie Stappen

```bash
# Clone de repository
git clone <repository-url>
cd artpick

# Install dependencies
bundle install

# Setup database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# Start de server
bin/rails server
```

### Admin Toegang

Na `db:seed` zijn de volgende credentials beschikbaar:

- **Email**: admin@artpick.com
- **Password**: password123

**BELANGRIJK**: Wijzig deze credentials direct na de eerste login!

## Gebruik

### Voor Bezoekers

1. Navigeer naar `http://localhost:3000` (of je productie URL)
2. Klik op een van de twee getoonde afbeeldingen
3. Herhaal tot je alle paren hebt gezien
4. Bekijk de resultaten op `/results`

### Voor Administrators

#### Afbeeldingen Uploaden

1. Login op `/admin`
2. Ga naar "Afbeeldingen"
3. Klik "Nieuwe afbeelding toevoegen"
4. Upload een verticale afbeelding (9:16 ratio aanbevolen)
5. Geef een titel op
6. Klik "Afbeelding toevoegen"

**Tip**: Voor 52 afbeeldingen, upload ze één voor één of bulk upload via Rails console:

```ruby
# In Rails console (bin/rails console)
Dir.glob("path/to/images/*.jpg").each_with_index do |file, i|
  image = Image.create!(title: "Artwork #{i+1}")
  image.file.attach(io: File.open(file), filename: File.basename(file))
end
```

#### Uitnodigingslinks Maken

1. Ga naar "Uitnodigingslinks" in admin
2. Vul een optionele naam in (bijv. "Instagram Campaign")
3. Klik "Link aanmaken"
4. Kopieer de gegenereerde URL
5. Deel de link via sociale media, email, etc.

#### Instellingen Aanpassen

1. Ga naar "Instellingen"
2. Pas de stemdeadline aan (standaard: 8 januari 2025)
3. Wijzig de introductietekst voor de resultatenpagina
4. Klik "Instellingen opslaan"

## Deployment

### Heroku

```bash
# Install Heroku CLI en login
heroku login

# Create app
heroku create artpick-production

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Deploy
git push heroku main

# Run migrations
heroku run rails db:migrate
heroku run rails db:seed

# Open app
heroku open
```

### Docker (Production)

```bash
# Build image
docker build -t artpick .

# Run with docker-compose
docker-compose up -d
```

### Environment Variables

Zorg voor de volgende environment variables in productie:

```env
# Database
DATABASE_URL=postgresql://...
ARTPICK_DATABASE_PASSWORD=...

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=<generate met `rails secret`>

# Email (voor uitnodigingen)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Asset Host (optioneel)
ASSET_HOST=https://your-cdn.com
```

## Features Uitleg

### Deadline Logica

Het systeem controleert automatisch de deadline:

- **Voor 8 januari**: Gebruikers kunnen stemmen
- **Na 8 januari**: Redirect naar resultatenpagina
- **Admin**: Kan deadline aanpassen via instellingen

### Sessie Tracking

- Elke bezoeker krijgt automatisch een sessie
- Sessies worden opgeslagen in de database
- Voorkomt dat gebruikers hetzelfde paar twee keer zien
- Tracked aantal geziene paren per sessie

### Image Variant Processing

Active Storage gebruikt `image_processing` gem voor:

- Automatische format conversie (WebP voor moderne browsers)
- Lazy loading
- Responsive images

## Testing

```bash
# Run all tests
bin/rails test

# Run specific test
bin/rails test test/models/image_test.rb

# Run system tests (feature tests)
bin/rails test:system
```

## Performance Tips

### Voor 52 Afbeeldingen

- **Totaal aantal mogelijke paren**: 52 × 51 / 2 = 1,326 unieke combinaties
- **Aanbevolen minimum stemmen per gebruiker**: 20-30 paren
- **Geschatte tijd per gebruiker**: 2-3 minuten

### Database Optimalisatie

De database heeft indexes op:
- `images.elo_score` (voor snelle ranking queries)
- `images.position` (voor positie lookups)
- `votes.winner_id` en `votes.loser_id` (voor snelle vote queries)
- `voting_sessions.session_token` (voor sessie lookups)

### Caching (Optioneel)

Voor hoge traffic, overweeg:

```ruby
# In config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }

# Cache de ranking
def self.cached_ranking
  Rails.cache.fetch("ranking", expires_in: 5.minutes) do
    Image.ranked.to_a
  end
end
```

## Troubleshooting

### Afbeeldingen worden niet getoond

1. Check Active Storage configuratie in `config/storage.yml`
2. Zorg dat `image_processing` gem geïnstalleerd is
3. Controleer of ImageMagick/libvips beschikbaar is

### Elo scores worden niet bijgewerkt

1. Check de database logs voor errors
2. Verifieer dat `vote_count` wordt verhoogd
3. Run `Image.update_all_positions` in Rails console

### Email uitnodigingen werken niet

1. Configureer SMTP settings in `config/environments/production.rb`
2. Check Action Mailer logs
3. Verifieer dat background jobs draaien (Solid Queue)

## Licentie

Dit project is eigendom van [Jouw Naam/Organisatie].

## Support

Voor vragen of problemen, contacteer:
- Email: admin@artpick.com
- GitHub Issues: [repository-url]/issues

---

**Gebouwd met ❤️ voor kunstenaars en kunstliefhebbers**
