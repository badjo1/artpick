# The Continuum - Business Rules

## Data Integriteit & Bescherming

### BR-001: Artwork Protection Rule

**Regel:** Artworks mogen NOOIT automatisch verwijderd worden bij het verwijderen van een exhibition.

**Rationale:**
- Artworks vertegenwoordigen waardevolle content met bijbehorende bestanden
- Accidentele verwijdering van een exhibition mag niet leiden tot dataverlies
- Admin moet bewust alle artworks handmatig verwijderen voor exhibition verwijdering

**Implementatie:**
```ruby
# app/models/exhibition.rb
has_many :artworks, dependent: :restrict_with_error
```

**Workflow:**
1. Admin probeert exhibition te verwijderen
2. System controleert: `exhibition.artworks.any?`
3. Als TRUE: Verwijdering geblokkeerd met error
4. Error message: "Cannot delete record because dependent artworks exist"
5. Admin moet eerst alle artworks individueel verwijderen
6. Dan kan exhibition verwijderd worden

**Test Coverage:**
- `test/models/exhibition_test.rb#test_should_not_destroy_exhibition_with_artworks`
- `test/models/exhibition_test.rb#test_should_destroy_exhibition_without_artworks`
- `test/models/exhibition_test.rb#test_should_destroy_exhibition_after_manually_deleting_all_artworks`

**Gerelateerde Code:**
- Model: `/app/models/exhibition.rb:4`
- Controller: `/app/controllers/admin/exhibitions_controller.rb:52-58`

---

### BR-002: Artist Nullification Rule

**Regel:** Wanneer een artist wordt verwijderd, blijven de artworks bestaan maar wordt artist_id op NULL gezet.

**Rationale:**
- Artworks zijn onafhankelijk van de artist entiteit
- Historische data moet bewaard blijven
- Artists kunnen gemerged of vervangen worden

**Implementatie:**
```ruby
# app/models/artist.rb
has_many :artworks, dependent: :nullify

# app/models/artwork.rb
belongs_to :artist, optional: true
```

**Workflow:**
1. Admin verwijdert artist
2. Alle artworks van deze artist blijven bestaan
3. `artwork.artist_id` wordt NULL
4. Artworks tonen "Unknown Artist" in UI

---

### BR-003: Analytics Data Cascade Delete

**Regel:** Analytics data (check_ins, comparisons, preferences) wordt automatisch verwijderd met de parent record.

**Rationale:**
- Analytics data is afgeleide informatie
- Geen waarde zonder context (exhibition, user, session)
- Voorkomt orphaned records en database bloat

**Implementatie:**
```ruby
# Exhibitions
has_many :check_ins, dependent: :destroy
has_many :comparisons, dependent: :destroy
has_many :preferences, dependent: :destroy

# Users
has_many :comparisons, dependent: :destroy
has_many :preferences, dependent: :destroy
has_many :check_ins, dependent: :destroy
```

**Affected Models:**
- `CheckIn` - Analytics/logging data
- `Comparison` - Vote records
- `Preference` - Top 5 selections
- `VotingSession` - Session data

---

## Voting & Ranking

### BR-004: Minimum Comparisons Rule

**Regel:** Gebruikers moeten minimaal `artworks_count / 2` comparisons maken voordat ze een top 5 kunnen selecteren.

**Rationale:**
- Elke comparison toont 2 artworks
- N/2 comparisons = theoretisch alle N artworks gezien
- Zorgt voor informed keuzes

**Formule:**
```ruby
def minimum_comparisons
  return 1 if artwork_count.zero? # Edge case
  (artwork_count / 2.0).ceil
end
```

**Voorbeelden:**
- 52 artworks → minimum 26 comparisons
- 51 artworks → minimum 26 comparisons (ceil)
- 30 artworks → minimum 15 comparisons
- 0 artworks → minimum 1 comparison (edge case)

**Test Coverage:**
- `test/models/exhibition_test.rb#test_minimum_comparisons_should_return_artwork_count_divided_by_2`
- `test/models/exhibition_test.rb#test_minimum_comparisons_should_handle_odd_numbers`
- `test/models/exhibition_test.rb#test_minimum_comparisons_should_handle_zero_artworks`

**UI Behavior:**
- Progress counter: "Comparisons: 15 / 26 minimum"
- "Select Your Top 5" button verschijnt bij minimum
- Help text moedigt aan door te gaan tot optimal (artwork_count)

---

### BR-005: Optimal Comparisons Rule

**Regel:** Het optimale aantal comparisons is gelijk aan het totaal aantal artworks.

**Rationale:**
- Statistisch gezien: elk artwork is minimaal 1x gezien
- Hogere kwaliteit rankings
- Betere Elo score distributie

**Formule:**
```ruby
def optimal_comparisons
  artwork_count
end
```

