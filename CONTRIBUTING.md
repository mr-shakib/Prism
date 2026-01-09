# Contributing to Prism

Thank you for considering contributing to Prism! This document outlines the process and guidelines.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## Code of Conduct

### Our Pledge
We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

## Getting Started

### Prerequisites
- Flutter SDK 3.24.0 or higher
- Dart 3.0 or higher
- Android Studio / VS Code
- Git

### Setup
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Prism.git
   cd Prism
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/Prism.git
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Set up Firebase (see PROFESSIONAL_UPGRADE_GUIDE.md)
6. Run the app:
   ```bash
   flutter run
   ```

## Development Workflow

### Branch Naming Convention
```
feature/feature-name        # New feature
bugfix/bug-description      # Bug fix
hotfix/critical-fix         # Urgent production fix
refactor/refactor-name      # Code refactoring
docs/documentation-update   # Documentation changes
test/test-description       # Adding tests
```

### Commit Message Format
Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```bash
feat(auth): add biometric authentication

Implemented fingerprint and face ID authentication using local_auth package.
Added fallback to PIN code authentication.

Closes #123

---

fix(posts): resolve infinite scroll pagination bug

Fixed issue where posts would reload unnecessarily when reaching end of list.

Fixes #456
```

### Development Process

1. **Create a branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Write clean, documented code
   - Follow the coding standards (see below)
   - Write tests for new features

3. **Test your changes:**
   ```bash
   flutter test
   flutter analyze
   dart format .
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

5. **Keep your fork updated:**
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

6. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**

## Coding Standards

### Dart Style Guide
Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

### File Organization
```dart
// 1. Imports (grouped and sorted)
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:third_party_package/file.dart';

import 'package:prism/core/utils/helpers.dart';
import 'package:prism/features/auth/domain/entities/user.dart';

// 2. Constants
const kAnimationDuration = Duration(milliseconds: 300);

// 3. Class definition
class MyWidget extends StatelessWidget {
  // 4. Static members
  static const routeName = '/my-widget';
  
  // 5. Instance variables (final first)
  final String title;
  final VoidCallback? onPressed;
  
  // 6. Constructor
  const MyWidget({
    Key? key,
    required this.title,
    this.onPressed,
  }) : super(key: key);
  
  // 7. Lifecycle methods / build
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // 8. Other methods
  void _handleTap() {
    // Implementation
  }
}
```

### Naming Conventions
- **Classes/Types**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `lowerCamelCase` or `kPascalCase` for UI constants
- **Private members**: Prefix with `_`
- **File names**: `snake_case.dart`

### Documentation
```dart
/// A brief description of what this class does.
///
/// A more detailed explanation can go here.
/// It can span multiple lines.
///
/// Example:
/// ```dart
/// final service = MyService();
/// final result = await service.doSomething();
/// ```
class MyService {
  /// Does something important.
  ///
  /// The [parameter] is used for...
  /// 
  /// Throws [CustomException] if...
  Future<Result> doSomething(String parameter) async {
    // Implementation
  }
}
```

### Widget Guidelines
1. **Keep widgets small and focused**
2. **Extract reusable widgets**
3. **Use `const` constructors when possible**
4. **Prefer composition over inheritance**

```dart
// Bad
class LargeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 100+ lines of widget tree
      ],
    );
  }
}

// Good
class LargeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderSection(),
        const _ContentSection(),
        const _FooterSection(),
      ],
    );
  }
}
```

### State Management
- Use **BLoC pattern** for business logic
- Keep business logic out of widgets
- Use dependency injection

```dart
// Good
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // UI based on state
      },
    );
  }
}
```

### Error Handling
```dart
// Use Either for domain layer
Future<Either<Failure, User>> login(String email, String password) async {
  try {
    final user = await remoteDataSource.login(email, password);
    return Right(user);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}

// Use try-catch in presentation layer
void _handleLogin() async {
  try {
    final result = await authService.login(email, password);
    // Handle success
  } catch (e) {
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
```

### Testing Requirements
- **Unit tests**: For business logic, use cases, repositories
- **Widget tests**: For UI components
- **Integration tests**: For critical user flows

```dart
// Example unit test
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    test('should return User on successful login', () async {
      // Arrange
      final user = User(id: '1', email: 'test@test.com');
      when(mockRepository.login(any, any))
          .thenAnswer((_) async => Right(user));

      // Act
      final result = await useCase('test@test.com', 'password');

      // Assert
      expect(result, Right(user));
    });
  });
}
```

## Pull Request Process

### Before Submitting
- [ ] Code follows the style guidelines
- [ ] Self-review completed
- [ ] Comments added to complex code
- [ ] Documentation updated
- [ ] Tests added/updated and passing
- [ ] No new warnings
- [ ] Tested on Android and iOS (if applicable)

### PR Title Format
```
<type>(<scope>): <description>

Example:
feat(auth): add biometric authentication support
```

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe the tests you ran

## Screenshots (if applicable)
Before | After
--|--
Screenshot | Screenshot

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests
- [ ] All tests pass locally
- [ ] I have tested on Android/iOS

## Related Issues
Closes #123
Related to #456
```

### Review Process
1. Two approvals required for merging
2. All CI checks must pass
3. No merge conflicts
4. Up-to-date with base branch

## Reporting Bugs

### Before Submitting
- Check existing issues
- Use the latest version
- Isolate the problem

### Bug Report Template
```markdown
**Describe the bug**
A clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen

**Screenshots**
If applicable

**Environment:**
- OS: [e.g., Android 12]
- Flutter version: [e.g., 3.24.0]
- App version: [e.g., 1.0.0]

**Additional context**
Any other context
```

## Suggesting Features

### Feature Request Template
```markdown
**Is your feature request related to a problem?**
A clear description

**Describe the solution you'd like**
What you want to happen

**Describe alternatives you've considered**
Other solutions you've thought about

**Additional context**
Mockups, examples, etc.
```

## Questions?

- Open a discussion on GitHub
- Email: dev@yourapp.com
- Discord: [Your Discord Server]

## License

By contributing, you agree that your contributions will be licensed under the project's MIT License.

---

Thank you for contributing to Prism! 🚀
