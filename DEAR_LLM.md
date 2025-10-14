# 🚨 IMPORTANT: Testing Instructions for AI Assistants

## ⚠️ CRITICAL REMINDER

**NEVER call `godot` directly when running tests in this repository!**

## ✅ CORRECT WAY TO RUN TESTS

Always use the project's test runner script:

```bash
./test-all.sh [test_type]
```

## 📋 Available Test Types

- `all` - Run all tests (default)
- `smoke` - Run quick smoke tests
- `hand` - Run hand evaluation tests
- `card` - Run card logic tests
- `state` - Run game state tests
- `sync` - Run multiplayer sync tests
- `bots` - Run bot AI tests

## 🔧 What the Script Does

The `test-all.sh` script calls `tests/run_tests.sh` which:

1. **Validates Godot installation** - Ensures Godot is available in PATH
2. **Runs tests with proper flags** - Uses `--headless --disable-render-loop`
3. **Provides colored output** - Clear success/failure indicators
4. **Includes timing** - Shows how long tests took to run
5. **Handles different test suites** - Can run specific test categories
6. **Proper error handling** - Exits with correct codes for CI/CD

## ❌ WRONG WAY (Don't Do This)

```bash
# ❌ NEVER DO THIS
godot --script tests/test_bots.gd --headless
godot --headless tests/test_scene.tscn
# ❌ Or any other direct godot calls
```

## 🎯 Why This Matters

- **Consistency**: All developers use the same testing approach
- **CI/CD Integration**: The script is designed for automated testing
- **Proper Setup**: Ensures correct Godot flags and environment
- **Error Reporting**: Better error messages and exit codes
- **Performance**: Optimized for headless testing

## 📝 Examples

```bash
# Run all tests
./test-all.sh

# Run specific test suite
./test-all.sh hand

# Run bot AI tests
./test-all.sh bots

# Run with verbose output
./test-all.sh --verbose all

# Run smoke tests only
./test-all.sh smoke
```

---

**Remember: `./test-all.sh` is your friend! Use it for all test runs! 🎮**
