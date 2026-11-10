# Made You Look

SwiftUI iOS app (iOS 18+) built from the Group 23 INF 151 Figma prototype.
"Beauty, made personal": a short quiz personalizes product and look recommendations.

## Run

1. Open `MadeYouLook.xcodeproj` in Xcode.
2. Choose an iPhone simulator and press ⌘R.

Everything runs on the device. A built-in catalog supplies products (`MadeYouLook/Data/products.json`) and looks, and your data
(quiz answers, saved items, bag, settings) is stored in `UserDefaults`. Sign-in is mocked:

- **Get Started** → quiz → *You're all set* → Google / Apple / email create a local profile.
- **Sign In** resumes the saved account, or loads the demo account from the prototype (Asmitha) if there is none.
- **Settings → Logout** clears everything and returns to the welcome screen.

## Screens (Figma frame → file)

| Figma frame | File |
|---|---|
| Initial Launch | `Onboarding/WelcomeView.swift` |
| Onboarding 1–5 | `Onboarding/OnboardingFlow.swift`, `Onboarding/QuizPickers.swift` |
| Onboarding 6 (You're all set) | `Onboarding/AllSetView.swift` |
| Homepage | `Home/HomeView.swift` (plus search, filters, notifications) |
| Personalized Recs (list) | `Home/RecommendationsView.swift` |
| Personalized Recs (product) | `Home/ProductDetailView.swift` |
| Personalized Recs (Makeup Looks) | `Explore/ExploreView.swift` (includes look detail) |
| Saved | `Saved/SavedView.swift` |
| Profile | `Profile/ProfileView.swift` |
| Profile (Settings) | `Profile/SettingsView.swift` |
| In my bag / My products / Recent | `Home/BagView.swift` |

## Adding the Figma images

Any image that's missing shows a soft gradient placeholder, so the app works without them.
To use the real photos:

1. In Figma, select an image layer, then in the right panel choose **Export → PNG (2x)**.
2. Name the file using one of the names below and save it in `FigmaExports/`.
3. Run `scripts/import_figma_images.sh`, then rebuild.

| Name | Where it's used |
|---|---|
| `splash_bg` | Welcome screen background |
| `bg_silk` | Optional silk texture behind all screens |
| `hero_products` | Home "Products made for you" banner |
| `goal_find_makeup`, `goal_inspiration`, `goal_learn_looks`, `goal_discover` | Quiz step 1 |
| `tone_fair`, `tone_light`, `tone_light_medium`, `tone_tan`, `tone_deep`, `tone_deep_dark` | Quiz step 2 |
| `style_natural`, `style_bronzy`, `style_soft_glam`, `style_full_glam`, `style_dark`, `style_light` | Quiz step 3 |
| `product_rare_soft_pinch`, `product_elf_halo_glow`, `product_mario_surrealskin`, `product_ct_lip_cheat` | Products shown in the Figma |
| `product_nars_concealer`, `product_fenty_gloss_bomb`, `product_benefit_hoola`, `product_maybelline_sky_high`, `product_huda_palette`, `product_glossier_cloud_paint`, `product_laura_mercier_powder`, `product_lrp_tinted_spf` | Extra catalog products (optional) |
| `look_everyday_natural`, `look_bronzed_summer`, `look_everyday_glow`, `look_date_night` | Looks shown in the Figma |
| `look_smoky_night`, `look_soft_glam_brunch`, `look_clean_girl`, `look_sunset_bronze` | Extra looks (optional) |

Product detail galleries also pick up `<product image>_2` and `<product image>_3` if they exist.

## Product catalog

`MadeYouLook/Data/products.json` holds 60 products (15 each for Face, Cheeks, Eyes, Lips).
Prices, ratings, review counts, shade names, swatch colors and packshots were collected from
Sephora and Ulta product pages on 2026-10-31; each entry's `source` links to its page.

To add a product by hand, append an entry to `products.json`. Required fields are `id`, `brand`,
`name`, `category` (`face`/`cheeks`/`eyes`/`lips`) and `price`. The other fields are optional:
`cardName`, `rating`, `reviewCount`, `shades` (`name`, `detail`, `hex`, optional `tone`),
`concerns`, `styles`, `details`, `howToUse` and `imageName`. Put a matching image in Assets.xcassets.

To regenerate the catalog from freshly collected retailer data, run `scripts/build_catalog.py`
(see the docstring), then `scripts/import_figma_images.sh ProductImages`.

## Personalization

Recommendations are driven by `MadeYouLook/Data/research.json` (rules, shade guides and cited sources)
and `MadeYouLook/Models/Personalization.swift` (scoring). Quiz answers (skin type, concerns, skin tone,
budget, preferred looks) are matched against each product's formula `attributes` in `products.json`,
which `scripts/tag_attributes.py` derives from the Sephora/Ulta descriptions. Each card shows the top
reason; Product Detail lists all reasons. The research write-up with sources is in the app under
Settings → How Recommendations Work.
