# Release Validation Checklist — App Store & Play Store

Last updated: 2026-04-21

- Ensure metro.config.js is committed (resolverMainFields: ['react-native','main']).
- Install required native deps (e.g., react-native-svg): `expo install react-native-svg`.
- Lock Expo SDK / React Native versions; confirm EAS support.
- Verify app.json: bundleIdentifier/package, icons, adaptiveIcon, splash, permissions, intentFilters, associatedDomains.
- Include iOS privacy strings (NSCameraUsageDescription, NSPhotoLibraryUsageDescription).
- Clear Metro cache and test dev flow: `npx expo start -c` + Expo Go on device.
- Test production builds via EAS or prebuild: `eas build --platform all` (or `expo prebuild` + native builds).
- Validate deep links/universal links and intent filters on devices.
- Verify fonts load, storage init, QR scan (camera), and all UX flows.
- Run final QA on physical Android and iOS devices; fix issues before submission.
- Commit and tag release; include changelog and release notes for stores.

Notes: EAS respects metro.config.js. If using a custom dev client or EAS builds, ensure the same metro config and native deps are used.