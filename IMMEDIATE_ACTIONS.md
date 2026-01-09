# 🚨 IMMEDIATE SECURITY ACTIONS REQUIRED

## ⚠️ YOUR SECRETS ARE EXPOSED - ACT NOW!

If you've already pushed to GitHub with exposed secrets, follow these steps **IMMEDIATELY**:

---

## Step 1: Remove Sensitive Files from Git Tracking (DO THIS NOW!)

```bash
# Stop tracking firebase_options.dart
git rm --cached lib/firebase_options.dart

# Stop tracking google-services.json
git rm --cached android/app/google-services.json

# Stop tracking iOS GoogleService-Info.plist (if exists)
git rm --cached ios/Runner/GoogleService-Info.plist

# Commit the removal
git commit -m "chore: remove sensitive files from git tracking"

# Push the changes
git push origin main
```

## Step 2: Verify Your .gitignore Is Updated

✅ Already done! Your `.gitignore` has been updated to exclude:
- `lib/firebase_options.dart`
- `**/google-services.json`
- `**/GoogleService-Info.plist`
- `.env` files

## Step 3: Clean Git History (OPTIONAL but RECOMMENDED)

⚠️ **WARNING**: This rewrites Git history. Coordinate with team members first!

```bash
# Install git-filter-repo
pip install git-filter-repo

# Remove firebase_options.dart from entire history
git filter-repo --path lib/firebase_options.dart --invert-paths

# Remove google-services.json from entire history
git filter-repo --path android/app/google-services.json --invert-paths

# Force push to remote (DANGEROUS - make sure team is aware!)
git push origin --force --all
```

## Step 4: Rotate Your Firebase API Keys

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `prism-64e0f`
3. Navigate to **APIs & Services → Credentials**
4. Find your API keys
5. **Delete or regenerate** any exposed keys
6. Create new restricted keys with proper restrictions:
   - Set application restrictions (Android/iOS app)
   - Set API restrictions (only enable needed APIs)

## Step 5: Update Firebase Configuration

After rotating keys, regenerate your Firebase configuration:

```bash
# Make sure you're logged in
firebase login

# Regenerate configuration
flutterfire configure --project=prism-64e0f

# This will update firebase_options.dart with new keys
```

## Step 6: Set Up Environment-Based Configuration

1. **Create environment files:**
   ```bash
   # Copy the example file
   cp .env.example .env.dev
   
   # Fill in your actual values in .env.dev
   # NEVER commit this file!
   ```

2. **Update your app to use EnvConfig:**
   - The file `lib/core/config/env_config.dart` has been created
   - Update your `main.dart` to initialize it:
   
   ```dart
   import 'package:prism/core/config/env_config.dart';
   
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Load environment configuration
     await EnvConfig.initialize();
     
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     
     runApp(MyApp());
   }
   ```

## Step 7: Enable Firebase Security Features

### A. Set Up Firestore Security Rules

Go to Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    match /posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
                      request.resource.data.uid == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
                              resource.data.uid == request.auth.uid;
    }
  }
}
```

### B. Enable Firebase App Check

1. Go to Firebase Console → App Check
2. Click **Get Started**
3. Register your app
4. For Android: Enable Play Integrity
5. For iOS: Enable App Attest

## Step 8: Update Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Environment configuration
  flutter_dotenv: ^5.1.0
  
  # Secure storage
  flutter_secure_storage: ^9.0.0
  
  # App Check
  firebase_app_check: ^0.2.1+0
```

Then run:
```bash
flutter pub get
```

## Step 9: Verify Your Changes

Run this checklist:

```bash
# 1. Check if sensitive files are ignored
git status

# 2. Verify .gitignore is working
git add .
git status  # Should NOT show firebase_options.dart or google-services.json

# 3. Run the app to ensure everything works
flutter run

# 4. Check for any remaining secrets
git log --all --full-history --source -- '*firebase_options*'
```

## Step 10: Set Up Regular Security Checks

### A. Add Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh

# Check for potential secrets
if git diff --cached --name-only | xargs grep -E "AIza[0-9A-Za-z_-]{35}|sk_live_[0-9A-Za-z]+"; then
    echo "❌ ERROR: Potential API key detected!"
    echo "Please remove sensitive data before committing."
    exit 1
fi

# Run Flutter analyze
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Flutter analyze failed"
    exit 1
fi

echo "✅ Pre-commit checks passed"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### B. Enable GitHub Secret Scanning

If your repo is public:
1. Go to GitHub → Settings → Security
2. Enable **Secret scanning**
3. Enable **Push protection**

---

## ✅ Security Checklist

Mark these as you complete them:

- [ ] Removed sensitive files from git tracking
- [ ] Updated .gitignore
- [ ] Rotated exposed Firebase API keys
- [ ] Regenerated Firebase configuration with new keys
- [ ] Set up environment-based configuration
- [ ] Implemented Firebase security rules
- [ ] Enabled Firebase App Check
- [ ] Added flutter_secure_storage for sensitive data
- [ ] Set up pre-commit hooks
- [ ] Verified no secrets in current codebase
- [ ] (Optional) Cleaned git history of old secrets
- [ ] Enabled GitHub secret scanning

---

## 📚 Additional Resources

- [SECURITY_CHECKLIST.md](SECURITY_CHECKLIST.md) - Complete security guide
- [PROFESSIONAL_UPGRADE_GUIDE.md](PROFESSIONAL_UPGRADE_GUIDE.md) - Architecture improvements
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)

---

## 🆘 Need Help?

If you're unsure about any step:
1. **Don't panic** - follow the steps carefully
2. **Ask for help** - open a GitHub discussion
3. **Read the guides** - comprehensive docs are provided

## ⚡ Quick Commands Summary

```bash
# 1. Remove from tracking
git rm --cached lib/firebase_options.dart android/app/google-services.json
git commit -m "chore: remove sensitive files"
git push

# 2. Regenerate Firebase config
firebase login
flutterfire configure --project=prism-64e0f

# 3. Set up environment
cp .env.example .env.dev
# Edit .env.dev with your values

# 4. Install new dependencies
flutter pub get

# 5. Test everything
flutter run
```

---

**Remember**: Prevention is better than cure. Always review what you're committing!
