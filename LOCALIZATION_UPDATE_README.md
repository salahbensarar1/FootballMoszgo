# Localization Update Guide

This branch contains updates to the coach_screen.dart file to use localized strings instead of hardcoded Hungarian text.

## Changes Made:

1. Updated training types to use localized strings through a getter method that references AppLocalizations
2. Created reference JSON files with missing localization strings that need to be added:
   - `missing_en_strings.json` - English translations
   - `missing_hu_strings.json` - Hungarian translations

## Implementation Steps:

To complete the localization process:

1. Add the strings from `missing_en_strings.json` to `lib/l10n/app_en.arb`
2. Add the strings from `missing_hu_strings.json` to `lib/l10n/app_hu.arb`
3. Update the following components to use localization instead of hardcoded strings:
   - Drawer section titles (Contact, Support)
   - Menu item titles (Phone Support, Email Support)
   - Menu item subtitles (Profil kezelése, Segítség és támogatás, Alkalmazás információ)

## Notes:

- The coach_screen.dart file has already been updated to use a localized approach for training type names
- Some sections are prepared but commented out until the localization strings are properly added to the ARB files
- Once the strings are added to the ARB files, the app will need to be rebuilt to generate the localization code
