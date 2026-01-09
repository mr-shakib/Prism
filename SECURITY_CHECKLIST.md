# Security Checklist for Prism

## ⚠️ IMMEDIATE ACTIONS REQUIRED

### 1. Remove Exposed Secrets from Git History
If you've already committed sensitive files, you need to remove them from Git history:

```bash
# Install git-filter-repo if not already installed
# Windows: pip install git-filter-repo

# Remove firebase_options.dart from all history
git filter-repo --path lib/firebase_options.dart --invert-paths

# Remove google-services.json from all history
git filter-repo --path android/app/google-services.json --invert-paths

# Force push (WARNING: Coordinate with team first!)
git push origin --force --all
```

**Alternative: If the repository is already public and compromised:**
1. Rotate ALL Firebase API keys in Firebase Console
2. Create a new Firebase project
3. Update all configurations
4. Consider making the repo private or starting fresh

### 2. Revoke Exposed API Keys

#### Firebase API Keys
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings → General
4. Under "Your apps" section, delete the compromised apps
5. Re-register your apps with new configurations
6. Set up API key restrictions:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to APIs & Services → Credentials
   - Click on your API key
   - Set application restrictions (Android/iOS app)
   - Set API restrictions (only enable required APIs)

### 3. Check What Was Exposed

Run this command to see what sensitive data might be in your commits:

```bash
# Search for API keys in git history
git log -p | grep -i "apikey\|api_key\|secret\|password\|firebase"

# Check what's currently tracked
git ls-files | grep -E "firebase_options|google-services|secrets"
```

### 4. Secure Current Setup

✅ **Completed:**
- [x] Updated .gitignore to exclude sensitive files

🔲 **To Do:**
- [ ] Remove firebase_options.dart from tracking
- [ ] Remove google-services.json from tracking
- [ ] Create environment-specific configurations
- [ ] Set up secure storage for runtime secrets
- [ ] Implement API key restrictions in Google Cloud
- [ ] Set up Firebase App Check
- [ ] Enable Firestore security rules

---

## Ongoing Security Best Practices

### A. Firebase Security Rules

#### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    // Posts collection
    match /posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
                      request.resource.data.uid == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
                              resource.data.uid == request.auth.uid;
    }
    
    // Comments collection
    match /posts/{postId}/comments/{commentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
                              resource.data.uid == request.auth.uid;
    }
  }
}
```

#### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /posts/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     request.resource.size < 5 * 1024 * 1024 && // 5MB limit
                     request.resource.contentType.matches('image/.*');
    }
    
    match /profiles/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     request.resource.size < 2 * 1024 * 1024; // 2MB limit
    }
  }
}
```

### B. Enable Firebase App Check

```dart
// In main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Enable App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity, // For production
    // androidProvider: AndroidProvider.debug, // For development
    appleProvider: AppleProvider.appAttest,
  );
  
  runApp(MyApp());
}
```

### C. Secure API Endpoints

If you add a backend API:

```dart
class ApiSecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token
    final token = await SecureStorage().getAuthToken();
    options.headers['Authorization'] = 'Bearer $token';
    
    // Add app signature
    options.headers['X-App-Signature'] = await _generateSignature();
    
    // Add request timestamp
    options.headers['X-Request-Time'] = DateTime.now().toIso8601String();
    
    handler.next(options);
  }
  
  Future<String> _generateSignature() async {
    // Implement request signing
    return 'signature';
  }
}
```

### D. Input Validation & Sanitization

```dart
class InputValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    return null;
  }
  
  static String sanitizeUserInput(String input) {
    // Remove HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove SQL injection attempts
    sanitized = sanitized.replaceAll(RegExp(r"[';\"--]"), '');
    
    // Limit length
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }
    
    return sanitized.trim();
  }
}
```

### E. Rate Limiting

```dart
class RateLimiter {
  final Map<String, List<DateTime>> _attempts = {};
  
  bool isAllowed(String userId, {int maxAttempts = 5, Duration window = const Duration(minutes: 15)}) {
    final now = DateTime.now();
    final attempts = _attempts[userId] ?? [];
    
    // Remove old attempts
    attempts.removeWhere((time) => now.difference(time) > window);
    
    if (attempts.length >= maxAttempts) {
      return false;
    }
    
    attempts.add(now);
    _attempts[userId] = attempts;
    return true;
  }
}
```

### F. Secure Data Storage

```dart
class SecureDataStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  Future<void> saveSecurely(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  Future<String?> readSecurely(String key) async {
    return await _storage.read(key: key);
  }
  
  Future<void> deleteSecurely(String key) async {
    await _storage.delete(key: key);
  }
  
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

### G. Encryption for Sensitive Data

```dart
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  late final Encrypter _encrypter;
  late final IV _iv;
  
  EncryptionService() {
    final key = Key.fromSecureRandom(32);
    _iv = IV.fromSecureRandom(16);
    _encrypter = Encrypter(AES(key));
  }
  
  String encrypt(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }
  
  String decrypt(String encrypted) {
    return _encrypter.decrypt64(encrypted, iv: _iv);
  }
}
```

---

## Security Monitoring

### A. Set Up Alerts

1. **Firebase Console Alerts:**
   - Budget alerts
   - Unusual activity alerts
   - Failed authentication attempts

2. **Crashlytics:**
   - Monitor for security-related crashes
   - Track suspicious patterns

3. **Analytics:**
   - Monitor for unusual user behavior
   - Track failed login attempts

### B. Regular Security Audits

**Monthly:**
- [ ] Review Firebase security rules
- [ ] Check for exposed secrets in recent commits
- [ ] Review user access logs
- [ ] Update dependencies with security patches

**Quarterly:**
- [ ] Full security audit
- [ ] Penetration testing
- [ ] Review and rotate API keys
- [ ] Update privacy policy

---

## Compliance & Legal

### A. GDPR Compliance (if serving EU users)
- [ ] Add privacy policy
- [ ] Implement data export feature
- [ ] Implement account deletion
- [ ] Add cookie consent
- [ ] Data retention policies

### B. COPPA Compliance (if allowing users under 13)
- [ ] Age verification
- [ ] Parental consent
- [ ] Limited data collection

### C. App Store Requirements
- [ ] Privacy manifest (iOS)
- [ ] Data safety section (Android)
- [ ] Terms of service
- [ ] Privacy policy URL

---

## Emergency Response Plan

### If Your App Is Compromised:

1. **Immediate Actions:**
   - Disable affected Firebase project/services
   - Rotate all API keys and secrets
   - Force logout all users
   - Take app offline if necessary

2. **Investigation:**
   - Check Firebase logs
   - Review authentication logs
   - Identify the breach source

3. **Recovery:**
   - Patch vulnerabilities
   - Restore from secure backup
   - Notify affected users (if required by law)

4. **Prevention:**
   - Implement additional security measures
   - Update security documentation
   - Train team on security best practices

---

## Contact & Support

For security issues:
- Email: security@yourapp.com (create this)
- Response time: Within 24 hours
- Bug bounty program: Consider setting up

## Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Firebase Security Checklist](https://firebase.google.com/docs/rules/security-checklist)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
