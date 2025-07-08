# Liverpool Rummy - Debugging Guide

A comprehensive guide for debugging multiplayer issues and game logic problems in Liverpool Rummy.

## Quick Debug Workflow

### 1. Run Tests First

**Always start with tests** before attempting multiplayer debugging:

```bash
# Run all tests
./tests/run_tests.sh

# If tests fail, focus on fixing core logic first
# If tests pass, proceed with multiplayer debugging
```

### 2. Isolate the Problem

```bash
# Test specific components
./tests/run_tests.sh hand     # Hand evaluation issues
./tests/run_tests.sh card     # Card manipulation issues  
./tests/run_tests.sh state    # Game state issues
./tests/run_tests.sh sync     # Multiplayer sync issues
```

### 3. Use Debug Helpers

Add debug output to your code:

```gdscript
# In your game code
var debug_helper = DebugHelper.new()
debug_helper.print_game_state(Global.game_state)
debug_helper.print_hand_evaluation(evaluation)
```

## Common Issues and Solutions

### Hand Evaluation Problems

**Symptoms:**
- Cards not melding correctly
- Wrong cards recommended for discard
- Evaluation scores seem incorrect

**Debug Steps:**
1. Run hand evaluation tests: `./tests/run_tests.sh hand`
2. Add debug output:
   ```gdscript
   var hand_stats = Global.gen_hand_stats(card_keys)
   DebugHelper.print_hand_stats(hand_stats)
   var evaluation = Global.evaluate_hand(hand_stats, player_id)
   DebugHelper.print_hand_evaluation(evaluation)
   ```
3. Check specific test cases that match your scenario

**Common Fixes:**
- Verify card key format (rank-suit-deck)
- Check joker handling in `gen_hand_stats()`
- Verify run/group detection logic
- Check round requirements in `_groups_per_round` and `_runs_per_round`

### Multiplayer Synchronization Issues

**Symptoms:**
- Players see different game states
- Actions not appearing for other players
- Game hanging or freezing
- "Waiting for sync" messages

**Debug Steps:**
1. Run sync tests: `./tests/run_tests.sh sync`
2. Check sync state: `DebugHelper.print_multiplayer_sync_state(Global.ack_sync_state)`
3. Verify game state consistency:
   ```gdscript
   var issues = DebugHelper.validate_game_state_consistency(Global.game_state)
   if len(issues) > 0:
       for issue in issues:
           print("CONSISTENCY ISSUE: " + issue)
   ```

**Common Fixes:**
- Ensure `register_ack_sync_state()` is called before RPC
- Verify `ack_sync_completed()` is called after animations
- Check that all clients receive and respond to RPCs
- Ensure server/client detection is correct

### Card Logic Problems

**Symptoms:**
- Wrong number of cards in deck
- Card keys not generating correctly
- Jokers not handled properly

**Debug Steps:**
1. Run card tests: `./tests/run_tests.sh card`
2. Verify card generation:
   ```gdscript
   print("Total decks: ", Global.get_total_num_card_decks())
   print("Total cards: ", Global.get_total_num_cards())
   print("Sample key: ", Global.gen_playing_card_key('A', 'hearts', 0))
   ```

### Game State Issues

**Symptoms:**
- Wrong player turn
- Incorrect round number
- Player information inconsistent

**Debug Steps:**
1. Run state tests: `./tests/run_tests.sh state`
2. Print game state: `DebugHelper.print_game_state(Global.game_state)`
3. Validate consistency: `DebugHelper.validate_game_state_consistency(Global.game_state)`

## Multiplayer Testing Setup

### Local 4-Instance Setup

```bash
# Terminal 1 - Server (upper right)
godot --server

# Terminal 2 - Client 1 (lower right)
godot --client1

# Terminal 3 - Client 2 (lower left)
godot --client2

# Terminal 4 - Client 3 (upper left)
godot --client3
```

### Debug Each Instance

In each instance, you can add debug output:

```gdscript
# Add to Global._ready() or state changes
func _debug_instance_state():
    var peer_id = multiplayer.get_unique_id()
    var is_server = multiplayer.is_server()
    print("[PEER %d] %s - Game State:" % [peer_id, "SERVER" if is_server else "CLIENT"])
    DebugHelper.print_game_state(game_state)
```

### Common Multiplayer Patterns

**Race Conditions:**
- Symptom: Intermittent failures, different behavior each run
- Solution: Add proper sync points with `register_ack_sync_state()`

**State Desync:**
- Symptom: Players see different information
- Solution: Ensure server is authoritative, validate state consistency

**RPC Ordering:**
- Symptom: Actions happen in wrong order
- Solution: Use reliable RPCs and proper sequencing

## Performance Debugging

### Identifying Slow Functions

