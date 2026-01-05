# Storage Structure - Bunny CDN

## Gestructureerde Bestandsopslag

### Doel

Bestanden worden opgeslagen in een georganiseerde folder structuur op Bunny CDN:

```
{number}-{exhibition-slug}/artworks/{artwork-slug}.{ext}
{number}-{exhibition-slug}/media/{photo-name}.{ext}
```

**Voorbeelden:**
- `03-jvde-2025/artworks/portrait-of-a-woman.jpg`
- `03-jvde-2025/artworks/abstract-composition.png`
- `04-exhibition-4/artworks/digital-artwork-1.webp`
- `03-jvde-2025/media/photographer-photo-1.jpg`
- `03-jvde-2025/media/opening-night-gallery.jpg`

### Voordelen

1. **Organisatie** - Files gegroepeerd per exhibition (artworks en media gescheiden)
2. **Debugging** - Makkelijk te vinden in Bunny dashboard (sequentieel genummerd)
3. **URL voorspelbaarheid** - Logische URL structuur
4. **Cache management** - Per exhibition cache purgen mogelijk
5. **Backup/restore** - Per exhibition backup strategie
6. **Photographer photos** - Dedicated folder voor tentoonstellingsfoto's

---

## Implementatie

### Exhibition Number Field

Exhibitions hebben een sequentieel nummer dat gebruikt wordt in storage paths:

```ruby
# app/models/exhibition.rb
validates :number, presence: true, uniqueness: true

# Returns formatted prefix: "03-jvde-2025"
def storage_prefix
  "#{number.to_s.rjust(2, '0')}-#{slug}"
end
```

### Automatische Key Generatie voor Artworks

Nieuwe artworks krijgen automatisch een custom storage key:

```ruby
# app/models/artwork.rb
after_create_commit :set_custom_blob_key_async

def update_blob_key!
  artwork_slug = title.parameterize
  extension = File.extname(file.blob.filename.to_s)

  # Uses exhibition.storage_prefix for numbered structure
  new_key = "#{exhibition.storage_prefix}/artworks/#{artwork_slug}#{extension}"
  file.blob.update_column(:key, new_key)
end
```

### Automatische Key Generatie voor Media

Exhibition media krijgt ook custom storage keys:

```ruby
# app/models/exhibition_medium.rb
after_create_commit :set_custom_blob_key_async

def update_blob_key!
  extension = File.extname(file.blob.filename.to_s)
  filename = file.blob.filename.base

  new_key = "#{exhibition.storage_prefix}/media/#{filename}#{extension}"
  file.blob.update_column(:key, new_key)
end
```

**Wanneer gebeurt dit:**
- Na het aanmaken van een nieuw artwork of media item
- Automatisch in de background
- Kan ook handmatig via `artwork.update_blob_key!` of `medium.update_blob_key!`

---

## Migratie Bestaande Bestanden

### Stap 1: Bekijk Huidige Storage Structuur

```bash
bin/rails storage:summary
```

**Output:**
```
Storage Structure Summary
================================================================================

01-test-exhibition-1/
├── artworks/ (52 files)
│   ├── portrait-of-a-woman.jpg
│   ├── abstract-composition.png
│   └── ...
└── media/ (0 files)
================================================================================
```

### Stap 2: Verifieer Huidige Keys

```bash
bin/rails storage:verify_artwork_keys
```

**Output:**
```
Verifying Artwork Blob Keys
================================================================================
❌ Artwork #1: Portrait of a Woman
   Expected: 01-jvde-2025/artworks/portrait-of-a-woman.jpg
   Actual:   a8f7d6e2b3c4...
================================================================================
Verification Results:
  ✅ Correct:   0
  ❌ Incorrect: 52
================================================================================
💡 Run 'rails storage:migrate_artwork_keys' to fix incorrect keys
```

### Stap 3: Bekijk Details (Optioneel)

```bash
bin/rails storage:show_artwork_keys
```

**Output:**
```
Current Artwork Blob Keys
================================================================================
Artwork #1: Portrait of a Woman
  Exhibition: 01-jvde-2025
  Current key: a8f7d6e2b3c4d5e6f7g8h9i0j1k2l3m4
  Expected key: 01-jvde-2025/artworks/portrait-of-a-woman.jpg
--------------------------------------------------------------------------------
```

### Stap 4: Migreer Artwork Keys

```bash
bin/rails storage:migrate_artwork_keys
```

**Output:**
```
Starting blob key migration...
================================================================================
Processing artwork 1... ✅
Processing artwork 2... ✅
Processing artwork 52... ✅
================================================================================
Migration complete!
  Total artworks: 52
  Updated:        52
  Skipped:        0 (no file attached)
  Errors:         0
================================================================================
✨ All artworks successfully migrated!
```

