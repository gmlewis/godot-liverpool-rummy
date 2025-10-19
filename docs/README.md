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

### [Bot AI System](bot-ai-system.md)
Deep dive into the bot artificial intelligence, including:
- Four bot personalities (Dumb, Stingy, Generous, Basic)
- Decision-making process and strategy
- Hand evaluation scoring system
- Advanced algorithms (bitmap run building, group optimization)
- Smart discard logic and public melding strategy
- How to create custom bots

### [Game Rules Implementation](game-rules-implementation.md)
Complete guide to how game rules are enforced in code, including:
- Group and run validation algorithms
- Scoring system and point values
- Turn mechanics and buy request system
- Melding rules (personal and public)
- Special Round 7 rules (no discard)
- Joker and Ace handling
- Edge cases and rule enforcement architecture

### [UI/UX Interaction Patterns](ui-ux-interaction-patterns.md)
Detailed guide to player interactions and visual feedback, including:
- Card interaction system (tap, drag, drop)
- Meld area system with real-time validation
- Visual feedback (sparkles, indicators, animations)
- Turn indicators and state-dependent interactions
- Touch-friendly design and accessibility
- Error prevention and performance optimization

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
- [x] Bot AI decision-making logic
- [x] Game rules implementation details
- [x] UI/UX interaction patterns
- [ ] Meld validation and scoring system