```gdscript
# Benchmark critical functions
var benchmark = DebugHelper.benchmark_function(
    "evaluate_hand",
    func(): return Global.evaluate_hand(hand_stats, player_id),
    100  # iterations
)
print("Average time: %f ms" % (benchmark.avg_time * 1000))
```

### Memory Usage

```gdscript
# Check dictionary sizes
print("Playing cards: %d" % len(Global.playing_cards))
print("Stock pile: %d" % len(Global.stock_pile))
print("Discard pile: %d" % len(Global.discard_pile))
```

## Test-Driven Debugging

### Create Minimal Reproduction

1. **Create test scenario:**
   ```gdscript
   var test_game_state = DebugHelper.create_test_scenario("with_melds")
   var test_hand = DebugHelper.create_test_hand("winning_round1")
   ```

2. **Add specific test:**
   ```gdscript
   func test_my_bug_reproduction():
       # Set up the exact scenario that's failing
       global_instance.game_state = test_game_state
       var hand_stats = global_instance.gen_hand_stats(test_hand)
       var evaluation = global_instance.evaluate_hand(hand_stats, "player1")
       
       # Assert what should happen
       test_framework.assert_true(evaluation['is_winning_hand'], "Should be winning")
   ```

3. **Run the test:**
   ```bash
   # Add your test to the appropriate test suite and run
   ./tests/run_tests.sh hand
   ```

### Iterative Testing

1. **Write test for bug** (it should fail)
2. **Fix the code**
3. **Run test again** (it should pass)
4. **Run all tests** to ensure no regressions

## Advanced Debugging Techniques

### Mock Multiplayer Environment

```gdscript
# Create mock multiplayer state for testing
func setup_mock_multiplayer():
    # Mock server state
    Global.game_state = DebugHelper.create_test_scenario("basic_game")
    Global.private_player_info = {'id': '1', 'turn_index': 0}
    
    # Mock client connections
    Global.ack_sync_state = {}
```

### State Machine Debugging

```gdscript
# Add to state machine transitions
func _enter_state(new_state: String):
    Global.dbg("STATE TRANSITION: %s -> %s" % [current_state, new_state])
    DebugHelper.print_game_state(Global.game_state)
```

### Network Message Tracing

```gdscript
# Add to RPC functions
@rpc('authority', 'call_local', 'reliable')
func _rpc_some_action(param1, param2):
    var peer_id = multiplayer.get_remote_sender_id()
    Global.dbg("RPC RECEIVED: _rpc_some_action from peer %d" % peer_id)
    Global.dbg("  Params: %s, %s" % [str(param1), str(param2)])
    # ... rest of RPC function
```

## Automated Debugging

### Continuous Testing

```bash
# Watch for file changes and run tests automatically
while inotifywait -e modify global.gd; do
    echo "File changed, running tests..."
    ./tests/run_tests.sh smoke
done
```

### Integration with Development

1. **Pre-commit hook:**
   ```bash
   #!/bin/sh
   # In .git/hooks/pre-commit
   ./tests/run_tests.sh smoke
   if [ $? -ne 0 ]; then
       echo "Tests failed, commit aborted"
       exit 1
   fi
   ```

2. **IDE integration:**
   - Set up your IDE to run tests with a keyboard shortcut
   - Configure test output parsing for clickable error messages

## Common Error Messages and Solutions

### "Player not found in game_state"
- **Cause:** Player disconnected or ID mismatch
- **Fix:** Add null checks, handle disconnections properly

### "Invalid turn index"
- **Cause:** Turn advancement logic error
- **Fix:** Validate turn index in `validate_current_player_turn()`

### "Card key not found in playing_cards"
- **Cause:** Card generation or cleanup issue
- **Fix:** Verify card lifecycle, check `playing_cards` dictionary

### "Sync operation already registered"
- **Cause:** Multiple sync operations with same name
- **Fix:** Use unique operation names or clear previous operations

### "RPC call failed"
- **Cause:** Network issues or peer disconnection
- **Fix:** Add error handling, implement retry logic

## Best Practices

1. **Always test core logic first** before multiplayer
2. **Use descriptive debug messages** with player/peer IDs
3. **Add state validation** at key points
4. **Mock complex dependencies** in tests
5. **Keep test scenarios simple** and focused
6. **Run tests frequently** during development
7. **Use version control** to track working states

## Emergency Debugging

When things are completely broken:

1. **Reset to known good state:**
   ```bash
   git checkout HEAD~1  # Go back one commit
   ./tests/run_tests.sh  # Verify tests pass
   ```

2. **Bisect the problem:**
   ```bash
   git bisect start
   git bisect bad        # Current broken state
   git bisect good HEAD~10  # Known good state
   # Git will check out commits for you to test
   ```

3. **Create minimal reproduction:**
   - Remove all non-essential code
   - Focus on the exact failing scenario
   - Add comprehensive logging

Remember: **The tests are your safety net**. If tests pass but multiplayer fails, the issue is likely in the networking/UI layer, not the core game logic.
