# PlaceWell Design System
*Last updated: April 2026 — Phase 1 locked*

---

## Color Palette — Porcelain Sky

| Token | Value | Usage |
|---|---|---|
| `bgTop` | `#DDE6EC` | Gradient top — header area |
| `bgMid` | `#B8CFDA` | Gradient mid |
| `bgBot` | `#8AABBD` | Gradient bottom — footer area |
| `ink` | `#243040` | Primary text |
| `inkSoft` | `#4A6070` | Secondary text, subheadings |
| `inkMuted` | `#7A9AAA` | Placeholders, zone breadcrumbs |
| `amber` | `#C9A66B` | Primary accent — scan button, active states |
| `amberDim` | `rgba(201,166,107,0.18)` | Subtle amber fills |
| `glass` | `rgba(255,255,255,0.42)` | Frosted glass card surface |
| `glassBorder` | `rgba(255,255,255,0.62)` | Frosted glass card border |
| `glassTab` | `rgba(255,255,255,0.30)` | Tab bar surface |
| `glassTabBorder` | `rgba(255,255,255,0.50)` | Tab bar border |
| `terracotta` | `#C4785A` | Destructive actions |
| `white` | `#FFFFFF` | Pure white |

### Legacy tokens (kept for backward compat)
`chalk`, `sage`, `darkSage`, `stone` — unchanged from original brand.
These are used by Phase 2 screens not yet redesigned.

---

## Background Implementation

```js
// Always use LinearGradient as the root view — never a flat background
import { LinearGradient } from 'expo-linear-gradient';

<LinearGradient
  colors={[colors.bgTop, colors.bgMid, colors.bgBot]}
  style={{ flex: 1 }}
  start={{ x: 0, y: 0 }}
  end={{ x: 0, y: 1 }}
>
```

---

## Frosted Glass — No expo-blur

Simulated frosted glass works identically on iOS and Android.
Do NOT use expo-blur — it renders poorly on Android.

```js
// Room container / card
{
  backgroundColor: 'rgba(255,255,255,0.42)',
  borderWidth: 1,
  borderColor: 'rgba(255,255,255,0.62)',
  borderRadius: 20,
}

// Tab bar
{
  backgroundColor: 'rgba(255,255,255,0.30)',
  borderTopWidth: 1,
  borderTopColor: 'rgba(255,255,255,0.50)',
}
```

---

## Typography

| Token | Font | Usage |
|---|---|---|
| `fonts.display` | `CormorantGaramond_600SemiBold` | Screen titles, label names on detail |
| `fonts.displayLight` | `CormorantGaramond_400Regular` | Wordmark, room names (lighter weight) |
| `fonts.displayItalic` | `CormorantGaramond_600SemiBold_Italic` | Italic display text |
| `fonts.body` | `Jost_400Regular` | Body copy |
| `fonts.bodyMedium` | `Jost_500Medium` | Tile names, labels |
| `fonts.bodySemiBold` | `Jost_600SemiBold` | Buttons, strong labels |
| `fonts.mono` | `DMMono_400Regular` | Zone breadcrumbs, badges, tab labels, timestamps |
| `fonts.serifItalic` | `LibreBaskerville_400Regular_Italic` | Tagline, notes field, empty states |

### Wordmark
```
Place[italic W in amber]ell
```
- Font: `fonts.displayLight` (Cormorant Garamond 400 — NOT 600)
- Size: 38px
- Letter spacing: 0.5
- The W is italic and in `colors.amber` (#C9A66B)
- Tagline below in `fonts.serifItalic`, 11px, `colors.inkMuted`

---

## Spacing & Radius

```js
spacing = { xs:4, sm:8, md:16, lg:24, xl:32, xxl:48 }
radius  = { sm:6, md:10, lg:16, xl:20, full:999 }
```

---

## Navigation Structure

```
NavigationContainer
  └── RootStack (headerShown: false)
        ├── Main → TabNavigator (frosted glass tab bar, position:absolute)
        │     ├── HomeTab → HomeScreen
        │     ├── ScanTab → intercepted → navigates to Scanner
        │     └── SearchTab → SearchScreen
        ├── Scanner      (fade animation, gestureEnabled:false)
        ├── LabelSetup   → LabelFormScreen { mode:'create' }
        ├── LabelDetail  → LabelDetailScreen
        ├── LabelEdit    → LabelFormScreen { mode:'edit' }
        └── Settings     → SettingsScreen
```

---

## Home Screen Layout

```
LinearGradient (root)
  ├── Header (paddingTop: insets.top + 16)
  │     ├── Wordmark block (PlaceWell + tagline)
  │     └── Header actions (Lucide Search + Settings icons)
  ├── Header rule (1px, rgba(36,48,64,0.15))
  └── ScrollView
        └── RoomSection × N (staggered fade-up, 80ms delay each)
              └── Frosted glass container
                    ├── Room name (Cormorant 400, 22px)
                    └── 2-column tile grid
                          └── LabelTile × N
                                ├── Square photo (aspect:1, radius:16)
                                ├── Item count badge (dark pill, hidden if 0)
                                ├── Label name (Jost 500, 13px)
                                └── Zone (DM Mono 8.5px uppercase muted)
```

---

## Scan Button (Tab Bar)

- Shape: circular pill, 58×58
- Color: `#C9A66B` (amber)
- Icon: Lucide `QrCode`, white, size 24
- Shadow: `shadowColor: #C9A66B`, opacity 0.55, radius 10
- Border: 3px, `rgba(221,230,236,0.7)` (blends into gradient)
- Raised: `marginTop: -20` above tab bar
- Label: "SCAN" in DM Mono, amber colored

---

## Installed Packages (as of Phase 1)

```
expo-linear-gradient
@react-navigation/bottom-tabs
lucide-react-native
@expo-google-fonts/cormorant-garamond
@expo-google-fonts/jost
@expo-google-fonts/dm-mono
@expo-google-fonts/libre-baskerville
```

---

## Phase Status

| Phase | Status | Scope |
|---|---|---|
| Phase 1 | ✅ Code written | theme, AppNavigator, HomeScreen, RoomSection, LabelCard |
| Phase 2 | 🔲 Pending confirmation | LabelDetailScreen, LabelFormScreen, SearchScreen, SettingsScreen |
| Phase 3 | 🔲 Pending | Haptics, skeleton loaders, pull-to-refresh, onboarding |

---

## Cross-Platform Rules (always apply)

- Use `useSafeAreaInsets` on all screens — no hardcoded paddingTop
- `Platform.OS` checks for `textAlignVertical` (Android only) and `KeyboardAvoidingView` behavior
- `overflow: 'hidden'` for dashed borders on Android
- Never use `expo-blur` — use rgba simulation instead
- Tab bar `position: 'absolute'` — all scrollable content needs `paddingBottom` to clear it
- `TAB_BAR_HEIGHT = 64` + `insets.bottom` for scroll padding

---

## What NOT to Change Without Discussion

- The amber accent color — it was deliberately chosen after extensive palette exploration
- The frosted glass approach — expo-blur was explicitly rejected for Android compatibility
- The Porcelain Sky gradient — chosen after comparing 8+ palette options over multiple sessions
- The wordmark weight — must stay at 400 (displayLight), not 600 (display)
