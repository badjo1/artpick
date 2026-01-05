# The Continuum - Best Practices

## Rails Conventions

### ✅ Altijd `dependent:` specificeren op associations

**Best Practice:** Elke `has_many` association MOET een `dependent:` strategie hebben

**Waarom:** Voorkomt orphaned records en foreign key violations

**Opties:**
- `dependent: :destroy` - Roept destroy aan op child records (triggers callbacks)
- `dependent: :delete_all` - Direct SQL DELETE (sneller, geen callbacks)
- `dependent: :nullify` - Zet foreign key naar NULL
- `dependent: :restrict_with_error` - Voorkomt delete als children bestaan

**Voorbeeld:**
```ruby
class Exhibition < ApplicationRecord
  # GOED - expliciet dependent strategy
  has_many :artworks, dependent: :destroy
  has_many :check_ins, dependent: :destroy

  # FOUT - geen dependent strategy
  # has_many :check_ins
  # => PG::ForeignKeyViolation bij delete!
end
```

**Vuistregel:**
- Analytics/logs (check_ins, audits): `dependent: :destroy`
- Waardevolle core data (artworks, users): `dependent: :restrict_with_error`
- Afgeleide data (comparisons, preferences): `dependent: :destroy`
- Through associations: Meestal geen dependent nodig
- Optional references: `dependent: :nullify`

**Protect Valuable Data:**
```ruby
class Exhibition < ApplicationRecord
  # Voorkomt accidentele delete van waardevolle artworks
  has_many :artworks, dependent: :restrict_with_error

  # Controller handling:
  def destroy
    if @exhibition.destroy
      redirect_to admin_exhibitions_path, notice: "Exhibition deleted"
    else
      # Error: "Cannot delete record because dependent artworks exist"
      redirect_to admin_exhibitions_path,
                  alert: "Cannot delete: #{@exhibition.errors.full_messages.join(', ')}"
    end
  end
end
```

---

### Convention over Configuration

Rails bevat veel "magic" die automatisch werkt als je de conventies volgt.

#### ✅ Gebruik Rails Enum voor status velden

**Wanneer:** Je hebt een veld met een beperkt aantal statussen (bijv. status, role, state)

**Voordeel:**
- Automatische predicate methods (`active?`, `published?`)
- Automatische scopes (`Article.published`, `User.admin`)
- Type safety
- Less code

**Voorbeeld:**
```ruby
class Exhibition < ApplicationRecord
  # DOE DIT
  enum :status, { upcoming: 'upcoming', active: 'active', archived: 'archived' }

  # NIET DIT
  def active?
    status == 'active'
  end

  scope :active, -> { where(status: 'active') }
end
```

**Genereert automatisch:**
- Methods: `exhibition.active?`, `exhibition.upcoming?`, `exhibition.archived?`
- Scopes: `Exhibition.active`, `Exhibition.upcoming`, `Exhibition.archived`
- Setters: `exhibition.active!`, `exhibition.upcoming!`

---

### Don't Repeat Yourself (DRY)

#### ✅ Extract duplicate view code naar partials

**Wanneer:** Dezelfde HTML structuur > 2x in dezelfde view

**Voordeel:**
- Single source of truth
- Makkelijker te onderhouden
- Testen van één partial in plaats van duplicates

**Voorbeeld:**
```erb
<!-- DOE DIT -->
<%= render 'comparison_artwork', artwork: @pair[0], opponent: @pair[1] %>
<%= render 'comparison_artwork', artwork: @pair[1], opponent: @pair[0] %>

<!-- NIET DIT -->
<button type="button" data-winner-id="<%= @pair[0].id %>">
  <%= image_tag @pair[0].file %>
</button>
<button type="button" data-winner-id="<%= @pair[1].id %>">
  <%= image_tag @pair[1].file %>
</button>
```

---

#### ✅ Gebruik Counter Cache voor has_many associations

**Wanneer:** Je roept regelmatig `.count` aan op een association

**Voordeel:**
- Voorkomt N+1 queries
- Real-time updates
- Sneller (geen COUNT query)

**Implementatie:**

