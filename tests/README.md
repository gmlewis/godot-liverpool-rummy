# Liverpool Rummy - Unit Test Suite

A comprehensive test suite for the Liverpool Rummy multiplayer card game, designed to help you find and fix bugs quickly without needing to manually play through the entire game.

## Overview

This test suite covers the core game logic including:

- **Hand Evaluation Logic** - Tests for card scoring, hand statistics, run/group detection, and melding logic
- **Card Logic** - Tests for card generation, manipulation, and validation
- **Game State Management** - Tests for player management, turn logic, and round progression
- **Multiplayer Synchronization** - Tests for bot management, network state, and sync logic

## Quick Start

### Running All Tests

```bash
# From the project root directory
godot --headless --script tests/run_tests.gd
```

### Running Individual Test Suites

```bash
# Test hand evaluation logic
godot --headless -s tests/test_hand_evaluation.gd

# Test card logic
godot --headless -s tests/test_card_logic.gd

# Test game state management
godot --headless -s tests/test_game_state.gd

# Test multiplayer sync
godot --headless -s tests/test_multiplayer_sync.gd
```

### Running Quick Smoke Tests

```bash
# Run just the critical tests for quick validation
godot --headless -s tests/test_runner.gd --quick
```

## Test Structure

### Test Framework (`test_framework.gd`)

A lightweight testing framework with:
- Assertion methods (`assert_equal`, `assert_true`, `assert_false`, etc.)
- Test lifecycle management
- Colored console output
- Test result tracking and reporting

### Test Suites

1. **Hand Evaluation Tests** (`test_hand_evaluation.gd`)
   - Card scoring and sorting
   - Hand statistics generation
   - Pre-meld evaluation (finding groups and runs)
   - Post-meld evaluation (finding public meld opportunities)
   - Run validation and bitmap logic
   - Joker handling

2. **Card Logic Tests** (`test_card_logic.gd`)
   - Card key generation and parsing
   - Deck size calculation based on player count
   - Card manipulation utilities
   - Joker-specific logic

3. **Game State Tests** (`test_game_state.gd`)
   - Game reset functionality
   - Player information management
   - Turn validation
   - Round requirements
   - Player melding status

4. **Multiplayer Sync Tests** (`test_multiplayer_sync.gd`)
   - Bot creation and management
   - Acknowledgment synchronization
   - Buy request tracking
   - Server/client state management
   - Player disconnection handling

## Debugging Tips

### Common Issues and Solutions

1. **Hand Evaluation Bugs**
   - Check `test_hand_evaluation.gd` for failing tests
   - Look for issues in `gen_hand_stats()` or `evaluate_hand()`
   - Verify run/group detection logic

2. **Card Logic Bugs**
   - Check `test_card_logic.gd` for failing tests
   - Verify card key generation and parsing
   - Check deck size calculations

3. **Game State Bugs**
   - Check `test_game_state.gd` for failing tests
   - Look for issues in player management or turn logic
   - Verify round progression

4. **Multiplayer Sync Issues**
   - Check `test_multiplayer_sync.gd` for failing tests
   - Look for issues in bot management or state synchronization
   - Verify buy request handling

### Running Tests During Development

```bash
# Run tests after making changes
godot --headless --script tests/run_tests.gd

# Run specific test suite if you're working on a particular area
godot --headless -s tests/test_hand_evaluation.gd

# Run smoke tests for quick validation
godot --headless -s tests/test_runner.gd --quick
```

### Test Output Interpretation

- **Green ✓**: Test passed
- **Red ✗**: Test failed with reason
- **Yellow**: Test suite headers and summaries

Example output:
```
=== Running Test Suite: Hand Evaluation Tests ===
  Running: test_card_key_score
  ✓ PASSED: test_card_key_score
  Running: test_sort_card_keys_by_score
  ✗ FAILED: test_sort_card_keys_by_score - Expected 'A-spades-0', got 'K-diamonds-0'
```

## Debugging Multiplayer Issues

### Common Multiplayer Problems

1. **Race Conditions**
   - Look for failed sync tests
   - Check `ack_sync_state` management
   - Verify proper ordering of RPC calls

2. **State Desynchronization**
   - Run game state tests to verify consistency
   - Check that `game_state` is properly synchronized
   - Verify private vs public information separation

3. **Bot Behavior Issues**
   - Check bot creation and management tests
   - Verify bot private information handling
   - Test bot decision-making logic

### Testing Multiple Instances

When running multiple game instances locally:

```bash
# Terminal 1 - Server
godot --server

# Terminal 2 - Client 1
godot --client1

# Terminal 3 - Client 2
godot --client2

# Terminal 4 - Client 3
godot --client3
```

Before testing multiplayer, run the unit tests to ensure core logic is working:

```bash
# Run tests first
godot --headless --script tests/run_tests.gd

# If tests pass, then test multiplayer
# If tests fail, fix the issues before multiplayer testing
```

## Adding New Tests

### Creating a New Test

1. Add your test function to the appropriate test suite
2. Use the assertion methods from `TestFramework`
3. Add the test to the `run_all_tests()` function
```

### Creating a New Test Suite

1. Create a new `.gd` file in the `tests/` directory
2. Follow the pattern of existing test suites
3. Add the new suite to `test_runner.gd`
```

## Performance Considerations

- Tests run in memory without UI rendering
- Total test execution time should be under 10 seconds
- Each test should complete in under 100ms
- Use mocking for complex dependencies

## CI/CD Integration

The test suite is designed to be run in continuous integration:

```bash
# Exit code 0 if all tests pass, non-zero if any fail
godot --headless --script tests/run_tests.gd
echo $?  # Check exit code
```

## Troubleshooting

### Common Issues

1. **"Class not found" errors**
   - Ensure all test files are in the `tests/` directory
   - Check that class names match file names
   - Verify `class_name` declarations

2. **Godot version compatibility**
   - Tests are designed for Godot 4.x
   - Some syntax may need adjustment for older versions

3. **Missing dependencies**
   - Ensure `global.gd` is in the project root
   - Check that all referenced classes exist

### Getting Help

- Check the test output for specific error messages
- Look at the failing test code to understand what's expected
- Use `Global.dbg()` to add debug output to your game logic
- Run individual test suites to isolate issues

## Best Practices

1. **Run tests frequently** - After any code change
2. **Write tests for new features** - Before implementing complex logic
3. **Keep tests simple** - Each test should verify one thing
4. **Use descriptive test names** - Make it clear what's being tested
5. **Add assertions with messages** - Help debug failing tests

## Future Enhancements

- Integration with Godot's built-in testing framework
- Performance benchmarking tests
- Visual regression testing for UI components
- Automated test generation from game scenarios
- Code coverage reporting
