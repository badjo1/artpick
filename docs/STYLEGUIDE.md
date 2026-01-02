# Rails Project Styleguide

> Gedeelde code styling, conventions, en best practices voor Rails projecten

**Versie:** 1.0
**Gebaseerd op:** FundTogether Styleguide
**Project:** The Continuum (ArtPick)

---

## Inhoudsopgave

1. [Code Formatting](#code-formatting)
2. [Naming Conventions](#naming-conventions)
3. [File Structure](#file-structure)
4. [Views & Templates](#views--templates)
5. [Components & Partials](#components--partials)
6. [JavaScript & Stimulus](#javascript--stimulus)
7. [Rails Conventions](#rails-conventions)
8. [Database & Models](#database--models)
9. [Testing](#testing)
10. [Security](#security)
11. [Git Workflow](#git-workflow)

---

## Code Formatting

### Ruby

**Indentatie:** 2 spaties (geen tabs)

```ruby
# ✅ Goed
def calculate_score
  if artwork.present?
    artwork.elo_score
  else
    1500.0
  end
end

# ❌ Fout (4 spaties of tabs)
def calculate_score
    if artwork.present?
        artwork.elo_score
    end
end
```

**Lijn lengte:** Max 120 karakters

**String quotes:**
- Gebruik single quotes voor strings zonder interpolation
- Gebruik double quotes voor interpolation

```ruby
# ✅ Goed
title = 'Artwork Title'
message = "Welcome, #{user.name}!"

# ❌ Fout
title = "Artwork Title"
message = 'Welcome, ' + user.name + '!'
```

### ERB Templates

**Indentatie:** 2 spaties

```erb
<!-- ✅ Goed -->
<div class="container">
  <% if artwork.present? %>
    <h1><%= artwork.title %></h1>
  <% end %>
</div>

<!-- ❌ Fout -->
<div class="container">
<% if artwork.present? %>
<h1><%= artwork.title %></h1>
<% end %>
</div>
```

**ERB tags:**
- `<%= %>` voor output
- `<% %>` voor logic (geen output)
- `<%# %>` voor comments

---

## Naming Conventions

### Files & Directories

**Models:** Singular, snake_case
```
app/models/artwork.rb
app/models/voting_session.rb
```

**Controllers:** Plural, snake_case
```
app/controllers/artworks_controller.rb
app/controllers/exhibitions_controller.rb
```

**Views:** Match controller name, snake_case
```
app/views/exhibitions/index.html.erb
app/views/exhibitions/show.html.erb
```

**Partials:** Prefix met underscore
```
app/views/shared/_public_layout.html.erb
app/views/artworks/_card.html.erb
```

### Ruby Code

**Classes & Modules:** PascalCase
```ruby
class VotingSession
module EloCalculation
```

**Methods & Variables:** snake_case
```ruby
def calculate_elo_score
  personal_score = 0
end
```

**Constants:** SCREAMING_SNAKE_CASE
```ruby
MINIMUM_COMPARISONS = 26
DEFAULT_ELO_SCORE = 1500.0
```

**Boolean methods:** End with `?`
```ruby
def voting_open?
  active? && (end_date.nil? || end_date >= Date.today)
end

def has_voted?(session)
  # ...
end
```

**Destructive methods:** End with `!`
```ruby
def increment_elo_score!(amount)
  # modifies object
end
```

### Database

**Tables:** Plural, snake_case
```sql
artworks
exhibitions
voting_sessions
```

**Columns:** snake_case
```sql
elo_score
vote_count
created_at
```

**Foreign keys:** `{model}_id`
```sql
artwork_id
exhibition_id
voting_session_id
```

**Join tables:** Alphabetical order
```ruby
# ❌ Fout
sessions_artworks

# ✅ Goed
artwork_sessions
```

---

## File Structure

### Standard Rails Structure

```
app/
├── assets/
│   ├── images/
│   └── stylesheets/
├── channels/
├── controllers/
│   ├── concerns/
│   └── *_controller.rb
├── helpers/
│   └── *_helper.rb
├── javascript/
│   ├── application.js
│   └── controllers/          # Stimulus controllers
├── mailers/
├── models/
│   ├── concerns/
│   └── *.rb
└── views/
    ├── layouts/
    ├── shared/               # Shared partials
    └── {resource}/           # Per-resource views
```

### Component Organization

**Shared Components:** `app/views/shared/`
```
shared/
├── _public_layout.html.erb   # Public facing layout
├── _flash_messages.html.erb  # Alert messages
├── _error_messages.html.erb  # Form errors
└── _navigation.html.erb      # Navigation
```

---

## Views & Templates

### Layout Structure

```erb
<!-- Gebruik layouts voor consistent page structure -->
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "The Continuum" %></title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag :app %>
    <%= javascript_importmap_tags %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

### View Organization

**1 view = 1 verantwoordelijkheid**

```erb
<!-- ✅ Goed: Gebruik partials -->
<div class="container">
  <%= render 'shared/flash_messages' %>
  <%= render 'header' %>
  <%= render 'content' %>
</div>

<!-- ❌ Fout: Alles in één file -->
<div class="container">
  <!-- 200 regels code... -->
</div>
```

### Comments in Views

```erb
<!-- Section Headers -->
<!-- ============================================ -->
<!-- Exhibition Overview Section -->
<!-- ============================================ -->

<!-- Inline Comments -->
<%# TODO: Add validation message %>
<%# NOTE: This is temporary until voting closes %>
```

### Inline Styles & Scripts

**❌ NEVER use inline styles or scripts:**

```erb
<!-- ❌ Fout - geen inline styles -->
<div style="margin-top: 1rem; color: #666;">Content</div>

<!-- ❌ Fout - geen inline scripts -->
<button onclick="doSomething()">Click</button>
<script>
  function doSomething() { }
</script>

<!-- ✅ Goed - gebruik CSS classes -->
<div class="mt-md text-secondary">Content</div>

<!-- ✅ Goed - gebruik Stimulus controllers -->
<button data-action="click->example#doSomething">Click</button>
```

**Waarom:**
- Separation of concerns (HTML, CSS, JS gescheiden)
- Herbruikbaarheid via CSS classes
- Eenvoudiger te onderhouden
- Betere performance (CSS caching)
- Consistentie in design

**Uitzonderingen:**
- Inline styles zijn ALLEEN toegestaan voor dynamische waarden die uit de backend komen (bijv. positionering gebaseerd op database data)

---

## Components & Partials

### Reusable Components

**Principes:**
- Elk component is een partial
- Gebruik locals voor parameters
- Geen business logic in partials

**Voorbeeld:**
```erb
<!-- app/views/artworks/_card.html.erb -->
<div class="artwork-card">
  <% if artwork.file.attached? %>
    <%= image_tag artwork.file, class: "artwork-image" %>
  <% end %>

  <div class="artwork-info">
    <h3><%= artwork.title %></h3>
    <% if defined?(rank) && rank %>
      <div class="artwork-rank">#<%= rank %></div>
    <% end %>
  </div>
</div>

<!-- Gebruik: -->
<%= render 'artworks/card', artwork: @artwork, rank: 1 %>
```

### Flash Messages

**Gebruik in controller:**
```ruby
# Success
redirect_to exhibition_path, notice: "Voting completed successfully"

# Error
redirect_to comparison_path, alert: "Could not save comparison"

# Warning
flash[:warning] = "You need 26 comparisons to continue"
```

---

## JavaScript & Stimulus

### File Structure

```
app/javascript/
├── application.js
└── controllers/
    ├── comparison_controller.js
    ├── flash_controller.js
    └── dropdown_controller.js
```

### Stimulus Conventions

**Controller Naming:**
- File: `flash_controller.js`
- Data attribute: `data-controller="flash"`
- Class: `FlashController`

**Voorbeeld:**
```javascript
// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    console.log("Flash controller connected")
  }

  dismiss() {
    this.element.remove()
  }
}
```

**Gebruik in view:**
```erb
<div data-controller="flash" data-flash-target="message">
  <button data-action="click->flash#dismiss">×</button>
</div>
```

### JavaScript Best Practices

**❌ NOOIT HTML in JavaScript:**
```javascript
// ❌ Fout - geen HTML strings in JavaScript
export default class extends Controller {
  open() {
    const html = `
      <div class="modal">
        <h1>Title</h1>
      </div>
    `
    this.element.innerHTML = html
  }
}
```

**✅ Gebruik server-side rendering of hidden elements:**
```javascript
// ✅ Goed - manipuleer bestaande DOM elementen
export default class extends Controller {
  static targets = ["modal"]

  open() {
    this.modalTarget.classList.remove("hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
  }
}
```

```erb
<!-- Hidden modal in view, JavaScript toont/verbergt -->
<div data-controller="modal">
  <button data-action="modal#open">Open Modal</button>

  <div data-modal-target="modal" class="hidden">
    <div class="modal-content">
      <h1>Modal Title</h1>
      <button data-action="modal#close">Close</button>
    </div>
  </div>
</div>
```

**Voordelen:**
- HTML blijft in ERB templates (maintainability)
- Server-side rendering (SEO, accessibility)
- Geen duplicatie van HTML structuur

### Delete Confirmation Modal Pattern

**ALTIJD custom modal - NOOIT native browser confirms**

The Continuum gebruikt ALTIJD custom styled modals voor alle delete confirmations. Native browser confirms (`data: { turbo_confirm }` of `data: { confirm }`) zijn **verboden** omdat ze:
- Niet te stylen zijn
- Niet passen bij het design
- Inconsistent zijn tussen browsers
- Beperkte controle over content

De admin layout bevat een globale delete modal (`shared/_delete_modal.html.erb`) die automatisch beschikbaar is op alle admin pagina's via `data-controller="modal"` op de `admin-wrapper` div.

---

#### ✅ CORRECT - Custom Modal met Data Attributes

**Trigger button (in je view):**
```erb
<button type="button"
        class="btn btn-danger"
        data-action="click->modal#open"
        data-modal-title="Delete Artwork"
        data-modal-body="<p>Are you sure you want to delete <strong><%= artwork.title %></strong>?</p><p class='text-danger'>This action cannot be undone.</p>"
        data-modal-url="<%= admin_exhibition_artwork_path(@exhibition, artwork) %>">
  Delete
</button>
```

**Let op:** Je hoeft `data-modal-method` NIET op te geven - de modal gebruikt altijd DELETE.

---

#### ❌ FOUT - Native Browser Confirms

**Gebruik DIT NOOIT:**
```erb
<!-- FOUT - native browser alert (lelijk, niet te stylen) -->
<%= button_to "Delete", path, method: :delete,
    data: { turbo_confirm: "Are you sure?" } %>

<!-- FOUT - oude Rails syntax -->
<%= button_to "Delete", path, method: :delete,
    data: { confirm: "Are you sure?" } %>

<!-- FOUT - link_to met confirm -->
<%= link_to "Delete", path, method: :delete,
    data: { turbo_method: :delete, turbo_confirm: "Sure?" } %>
```

**Data Attributes:**
- `data-modal-title` - Titel van de modal (bijv. "Delete Artwork")
- `data-modal-body` - HTML content voor de modal body (kan variabelen bevatten)
- `data-modal-url` - URL voor de delete actie
- `data-modal-method` - HTTP methode (meestal "delete")

---

#### ⚠️ KRITIEK: CSRF Token Handling

**De modal implementatie gebruikt een server-rendered HTML form met Rails helpers.**

**✅ CORRECT - Modal partial met server-rendered form:**
```erb
<!-- shared/_delete_modal.html.erb -->
<div class="modal-actions">
  <button type="button" data-action="click->modal#close" class="btn">Cancel</button>
  <form action="#" method="post" data-modal-target="form" class="inline-form">
    <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
    <%= hidden_field_tag :_method, 'delete' %>
    <%= submit_tag "Delete", class: "btn btn-danger" %>
  </form>
</div>
```

**✅ CORRECT - JavaScript update alleen de form action:**
```javascript
// app/javascript/controllers/modal_controller.js
static targets = ['container', 'title', 'body', 'form']

open(event) {
  const trigger = event.currentTarget
  const url = trigger.dataset.modalUrl

  // Update modal content
  this.titleTarget.textContent = trigger.dataset.modalTitle
  this.bodyTarget.innerHTML = trigger.dataset.modalBody

  // Update form action URL (NIET de hele form regenereren!)
  if (this.hasFormTarget && url) {
    this.formTarget.action = url
  }

  this.containerTarget.classList.remove('hidden')
}
```

**❌ FOUT - Genereer NOOIT forms met innerHTML:**
```javascript
// FOUT - Dit veroorzaakt CSRF token errors!
this.deleteButtonTarget.innerHTML = `
  <form action="${url}" method="post">
    <input type="hidden" name="authenticity_token" value="${csrfToken}">
    <input type="submit" value="Delete">
  </form>
`
```

**Waarom dit fout gaat:**
1. CSRF tokens die client-side worden toegevoegd kunnen stale/invalid zijn
2. Rails verwacht server-rendered authenticity tokens
3. `form_authenticity_token` is niet beschikbaar in JavaScript context
4. Meta tag CSRF token kan out-of-sync raken met sessie

**Waarom onze implementatie werkt:**
1. ✅ Form wordt server-side gerenderd met gewone HTML + Rails helpers
2. ✅ `form_authenticity_token` genereert CSRF token op server tijdens page render
3. ✅ Token is embedded in de HTML, altijd geldig en gesynchroniseerd met sessie
4. ✅ JavaScript update ALLEEN de form `action` URL, niet de token
5. ✅ Gewone POST submit (geen Turbo interference)

**Technische details:**
- `form_authenticity_token` = Rails helper die de CSRF token genereert op server
- `hidden_field_tag :_method, 'delete'` = Rails method spoofing voor DELETE request
- `data-modal-target="form"` = Stimulus target zodat JavaScript de form kan vinden
- Form action start als `"#"` en wordt dynamisch geüpdatet naar de juiste URL

---

#### 📋 Implementation Checklist

**Wanneer je een nieuwe delete button toevoegt:**

1. ✅ **Layout heeft modal controller**
   - Controleer dat de parent layout `data-controller="modal"` heeft
   - Admin pages: `_admin_layout.html.erb` heeft dit al op `.admin-wrapper`
   - Public pages: Voeg toe aan layout of specifieke view

2. ✅ **Modal partial is geïncludeerd**
   - Admin pages: `<%= render "shared/delete_modal" %>` staat al in `_admin_layout.html.erb`
   - Public pages: Include de partial in je layout

3. ✅ **Delete button gebruikt data attributes**
   ```erb
   <button type="button"
           class="btn btn-danger"
           data-action="click->modal#open"
           data-modal-title="Delete [Resource]"
           data-modal-body="<p>Are you sure...?</p>"
           data-modal-url="<%= resource_path(@resource) %>">
     Delete
   </button>
   ```

4. ✅ **Controller destroy action bestaat**
   - Route: `resources :artworks` (includes destroy)
   - Controller method: `def destroy ... end`
   - Redirect na delete: `redirect_to index_path, notice: "Deleted successfully"`

5. ✅ **Test de functionaliteit**
   - Hard refresh browser (Cmd+Shift+R)
   - Klik delete button → modal opent
   - Klik Delete in modal → resource wordt verwijderd
   - Geen CSRF errors

---

#### 🎨 Modal Body Best Practices:
- Gebruik `<strong>` voor resource naam
- Toon hoeveel gerelateerde items verwijderd worden
- Gebruik `class='text-danger'` voor waarschuwingen
- Vermeld "This action cannot be undone"

**Voorbeeld met conditionals:**
```erb
data-modal-body="<p>Delete <strong><%= @artist.name %></strong>?</p>
<% if @artworks.any? %>
  <p class='text-danger'>Warning: This artist has <%= @artworks.count %> artwork(s).</p>
<% else %>
  <p class='text-danger'>This action cannot be undone.</p>
<% end %>"
```

---

## Rails Conventions

### Controllers

**RESTful Actions Volgorde:**
```ruby
class ExhibitionsController < ApplicationController
  before_action :set_exhibition, only: [:show, :edit, :update, :destroy]

  def index
  end

  def show
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def set_exhibition
    @exhibition = Exhibition.find_by!(slug: params[:slug])
  end

  def exhibition_params
    params.require(:exhibition).permit(:title, :description)
  end
end
```

**Custom Actions:** Plaats na RESTful actions, voor `private`

### Strong Parameters

**Altijd permit specifieke attributes:**
```ruby
# ✅ Goed
def artwork_params
  params.require(:artwork).permit(:title, :description, :file)
end

# ❌ Fout
def artwork_params
  params.require(:artwork).permit!
end
```

### Redirects & Flash Messages

```ruby
# Success
redirect_to exhibition_path, notice: "Successfully saved"

# Error
redirect_to edit_exhibition_path, alert: "Something went wrong"
render :edit, status: :unprocessable_entity
```

### Query Optimization

**Gebruik includes voor N+1 queries:**
```ruby
# ✅ Goed
@exhibitions = Exhibition.includes(:artworks).all

# ❌ Fout (N+1)
@exhibitions = Exhibition.all
# Later in view: exhibition.artworks (extra query per exhibition)
```

---

## Database & Models

### Monetary Values

**Gebruik decimals met precision voor scores:**
```ruby
# ✅ Goed
add_column :artworks, :elo_score, :decimal, precision: 10, scale: 2, default: 1500.0

# Voor geld: gebruik integers (cents)
add_column :transactions, :amount_cents, :integer, default: 0
```

### Validations

**Volgorde:**
```ruby
class Artwork < ApplicationRecord
  # Associations
  belongs_to :exhibition
  has_many :comparisons

  # Validations
  validates :title, presence: true
  validates :elo_score, numericality: true

  # Callbacks
  before_save :normalize_title

  # Scopes
  scope :ranked, -> { order(elo_score: :desc) }

  # Instance methods
  def display_score
    elo_score.round
  end

  # Class methods
  def self.process_vote(winner_id, loser_id)
    # ...
  end

  private

  def normalize_title
    # ...
  end
end
```

### Enums

```ruby
# ✅ Goed: Symbol syntax (Rails 7+)
enum :status, [:upcoming, :active, :archived]

# In database: integer kolom
# In code: exhibition.active? exhibition.status = :archived
```

---

## Testing

### Test Structure

```ruby
require "test_helper"

class ArtworkTest < ActiveSupport::TestCase
  setup do
    @artwork = artworks(:one)
  end

  test "should be valid" do
    assert @artwork.valid?
  end

  test "title should be present" do
    @artwork.title = ""
    assert_not @artwork.valid?
  end
end
```

### Fixtures

**Locatie:** `test/fixtures/`

**Best Practices:**
- Minimale data voor tests
- Gebruik ERB voor dynamic content
- Readable names: `one`, `two`, `active_exhibition`

```yaml
# test/fixtures/exhibitions.yml
one:
  title: Test Exhibition
  slug: test-exhibition-1
  status: active
  start_date: 2024-12-01
  end_date: 2026-03-01
```

### Controller Tests

```ruby
test "should get index" do
  get exhibitions_path
  assert_response :success
end

test "should create comparison" do
  assert_difference("Comparison.count") do
    post compare_exhibition_path(@exhibition), params: {
      winning_artwork_id: @artwork1.id,
      losing_artwork_id: @artwork2.id
    }
  end
end
```

---

## Security

### Security Checklist

**Voor elke PR/commit:**
- [ ] No secrets in code
- [ ] Strong parameters gebruikt
- [ ] Authorization checks aanwezig
- [ ] SQL injection prevention
- [ ] XSS prevention (auto-escaped ERB)
- [ ] CSRF tokens actief

### Common Patterns

**Authorization:**
```ruby
# In controller
def require_authentication
  unless Current.user
    redirect_to login_path, alert: "Please sign in"
  end
end
```

**SQL Injection Prevention:**
```ruby
# ✅ Goed
Artwork.where(title: params[:title])
Artwork.where("title = ?", params[:title])

# ❌ Fout
Artwork.where("title = '#{params[:title]}'")
```

---

## Git Workflow

### Branches

```
main          - Production code
feature/*     - New features
bugfix/*      - Bug fixes
hotfix/*      - Urgent production fixes
```

### Commit Messages

**Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat:` - Nieuwe feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `style:` - Code formatting
- `test:` - Tests toevoegen/updaten
- `docs:` - Documentatie
- `chore:` - Build/deps updates

**Voorbeeld:**
```
feat: Add personal Elo ranking system

Implemented dual Elo tracking for both global and personal rankings.

- Created voting_session_artwork_scores table
- Updated Comparison model to process both Elo scores
- Added personal rankings to exhibition show page

🤖 Generated with Claude Code
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Commit Checklist

Voor elke commit:
- [ ] Tests passeren (green)
- [ ] Code is formatted
- [ ] No console.logs/debuggers
- [ ] Commit message is descriptive

---

## App-Specific Styling

**Design System:** Zie `app/assets/stylesheets/continuum.css`

**Key Features:**
- Dark mode first (#000000 background, #ffffff text)
- Monospace typography (JetBrains Mono, Monaco, Courier)
- Minimalistic, uppercase headings
- Border-based design (no shadows)
- Grid layouts voor content

**Color Variables:**
```css
--color-bg: #000000
--color-text: #ffffff
--color-text-secondary: #a1a1a1
--color-border: #333333
```

**Typography:**
```css
--font-family: 'JetBrains Mono', 'Monaco', 'Courier New', monospace
--font-size-base: 14px
```

---

## Resources

### Documentation

- [Rails Guides](https://guides.rubyonrails.org/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/)
- [Hotwire](https://hotwired.dev/)

### Project Docs

- `README.md` - Project setup
- `STYLEGUIDE.md` - This document
- FundTogether Styleguide - Source material

---

**Vragen of suggesties?** Update deze styleguide via pull request.
