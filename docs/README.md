# Liverpool Rummy Documentation

Welcome to the technical documentation for Liverpool Rummy! This documentation is intended for developers who want to understand, maintain, or contribute to the codebase.

## Architecture Documentation

### [Multiplayer Architecture](multiplayer-architecture.md)
Comprehensive guide to the networking system, including:
- UDP discovery and automatic host detection
- Client-server architecture and connection management
- Game state synchronization
- Preventing late joins to already-started games
- RPC functions and network protocols
- Testing and troubleshooting multiplayer features

### [Game State Machine](game-state-machine.md)
Complete overview of the game flow, including:
- State machine architecture and transitions
- All 9 game states from title screen to final scores
- Round progression and meld requirements
- Turn order and player actions
- State persistence and multiplayer synchronization

### [Card Shuffle Animations](card-shuffle-animations.md)
Comprehensive guide to the 7 shuffle animations, including:
- Detailed description of each animation type
- Technical implementation details
- Animation phases and timing breakdown
- How to add new custom animations
- Performance considerations and tips

## Project Structure

```
godot-liverpool-rummy/
├── backgrounds/          # Background images and textures
├── docs/                # Technical documentation (you are here!)
├── fonts/               # Font files for UI
├── players/             # Player and bot AI scripts
│   └── 04-basic_bot.gd # Bot AI implementation
├── playing_cards/       # Card logic and animations
│   ├── card_shuffler.gd # Shuffle animations
│   └── playing_card.gd  # Individual card behavior
├── rounds/              # Round-specific UI scenes
├── scenes/              # Main game scenes and UI
│   └── title_page_ui.gd # Main menu and multiplayer UI
├── scripts/             # Utility scripts for meld areas
├── state_machine/       # Game state management
├── tests/               # Unit and integration tests
├── global.gd            # Global state and multiplayer management
├── rules.md             # Game rules for Liverpool Rummy
└── test-all.sh          # Run all tests
```

## Key Files

- **global.gd** - Core game state, multiplayer peer management, and RPC functions
- **scenes/title_page_ui.gd** - Main menu, UDP discovery, and connection UI
- **state_machine/** - State machine for game flow (setup, shuffle, deal, play, score, etc.)
- **playing_cards/card_shuffler.gd** - Beautiful card shuffle animations
- **players/04-basic_bot.gd** - AI bot logic for single-player and testing

## Testing

Run all tests with:
```bash
./test-all.sh
```

Individual test suites can be run:
```bash
./test-all.sh hand    # Hand evaluation tests
./test-all.sh bots    # Bot AI tests
./test-all.sh sync    # Multiplayer sync tests
```

See [DEAR_LLM.md](../DEAR_LLM.md) for important testing guidelines.

## Development Workflow

1. **Platform-specific files:** Use `./update-project-metadata.sh` to commit changes to `.godot/editor/project_metadata.cfg`
2. **Testing:** Always run `./test-all.sh` before committing
3. **Multiplayer:** Test with multiple debug instances (configured in project settings)

## Contributing

When adding new features or fixing bugs:

1. Update tests if behavior changes
2. Run `./test-all.sh` to ensure nothing breaks
3. Document complex systems in this docs folder
4. Add diagrams using Mermaid syntax where helpful

## AI Assistance

This project was developed with AI assistance. See the main [README.md](../README.md) for details on the AI-assisted development process.

---

## Documentation To-Do

- [x] Game state machine flow diagram
- [x] Multiplayer architecture and UDP discovery
- [x] Card shuffle animation guide
- [ ] Bot AI decision-making logic
- [ ] Game rules implementation details
- [ ] UI/UX interaction patterns
- [ ] Meld validation and scoring system