**UI Behavior:**
```
Comparisons: 30 / 26 minimum

Hoe meer artworks je vergelijkt, hoe beter je keuze • Optimum 52 vergelijkingen

[Select Your Top 5 →]
```

---

### BR-006: Elo Rating Exhibition Scoping

**Regel:** Elo scores zijn altijd scoped per exhibition.

**Rationale:**
- Artworks uit verschillende exhibitions zijn niet vergelijkbaar
- Elk exhibition heeft eigen context en kunstenaars
- Voorkomt cross-exhibition ranking vervuiling

**Implementatie:**
```ruby
# app/models/artwork.rb
def self.process_vote(winner_id, loser_id, exhibition)
  # Elo calculation
  # ...
  update_all_positions(exhibition)
end

def self.update_all_positions(exhibition)
  where(exhibition: exhibition).ranked(exhibition).each_with_index do |artwork, index|
    artwork.update_column(:position, index + 1)
  end
end
```

---

## Performance & Data Integrity

### BR-007: Counter Cache Rule

**Regel:** Alle `_count` columns MOETEN gesynchroniseerd worden via counter_cache.

**Affected Columns:**
- `exhibitions.artwork_count`
- `exhibitions.comparison_count`
- `artworks.vote_count`
- `artworks.favorite_count`

**Implementatie:**
```ruby
# app/models/artwork.rb
belongs_to :exhibition, counter_cache: :artwork_count
```

**Voordelen:**
- Geen COUNT queries
- Real-time updates
- Gebruikt in business logic (minimum_comparisons)

**Reset Counts (indien nodig):**
```ruby
Exhibition.find_each do |exhibition|
  Exhibition.reset_counters(exhibition.id, :artworks)
end
```

---

### BR-008: File Attachment Lifecycle

**Regel:** Active Storage attachments worden automatisch verwijderd met het parent record.

**Implementatie:**
```ruby
# app/models/artwork.rb
has_one_attached :file, dependent: :purge_later
```

**Behavior:**
- `dependent: :purge_later` - Background job (aanbevolen)
- Verwijdert blob, attachment record, EN file uit storage
- Voorkomt orphaned files

---

## Status & Enums

### BR-009: Exhibition Status Lifecycle

**Regel:** Exhibitions hebben drie statussen: `upcoming`, `active`, `archived`.

**Implementatie:**
```ruby
enum :status, { upcoming: 'upcoming', active: 'active', archived: 'archived' }
```

**Status Flow:**
```
upcoming → active → archived
```

**Regels:**
- `voting_open?` = `active?` AND (no end_date OR end_date >= today)
- Alleen `active` exhibitions kunnen votes ontvangen
- `archived` exhibitions zijn read-only

**Predicate Methods:**
- `exhibition.active?`
- `exhibition.upcoming?`
- `exhibition.archived?`

**Scopes:**
- `Exhibition.active`
- `Exhibition.upcoming`
- `Exhibition.archived`

---

## Validation Rules

### BR-010: Required Fields

**Exhibition:**
- `title` - REQUIRED
- `slug` - REQUIRED, unique
- `space_id` - REQUIRED (belongs_to)
- `status` - REQUIRED, default: 'upcoming'

**Artwork:**
- `title` - REQUIRED
- `file` - REQUIRED (Active Storage attachment)
- `exhibition_id` - REQUIRED (belongs_to)
- `elo_score` - REQUIRED, default: 1500
- `vote_count` - REQUIRED, default: 0

**Artist:**
- `name` - REQUIRED

---

## Security Rules

### BR-011: CSRF Token Generation

**Regel:** CSRF tokens MOETEN altijd server-side gegenereerd worden.

**Implementation:**
```erb
<!-- CORRECT -->
<form action="#" method="post">
  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
</form>

<!-- INCORRECT -->
<script>
  const token = document.querySelector('meta[name="csrf-token"]').content;
  // Client-side token injection = INSECURE
</script>
```

**Rationale:**
- Server-rendered tokens zijn gesynchroniseerd met sessie
- Client-side tokens kunnen stale/invalid zijn
- Voorkomt CSRF attacks

---

## Checklist: Nieuwe Features

Bij het toevoegen van nieuwe features, check:

- [ ] **BR-001**: Zijn waardevolle records beschermd? (`restrict_with_error`)
- [ ] **BR-003**: Hebben analytics associations `dependent: :destroy`?
- [ ] **BR-007**: Zijn counters gecached met `counter_cache`?
- [ ] **BR-008**: Hebben file attachments `dependent: :purge_later`?
- [ ] **BR-011**: Worden CSRF tokens server-side gegenereerd?
- [ ] Tests geschreven voor business logic?
- [ ] Documentatie bijgewerkt?

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-05 | System | Initial business rules documentation |