1. **Voeg column toe aan parent table:**
```ruby
# Migration
add_column :exhibitions, :artworks_count, :integer, default: 0
```

2. **Voeg counter_cache toe aan belongs_to:**
```ruby
class Artwork < ApplicationRecord
  belongs_to :exhibition, counter_cache: :artworks_count
end
```

3. **Gebruik cached column:**
```ruby
class Exhibition < ApplicationRecord
  def minimum_comparisons
    # GOED - gebruikt cached column
    (artworks_count / 2.0).ceil

    # FOUT - triggert COUNT query
    # (artworks.count / 2.0).ceil
  end
end
```

4. **Reset existing counts:**
```ruby
Exhibition.find_each do |exhibition|
  Exhibition.reset_counters(exhibition.id, :artworks)
end
```

---

## Security

### ✅ Server-side CSRF Tokens

**ALTIJD gebruik server-side form helpers voor CSRF tokens**

**DOE DIT:**
```erb
<form action="#" method="post">
  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
  <%= hidden_field_tag :_method, 'delete' %>
</form>
```

**NIET DIT:**
```javascript
// Client-side token injection = FOUT
const csrfToken = document.querySelector('meta[name="csrf-token"]').content
form.innerHTML = `<input name="authenticity_token" value="${csrfToken}">`
```

**Waarom:** Server-rendered tokens zijn altijd gesynchroniseerd met de sessie.

---

### ⚠️ XSS Prevention

**Vermijd `innerHTML` met user input**

**Risico:**
```javascript
// GEVAARLIJK
this.bodyTarget.innerHTML = userProvidedHTML
```

**Oplossing:**
```javascript
// VEILIG
this.bodyTarget.textContent = userProvidedText

// Of sanitize HTML server-side in ERB met sanitize()
```

---

## Performance

### ✅ N+1 Query Prevention

**Gebruik `includes` voor eager loading**

```ruby
# GOED
@artworks = @exhibition.artworks.includes(:artist).ranked(@exhibition)

# FOUT (N+1 query)
@artworks = @exhibition.artworks.ranked(@exhibition)
# Later in view: artwork.artist.name (triggers query per artwork!)
```

---

## Code Organization

### ✅ Separation of Concerns

**CSS in stylesheet files, niet inline**

**DOE DIT:**
```erb
<p class="comparison-help-text">Text</p>
```

```css
.comparison-help-text {
  font-size: 0.85rem;
  text-align: center;
}
```

**NIET DIT:**
```erb
<p style="font-size: 0.85rem; text-align: center;">Text</p>
```

**Voordeel:**
- CSS caching
- Centraal styling beheer
- Responsive design
- Consistency

---

### ✅ Edge Case Handling

**Check voor edge cases in business logic**

```ruby
def minimum_comparisons
  # Edge case: prevent division by zero
  return 1 if artwork_count.zero?

  (artwork_count / 2.0).ceil
end
```

---

## Testing

### ✅ Test counter_cache behavior

```ruby
test "should update exhibition artwork_count after destroy" do
  initial_count = @exhibition.artworks.count

  delete admin_exhibition_artwork_url(@exhibition, @artwork)

  @exhibition.reload
  assert_equal initial_count - 1, @exhibition.artwork_count
end
```

---

## Documentatie

### ✅ Comment WHY, not WHAT

**GOED:**
```ruby
# Uses counter_cache for performance (no COUNT query)
def minimum_comparisons
  artwork_count
end
```

**FOUT:**
```ruby
# Returns the artwork count
def minimum_comparisons
  artwork_count
end
```

---

## Checklist: Code Review

Voor elke nieuwe feature/fix:

- [ ] Volgt Rails conventies? (enum, counter_cache, etc.)
- [ ] Is code DRY? (geen duplicatie)
- [ ] Zijn inline styles verwijderd?
- [ ] CSRF tokens server-side?
- [ ] XSS risico's geëlimineerd?
- [ ] N+1 queries voorkomen?
- [ ] Edge cases gehandled?
- [ ] Tests geschreven?
- [ ] Comments toegevoegd voor "why", niet "what"?
