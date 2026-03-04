# Orbit — Full Feature Roadmap

> Space-themed habit tracker for macOS. A living, growing universe that reflects your real life progress.

---

## Core Concept: The Living Solar System

The central metaphor of Orbit is that your habits form a solar system:

- **Sun** = You (the center of your universe)
- **Planets** = Categories (Health, Mind, Productivity, Creative, etc.)
- **Moons** = Individual habits orbiting their category planet
- **Orbital Paths** = Routines that connect habits across planets
- **Rings** = Streaks (Saturn-style rings grow with longer streaks)

### Planet Evolution

As your completion rate in a category increases, its planet transforms:

| Stage | Completion | Visual |
|-------|-----------|--------|
| Barren | 0% | Small, dark, lifeless rock |
| Sprouting | 25% | Slightly bigger, first signs of color |
| Thriving | 50% | Lush, detailed, mid-size |
| Flourishing | 75% | Vibrant, large, rich detail |
| Legendary | 100% | Massive, glowing, fully alive |

### Moon States

- **Completed today** = bright, glowing moon
- **Not completed** = dim/dark moon
- **Important habits** = larger moons
- Moons animate along orbital paths around their planet

### Streak Rings

Long streaks give planets Saturn-style rings:

- 7-day streak = thin ring
- 30-day streak = thick rings
- 100-day streak = gorgeous multi-ring system

### Zoom Interaction

Three levels of zoom with smooth camera animation:

1. **Solar System** (default) — all category planets orbiting the sun
2. **Planet View** (click planet or category) — zooms to planet, see all habit moons
3. **Moon View** (click habit/moon) — zooms in further, selected moon pulses/glows, stats popover appears

Clicking a habit from anywhere in the app (sidebar, card, moon) triggers the zoom animation to that planet + highlights the moon.

---

## Phase 1: Routines & Categories

The most immediate feature set — transforming Orbit from a flat habit list into a structured system.

### 1.1 Categories (Planets)

- Add `Category` model with name, color, SF Symbol icon
- Default categories: Health, Mind, Productivity, Creative, Social
- Users can create/edit/delete custom categories
- Each category renders as a planet in the orbital view
- Planet color matches category color from the existing theme palette

### 1.2 Morning / Night Routines

- Routines are a first-class concept, separate from individual habits
- A routine is an **ordered sequence of steps** (habits) to do in a specific order
- Routine types: Morning, Night, Custom
- Each routine has a name, icon, scheduled days (M/T/W/Th/F/Sa/Su), and time window

### 1.3 Ordered Step Checklists

- Routines display as a checklist with steps in defined order
- Steps can be reordered via drag-and-drop
- Each step can be a linked habit (completes the habit when checked) or a routine-only step
- Visual progress bar as you work through steps

### 1.4 Time Estimates

- Each routine step can have an optional time estimate (e.g., "5 min")
- Routine shows total estimated time ("~25 min")
- Helps users plan their mornings/evenings realistically

### 1.5 Routine Timer / Focus Mode

- Optional focus mode that walks you through each step
- Minimal UI: current step name, timer, next step preview
- Auto-advances or waits for manual check-off (configurable)
- Completion celebration animation when routine is finished

### 1.6 Flexible Scheduling

- Habits can be assigned to specific days (M/W/F, weekdays only, etc.)
- "Today" view only shows habits scheduled for the current day
- Routines can have different schedules (morning routine weekdays, different one weekends)

### 1.7 Habit Categories & Tags