### Stap 5: Migreer Media Keys (Als je media hebt)

```bash
bin/rails storage:migrate_media_keys
```

### Stap 6: Of Migreer Alles Tegelijk

```bash
bin/rails storage:migrate_all
```

Dit runt beide migraties achter elkaar.

### Stap 7: Verifieer Opnieuw

```bash
bin/rails storage:verify_artwork_keys
```

**Output:**
```
Verification Results:
  ✅ Correct:   52
  ❌ Incorrect: 0
================================================================================
✨ All blob keys are correctly structured!
```

---

## Belangrijke Notes

### ⚠️ Twee Soorten Migratie

#### Optie 1: Database Only Update (Snelste)

**Commando's:**
```bash
bin/rails storage:migrate_all
```

**Wat gebeurt er:**
1. Database blob.key wordt geüpdatet naar nieuwe structuur
2. Rails/Bunny zal bestanden opvragen via nieuwe path
3. Oude bestanden blijven bestaan op oude locatie (orphaned)

**Voordelen:**
- ⚡ Zeer snel (alleen database update)
- ✅ Nieuwe uploads correct opgeslagen
- ✅ Oude uploads blijven werken

**Nadelen:**
- ⚠️ Oude files worden orphans (blijven bestaan maar niet gebruikt)
- 💾 Dubbele storage gebruikt (oude + nieuwe locaties)

#### Optie 2: Fysieke File Migratie (Aanbevolen)

**Commando's:**
```bash
bin/rails storage:move_all
```

**Wat gebeurt er:**
1. Bestand wordt gedownload van oude locatie
2. Bestand wordt geüpload naar nieuwe locatie
3. Database attachment wordt geüpdatet naar nieuwe blob
4. Oude bestand blijft bestaan (veiligheid)

**Voordelen:**
- ✅ Files op correcte locatie in Bunny
- ✅ Schone folder structuur
- ✅ Oude files blijven als backup

**Nadelen:**
- 🐌 Langzamer (download + upload per file)
- 💾 Tijdelijk dubbele storage

### Cleanup Orphaned Files (Optioneel)

Na verificatie dat alles werkt:

```bash
bin/rails storage:cleanup_orphaned
```

**⚠️ DANGER:** Dit verwijdert definitief alle orphaned files!

**Alleen uitvoeren als:**
1. Fysieke migratie succesvol is
2. Alle files getest en werkend zijn
3. Backup is gemaakt

---

## URL Structuur

### Development (Local Storage)

```
http://localhost:3000/rails/active_storage/disk/...
  → /storage/03-jvde-2025/artworks/portrait-of-a-woman.jpg
  → /storage/03-jvde-2025/media/photographer-photo-1.jpg
```

### Production (Bunny CDN)

```
https://[storage-zone].b-cdn.net/03-jvde-2025/artworks/portrait-of-a-woman.jpg
https://[storage-zone].b-cdn.net/03-jvde-2025/media/photographer-photo-1.jpg
```

**Bunny Storage Zone structuur:**
```
storage-zone-name/
├── 03-jvde-2025/
│   ├── artworks/
│   │   ├── portrait-of-a-woman.jpg
│   │   ├── abstract-composition.png
│   │   └── digital-artwork-1.webp
│   └── media/
│       ├── photographer-photo-1.jpg
│       └── opening-night-gallery.jpg
├── 04-exhibition-4/
│   ├── artworks/
│   │   ├── artwork-title-1.jpg
│   │   └── artwork-title-2.png
│   └── media/
│       └── exhibition-photo.jpg
└── ... (andere exhibitions)
```

---

## Admin Interface

### Artwork Upload Flow

1. Admin upload nieuw artwork via `/admin/exhibitions/{id}/artworks/new`
2. File wordt geüpload naar Bunny
3. `after_create_commit` callback triggered
4. `update_blob_key!` wordt uitgevoerd
5. Blob key in database wordt geüpdatet naar: `{number}-{exhibition-slug}/artworks/{artwork-slug}.{ext}`

### Media Upload Flow

1. Admin upload nieuwe media via `/admin/exhibitions/{id}/exhibition_media/new`
2. Single upload: één foto met caption en photographer
3. Bulk upload: meerdere foto's met optionele photographer (geldt voor alle)
4. `after_create_commit` callback triggered
5. Blob key wordt geüpdatet naar: `{number}-{exhibition-slug}/media/{filename}.{ext}`

### Public Media Gallery

1. Bezoekers kunnen foto's bekijken op `/exhibitions/{slug}/media`
2. Masonry grid layout (responsive: 3 kolommen → 2 → 1)
3. Caption en photographer informatie wordt getoond
4. Photos worden lazy loaded voor performance

### Bulk Upload

Voor bulk uploads blijft de flow hetzelfde:

