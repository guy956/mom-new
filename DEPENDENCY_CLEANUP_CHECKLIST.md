# Dependency Cleanup Checklist

## Immediate Actions (Do First)

### 1. Remove Unused Dependencies ⚠️ CRITICAL
These packages are NOT used anywhere in the codebase:

```bash
# Remove from pubspec.yaml:
- shimmer: ^3.0.0
- flutter_staggered_grid_view: ^0.7.0
- go_router: ^15.1.2
- path_provider: ^2.1.5
- flutter_local_notifications: ^19.0.0
- uuid: ^4.5.1
- pdf: ^3.10.8
- printing: ^5.13.4
- csv: ^6.0.0
- animations: ^2.0.11
- lottie: ^3.3.1
```

**Expected Savings:** ~1.7 MB app size reduction (20%)

### 2. Update Security Packages 🔒 CRITICAL

```yaml
# In pubspec.yaml, update:
flutter_secure_storage: ^10.0.0  # was ^9.2.4
flutter_dotenv: ^6.0.0           # was ^5.2.1
```

### 3. Update Dev Dependencies

```yaml
flutter_lints: ^6.0.0  # was ^5.0.0
```

## Short Term (This Month)

### 4. Update Firebase Packages 🔥 CRITICAL

**IMPORTANT:** Review migration guides first!

```yaml
# Current (OUTDATED):
firebase_core: 3.6.0
firebase_auth: 5.3.1
google_sign_in: 6.2.2
cloud_firestore: 5.4.3
firebase_storage: 12.3.2

# Update to:
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
google_sign_in: ^7.2.0
cloud_firestore: ^6.1.2
firebase_storage: ^13.0.6
```

**Migration Steps:**
1. Read Firebase migration docs for each package
2. Update one package at a time
3. Test authentication flows after each update
4. Update Firestore queries if API changed
5. Test on both iOS and Android

## Medium Term (This Quarter)

### 5. Update UI Packages

```yaml
google_fonts: ^8.0.2     # was ^6.2.1
fl_chart: ^1.1.1         # was ^0.70.2
file_picker: ^10.3.10    # was ^8.1.6
```

### 6. Minor Version Updates

```yaml
shared_preferences: ^2.5.4  # was ^2.5.3
flutter_svg: ^2.2.3         # was ^2.0.17
```

## Testing Checklist After Each Update

- [ ] Run `flutter pub get`
- [ ] Run `flutter clean`
- [ ] Run `flutter build apk --debug` (Android)
- [ ] Run `flutter build ios --debug` (iOS)
- [ ] Test authentication flows
- [ ] Test Firestore operations
- [ ] Test file uploads (if using Firebase Storage)
- [ ] Run existing tests: `flutter test`
- [ ] Manual smoke test on real device

## Commands to Run

```bash
# 1. Remove unused dependencies from pubspec.yaml manually
# Then:
flutter pub get
flutter clean

# 2. Update security packages
flutter pub upgrade flutter_secure_storage flutter_dotenv

# 3. Update dev dependencies  
flutter pub upgrade flutter_lints

# 4. Update Firebase (one at a time, test between each)
# Edit pubspec.yaml manually, then:
flutter pub get
flutter test

# 5. Check for any issues
flutter analyze

# 6. Build and test
flutter build apk --debug
```

## Risk Mitigation

1. **Backup before major changes:**
   ```bash
   git add .
   git commit -m "Pre-dependency-update backup"
   ```

2. **Update in branches:**
   ```bash
   git checkout -b deps/remove-unused
   git checkout -b deps/update-firebase
   ```

3. **Test thoroughly:**
   - Run automated tests
   - Manual testing on real devices
   - Test critical user flows

## Success Criteria

- [ ] All unused dependencies removed
- [ ] App size reduced by ~1.7 MB
- [ ] Security packages updated
- [ ] Firebase packages updated to latest
- [ ] All tests passing
- [ ] No new errors in `flutter analyze`
- [ ] App builds successfully on iOS and Android
- [ ] Authentication works
- [ ] Firestore reads/writes work
- [ ] File uploads work (if applicable)

## Timeline

- **Week 1:** Remove unused deps, update security packages
- **Week 2-3:** Update Firebase packages (with testing)
- **Week 4:** Update UI packages, final testing

## Notes

- Firebase packages are LOCKED (no caret) - this is intentional but dangerous
- JWT secrets in .env are properly gitignored ✅
- Total dependencies: 39 → 29 after cleanup
- Estimated effort: 3-5 days with thorough testing