- Every habit belongs to one category (planet)
- Optional tags for cross-cutting organization (e.g., #quick, #important)
- Filter/sort by category or tag

---

## Phase 2: Visualizations

Lean into the space theme with richer data visualization.

### 2.1 Long-term Trend Charts

- 30/60/90-day completion rate line charts
- Per-habit and per-category trend views
- Halftone-styled chart rendering to match the aesthetic

### 2.2 Streak Heatmap Calendar

- GitHub-style contribution heatmap but with halftone dots
- Dot size/brightness = number of habits completed that day
- Scrollable month-by-month view
- Per-habit and overall views

### 2.3 Habit Correlation Insights

- "You meditate more on days you exercise" style insights
- Simple correlation analysis between habit pairs
- Surfaced as cards on the dashboard

### 2.4 Achievement Animations

- Celebration animations for milestones (7-day streak, 100 completions, etc.)
- Halftone particle effects, planet glow bursts
- Brief and delightful, not intrusive

### 2.5 Constellation Progress Map

- As you build consistent habits, stars connect into constellations
- Each constellation represents a long-term goal or milestone
- Unlocks over time as a visual record of progress

### 2.6 Daily Score / Orbit Health

- Single score (0-100) representing today's overall progress
- Factors in: habits completed, streaks maintained, routines finished
- Displayed prominently on dashboard
- Historical score tracking

---

## Phase 3: Gamification

Make consistency addictive through rewards and progression.

### 3.1 XP System & Levels

- Earn XP for completing habits, maintaining streaks, finishing routines
- Level up with cumulative XP
- Level displayed on profile/dashboard
- XP bonuses for consistency (completing all habits in a day = multiplier)

### 3.2 Badges & Achievements

- Unlockable badges for milestones:
  - "Early Bird" — complete morning routine 7 days straight
  - "Night Owl" — complete night routine 30 days straight
  - "Centurion" — 100-day streak on any habit
  - "Solar System" — have 5+ active category planets
  - "Full Moon" — complete every habit in a day
- Badge showcase view

### 3.3 Unlock New Planet Skins

- Leveling up or hitting milestones unlocks new planet visual styles
- Ice planet, lava planet, gas giant, ringed world, etc.
- Users can assign unlocked skins to their category planets
- Purely cosmetic reward for consistency

### 3.4 Streak Shields

- Earn streak shields through consistency (e.g., 30-day streak earns 1 shield)
- A shield lets you miss 1 day without breaking a streak
- Limited resource — adds strategy to habit maintenance
- Visual indicator when a shield is active

### 3.5 Growing Solar System

- Your solar system literally expands as you progress
- New visual elements unlock: asteroid belts, nebula backgrounds, space stations
- The app gets more visually rich the more you use it

### 3.6 Daily Challenges

- Optional daily challenge for bonus XP
- "Complete 3 habits before 9 AM"
- "Maintain all streaks today"
- "Finish your morning routine in under 20 minutes"

---

## Phase 4: Platform & Data

Expand Orbit's reach and utility beyond the main Mac window.

### 4.1 iCloud Sync

- Sync habit data across devices via CloudKit
- Conflict resolution for simultaneous edits
- Offline-first with background sync

### 4.2 iOS Companion App

- iPhone/iPad app sharing the same SwiftUI views where possible
- Adapted layouts for mobile (no hover states, touch-friendly)
- Quick check-off interface for on-the-go tracking
- Simplified orbital view for smaller screens

### 4.3 macOS Menu Bar Widget

- Persistent menu bar icon showing today's progress (e.g., "4/7")
- Click to expand: quick check-off list without opening the full app
- Optional: tiny orbital system animation in the menu bar popover

### 4.4 Notifications & Reminders

- Configurable reminders per habit or routine
- Smart reminders: "You usually meditate at 7 AM, don't forget!"
- Morning summary notification: "You have 5 habits today"
- Evening reminder: "3 habits left to complete"

### 4.5 Data Export

- Export habit data as CSV or JSON
- PDF report generation (weekly/monthly summaries)
- Shareable streak/achievement images

### 4.6 Shortcuts & Automation

- macOS Shortcuts integration
- Actions: "Complete habit", "Start routine", "Get today's progress"
- Enables automations like auto-completing a habit when a workout app logs activity

---

## Phase 5: Social

Longer-term features for community and accountability.

### 5.1 Accountability Partners

- Invite a friend to see your streak status
- They see which habits you've completed (not the details, just status)
- Optional nudge notifications: "Your partner hasn't logged today"

### 5.2 Shared Habit Groups

- Create a group around a shared habit (e.g., "30-day meditation challenge")
- Group members see each other's progress
- Group streak: everyone completes it = group streak continues

### 5.3 Leaderboards & Challenges

- Opt-in leaderboards among friends or groups
- Weekly/monthly challenges with rankings
- Based on completion rate, not raw count (fairness)

### 5.4 Routine Template Sharing

- Share your morning routine as a template
- Browse community-submitted routine templates
- One-click import to add a template to your habits

---

## Implementation Priority

```
NOW        Phase 1.1  Categories (Planets)
           Phase 1.2  Morning / Night Routines
           Phase 1.3  Ordered Step Checklists
           Phase 1.7  Habit Categories & Tags

NEXT       Phase 1.4  Time Estimates
           Phase 1.5  Routine Timer / Focus Mode
           Phase 1.6  Flexible Scheduling
           Phase 2.1  Long-term Trend Charts
           Phase 2.2  Streak Heatmap Calendar
           Phase 2.6  Daily Score

LATER      Phase 2.3  Correlation Insights
           Phase 2.4  Achievement Animations
           Phase 2.5  Constellation Map
           Phase 3.x  Gamification (all)

FUTURE     Phase 4.x  Platform & Data (all)
           Phase 5.x  Social (all)
```

---

## Technical Notes

### Model Changes Needed

- New `Category` model: id, name, color, icon, sortOrder
- Add `categoryId` to `Habit` model
- New `Routine` model: id, name, type (morning/night/custom), steps, schedule
- New `RoutineStep` model: id, habitId (optional), name, timeEstimate, sortOrder
- Update `HabitStore` to manage categories and routines

### View Changes Needed

- Refactor `OrbitalSystemView`: planets = categories, moons = habits
- Add zoom state machine (solar system > planet > moon)
- Add stats popover overlay for selected habit/moon
- Add routine list/detail views
- Update `AddHabitSheet` with category picker
- Update sidebar with category grouping

### Data Migration

- Existing habits need a default category assignment on first launch after update
- Backward-compatible: old data format still loads, gets migrated automatically