```ruby
# app/controllers/admin/artworks_controller.rb
def bulk_create
  params[:files].each do |file|
    artwork = @exhibition.artworks.create!(
      title: extract_title(file),
      file: file
    )
    # Callback handled automatisch key update
  end
end

# app/controllers/admin/exhibition_media_controller.rb
def bulk_create
  params[:files].each do |file|
    medium = @exhibition.exhibition_media.create!(
      file: file,
      photographer: params[:photographer]
    )
    # Callback handled automatisch key update
  end
end
```

---

## Handmatige Key Update

### Individuele Artwork

```ruby
artwork = Artwork.find(1)
artwork.update_blob_key!
# => true (success)
```

### Bulk Update per Exhibition

```ruby
exhibition = Exhibition.find_by(slug: 'jvde-2025')
exhibition.artworks.find_each do |artwork|
  artwork.update_blob_key!
end
```

### Rails Console Helper

```ruby
# Update all artworks at once
Artwork.find_each { |a| a.update_blob_key! }

# Update artworks for specific exhibition
Exhibition.find_by(slug: 'jvde-2025').artworks.each(&:update_blob_key!)
```

---

## Troubleshooting

### Artwork heeft geen file

```ruby
artwork.file.attached?
# => false

artwork.update_blob_key!
# => false (skipped)
```

### Artwork heeft geen exhibition

```ruby
artwork.exhibition
# => nil

artwork.update_blob_key!
# => false (skipped)
```

### Artwork title is leeg

```ruby
artwork.title
# => ""

artwork.update_blob_key!
# => false (skipped)
```

### Check logs voor errors

```ruby
# Check Rails logs
tail -f log/production.log | grep "Failed to update blob key"
```

---

## Cache Purging (Bunny CDN)

### Per Exhibition

```bash
# Via Bunny API
curl -X POST "https://api.bunny.net/storagezone/[storage-id]/purge" \
  -H "AccessKey: [api-key]" \
  -H "Content-Type: application/json" \
  -d '{"path": "/jvde-2025/*"}'
```

### Individueel Artwork

```bash
curl -X POST "https://api.bunny.net/storagezone/[storage-id]/purge" \
  -H "AccessKey: [api-key]" \
  -H "Content-Type: application/json" \
  -d '{"path": "/jvde-2025/portrait-of-a-woman.jpg"}'
```

---

## Best Practices

### ✅ DO

- Upload nieuwe artworks via admin interface (automatisch correct gestructureerd)
- Run `storage:verify_artwork_keys` periodiek
- Backup Bunny storage per exhibition folder
- Gebruik logische artwork titles (worden slugified)

### ❌ DON'T

- Handmatig blobs aanmaken zonder key te zetten
- Direct database keys updaten zonder `update_blob_key!`
- Duplicate artwork titles binnen zelfde exhibition (key conflict)
- Speciale karakters in artwork titles (worden ge-slugified)

---

## Testing

Tests passen automatisch aan nieuwe structuur:

```ruby
# test/models/artwork_test.rb
test "should generate custom blob key after creation" do
  artwork = exhibitions(:one).artworks.create!(
    title: "Test Artwork",
    file: fixture_file_upload('test_image.jpg')
  )

  expected_key = "#{artwork.exhibition.slug}/test-artwork.jpg"
  assert_equal expected_key, artwork.file.blob.key
end
```

---

## Quick Reference - Migration Commands

### 📊 Check Status
```bash
bin/rails storage:summary                  # View current storage structure
bin/rails storage:verify_artwork_keys     # Check which files need migration
bin/rails storage:show_artwork_keys       # Detailed view of all keys
```

### 🔧 Database Only Migration (Fast)
```bash
bin/rails storage:migrate_all              # Migrate all (artworks + media)
bin/rails storage:migrate_artwork_keys     # Migrate only artworks
bin/rails storage:migrate_media_keys       # Migrate only media
```

### 🚚 Physical File Migration (Recommended)
```bash
bin/rails storage:move_all                 # Move all files physically
bin/rails storage:move_artworks            # Move only artwork files
bin/rails storage:move_media               # Move only media files
```

### 🗑️ Cleanup (Danger Zone)
```bash
bin/rails storage:cleanup_orphaned         # Delete old/orphaned files (⚠️ PERMANENT)
```

### 🎯 Recommended Workflow

**Voor nieuwe installaties:**
1. Gebruik nieuwe admin interface - automatisch correct

**Voor bestaande installaties:**
1. `bin/rails storage:verify_artwork_keys` - Check status
2. `bin/rails storage:move_all` - Move files physically
3. Test alle images op website
4. `bin/rails storage:cleanup_orphaned` - Cleanup (optioneel, na verificatie)

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-05 | Initial structured storage implementation |
| 1.1 | 2026-01-05 | Added exhibition numbers and physical file migration |
