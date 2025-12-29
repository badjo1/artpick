# ArtPick - Productie Deployment Checklist

## 1. Bunny.net CDN Configuratie

### Environment Variabelen Instellen
Voeg deze environment variabelen toe aan je productie server:

```bash
BUNNY_ACCESS_KEY=your_bunny_access_key
BUNNY_SECRET_KEY=your_bunny_secret_key
BUNNY_BUCKET_NAME=your_bucket_name
BUNNY_REGION=de  # Of jouw regio (bijv. de, uk, ny)
BUNNY_ENDPOINT=https://storage.bunnycdn.com  # Of jouw specifieke endpoint
```

### Bunny.net Storage Zone Aanmaken

1. **Log in** op [Bunny.net dashboard](https://dash.bunny.net)

2. **Maak Storage Zone aan**:
   - Ga naar "Storage" → "Storage Zones"
   - Klik "Add Storage Zone"
   - Kies een naam (bijv. "artpick-images")
   - Selecteer regio: **Falkenstein (de)** (of jouw voorkeur)
   - Klik "Add Storage Zone"

3. **Noteer credentials**:
   - **Storage Zone Name**: Dit is je `BUNNY_STORAGE_ZONE` (bijv. "artpick-images")
   - **Password**: Dit is je `BUNNY_SECRET_KEY` (zie onder FTP & API Access)
   - **ReadOnlyPassword**: Dit is je `BUNNY_ACCESS_KEY` (gebruik de ReadOnly password)
   - **Region**: `de` voor Falkenstein (of `uk`, `ny`, etc.)

4. **Belangrijk**:
   - ✅ Gebruik de **ReadOnly Password** als `BUNNY_ACCESS_KEY`
   - ✅ Gebruik de **Password** als `BUNNY_SECRET_KEY`
   - ✅ Storage Zone moet **public** zijn (niet private)

### Pull Zone Instellen (optioneel maar aanbevolen)
Voor snellere laadtijden:
1. Maak een Pull Zone aan die gekoppeld is aan je Storage Zone
2. Gebruik de Pull Zone URL voor betere CDN prestaties

## 2. Database Setup (PostgreSQL)

### 4 Aparte Databases Aanmaken

De applicatie gebruikt **4 aparte databases**:
1. **artpick_production** - Hoofddatabase (users, images, votes, etc.)
2. **artpick_cache** - Solid Cache tabellen
3. **artpick_queue** - Solid Queue tabellen (background jobs)
4. **artpick_cable** - Solid Cable tabellen (websockets)

### Database URLs Instellen
Stel deze environment variabelen in op je platform (Heroku, Hatchbox, etc.):

```bash
DATABASE_URL=postgresql://user:pass@host:5432/artpick_production
CACHE_DATABASE_URL=postgresql://user:pass@host:5432/artpick_cache
QUEUE_DATABASE_URL=postgresql://user:pass@host:5432/artpick_queue
CABLE_DATABASE_URL=postgresql://user:pass@host:5432/artpick_cable
```

**Op Hatchbox/Heroku**: Deze databases worden vaak automatisch aangemaakt als je ze toevoegt aan je app configuratie.

### Database Aanmaken & Migreren
```bash
# Maak alle databases aan
RAILS_ENV=production bin/rails db:create

# Of handmatig via psql:
createdb artpick_production
createdb artpick_cache
createdb artpick_queue
createdb artpick_cable

# Voer alle migraties uit
RAILS_ENV=production bin/rails db:prepare
```

## 3. Admin Gebruiker Aanmaken

### Via Rails Console
```bash
RAILS_ENV=production bin/rails console
```

Voer uit in de console:
```ruby
User.create!(
  email_address: 'jouw@email.com',
  password: 'kies_een_sterk_wachtwoord',
  password_confirmation: 'kies_een_sterk_wachtwoord'
)
```

### Via Seeds (optioneel)
Je kunt ook `db/seeds.rb` aanpassen en dan uitvoeren:
```bash
RAILS_ENV=production bin/rails db:seed
```

## 4. Settings Configureren

### Via Admin Dashboard
1. Log in op `/session` met je admin account
2. Ga naar "Instellingen"
3. Stel in:
   - **Voting Open**: Ja (om stemming te starten)
   - **Voting Deadline**: 2025-01-08 (of jouw gewenste datum)
   - **Results Intro Text**: Welkomsttekst voor resultaten pagina

### Of via Rails Console
```ruby
Setting.update_voting_open(true)
Setting.update_voting_deadline(Date.new(2025, 1, 8))
Setting.update_results_intro("Welkom bij de ArtPick resultaten!")
```

## 5. Verplichte Environment Variabelen

```bash
# Database (Primary)
DATABASE_URL=postgresql://user:pass@host:5432/artpick_production

# Aparte Databases voor Cache, Queue en Cable
CACHE_DATABASE_URL=postgresql://user:pass@host:5432/artpick_cache
QUEUE_DATABASE_URL=postgresql://user:pass@host:5432/artpick_queue
CABLE_DATABASE_URL=postgresql://user:pass@host:5432/artpick_cable

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=<genereer met: bin/rails secret>

# Bunny.net CDN (zie sectie 1 voor credentials)
BUNNY_STORAGE_ZONE=your_storage_zone_name
BUNNY_ACCESS_KEY=your_access_key
BUNNY_SECRET_KEY=your_password_from_bunny
BUNNY_REGION=de

# Email (voor uitnodigingen, optioneel)
# Voeg deze toe aan je environment variabelen:
# SMTP_ADDRESS=je_smtp_server
# SMTP_PORT=587
# SMTP_DOMAIN=je_domain
# SMTP_USERNAME=je_username
# SMTP_PASSWORD=je_wachtwoord
```

### Secret Key Base Genereren
```bash
bin/rails secret
```

## 6. Assets Precompileren

```bash
RAILS_ENV=production bin/rails assets:precompile
```

## 7. Security Checklist

### SSL/HTTPS
- ✅ `config.force_ssl = true` is al ingesteld
- Zorg dat je hosting SSL certificaat heeft (Let's Encrypt)

### CSRF Protection
- ✅ Automatisch ingeschakeld in Rails

### Content Security Policy (optioneel maar aanbevolen)
Voeg toe aan `config/initializers/content_security_policy.rb`:
```ruby
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.img_src :self, :https, :data, "*.bunnycdn.com"
  policy.script_src :self, :https
  policy.style_src :self, :https, :unsafe_inline
end
```

## 8. Performance Optimalisatie

### Database Indexen
✅ Al aanwezig in de migraties

### Caching
Redis of Solid Cache is al geconfigureerd voor:
- Page caching
- Fragment caching
- Session storage

### CDN
✅ Bunny.net is geconfigureerd voor image hosting

## 9. Monitoring & Logging

### Health Check Endpoint
- URL: `https://jouwdomain.nl/up`
- Controleer of deze 200 OK returnt

### Log Niveau
In `config/environments/production.rb`:
```ruby
config.log_level = :info  # Of :warn voor minder logs
```

## 10. Afbeeldingen Uploaden

### Bulk Upload via Admin
1. Log in op admin dashboard
2. Ga naar "Afbeeldingen" → "Bulk Upload"
3. Sleep je 52 afbeeldingen in de upload zone
4. Wacht tot alle uploads voltooid zijn
5. Afbeeldingen worden automatisch naar Bunny.net geüpload

### Aandachtspunten voor Afbeeldingen
- **Formaat**: Bij voorkeur landscape/horizontaal (16:9)
- **Bestandstype**: JPG, PNG, WEBP
- **Bestandsgrootte**: Maximaal 10MB per afbeelding
- **Optimalisatie**: Comprimeer afbeeldingen vooraf voor snellere laadtijden
- **Naamgeving**: Duidelijke bestandsnamen (worden automatisch omgezet naar titels)

## 11. Testing voor Go-Live

### Functionele Tests
- [ ] Admin kan inloggen
- [ ] Admin kan afbeeldingen uploaden
- [ ] Afbeeldingen worden correct getoond op Bunny.net CDN
- [ ] Stemmen werkt (beide knoppen)
- [ ] Teller gaat omhoog na elke stem
- [ ] Na 26 stemmen: "Kies top 5" link verschijnt
- [ ] Top 5 selectie werkt
- [ ] Top 5 wordt opgeslagen
- [ ] Resultaten pagina toont:
  - Top 10 Elo ranking
  - Top 10 Favorieten
  - Favorite counts
- [ ] Email uitnodigingen werken (indien geconfigureerd)
- [ ] Social sharing links werken

### Performance Tests
- [ ] Pagina laadt in < 3 seconden
- [ ] Afbeeldingen laden snel vanaf Bunny.net
- [ ] Mobiele weergave werkt goed
- [ ] Responsive design werkt op alle schermformaten

### Security Tests
- [ ] HTTPS werkt op alle paginas
- [ ] Admin routes zijn beveiligd
- [ ] Session management werkt correct
- [ ] CSRF tokens werken

## 12. Go-Live Stappen

1. **Database backup maken**
   ```bash
   pg_dump artpick_production > backup_$(date +%Y%m%d).sql
   ```

2. **Laatste deployment**
   ```bash
   git pull origin main
   RAILS_ENV=production bin/rails db:migrate
   RAILS_ENV=production bin/rails assets:precompile
   # Herstart je web server (Puma)
   ```

3. **Voting openen**
   - Via Admin → Instellingen → Voting Open: Ja

4. **Monitoring inschakelen**
   - Controleer logs: `tail -f log/production.log`
   - Monitor server resources (CPU, memory)

5. **Uitnodigingen versturen**
   - Via Admin → Uitnodigingslinks
   - Of via email uitnodigingen

## 13. Post-Launch Monitoring

### Dagelijks Controleren
- Aantal unieke sessies: Admin Dashboard
- Aantal stemmen: Admin Dashboard
- Top 5 selecties: Admin Dashboard
- Server performance

### Voor Deadline (8 januari 2025)
- Stemming automatisch gesloten om 23:59
- Resultaten blijven zichtbaar
- Data backup maken

## 14. Troubleshooting

### Afbeeldingen worden niet getoond
1. Controleer Bunny.net credentials
2. Controleer CORS instellingen in Bunny.net
3. Controleer browser console voor errors
4. Test met: `RAILS_ENV=production bin/rails assets:precompile`

### Stemmen werkt niet
1. Controleer JavaScript errors in browser console
2. Controleer database connectie
3. Controleer logs: `tail -f log/production.log`

### Database problemen
1. Controleer DATABASE_URL
2. Test connectie: `RAILS_ENV=production bin/rails db:migrate:status`
3. Backup terugzetten indien nodig

## 15. Backup Strategie

### Dagelijks
```bash
# Database backup
pg_dump artpick_production | gzip > backup_$(date +%Y%m%d).sql.gz

# Uploaded files backup (indien lokaal opgeslagen)
tar -czf storage_backup_$(date +%Y%m%d).tar.gz storage/
```

### Voor belangrijke momenten
- Voor deployment
- Voor database migraties
- Voor grote wijzigingen
- Op 8 januari 2025 (voor deadline)

## Support

Voor vragen of problemen:
1. Check logs: `log/production.log`
2. Check Rails console: `RAILS_ENV=production bin/rails console`
3. Check database: `RAILS_ENV=production bin/rails db:migrate:status`

---

**Laatste check**: Alle taken in deze checklist doorlopen? Dan ben je klaar voor productie! 🚀
