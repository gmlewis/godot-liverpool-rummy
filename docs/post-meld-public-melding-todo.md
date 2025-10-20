# Post-Meld Public Melding Feature - Technical TODO List

This document outlines the implementation plan for enabling human players to publicly meld cards onto other players' personal melds after any player has personally melded in rounds 1-6. This includes JOKER replacement mechanics where non-JOKER cards can replace JOKERs in runs, returning the JOKER to the player's hand.

## Phase 1: Core State Management
- [ ] **Add Post-Meld State Detection**
  - Modify `game_state_machine.gd` to track when any player has personally melded
  - Add `is_post_meld_phase` flag to global game state
  - Update state transitions to enter post-meld phase after first personal meld

- [ ] **Extend Player State Tracking**
  - Add `has_personally_melded` flag to each player's public info
  - Update RPC functions to sync this state across clients
  - Modify UI to show post-meld indicators only when applicable

## Phase 2: Card Validation Logic
- [ ] **Implement Public Meld Validation**
  - Create `can_publicly_meld_card()` function in `global.gd`
  - Check if card can be added to any player's existing meld groups
  - Validate run extensions (same suit, consecutive ranks)
  - Validate group additions (same rank, different suits)

- [ ] **JOKER Replacement Logic**
  - Create `can_replace_joker_in_run()` function
  - Find JOKERs in runs that can be replaced by the dragged card
  - Validate replacement maintains valid run structure
  - Calculate which JOKERs would be returned to player's hand

- [ ] **Multi-Card Batch Validation**
  - Extend validation to check entire meld area contents
  - Prioritize melds that use more cards when multiple options exist
  - Handle partial melds (some cards meld, others stay in area)

## Phase 3: UI Feedback System Adaptation
- [ ] **Adapt Existing "Meld!" Indicators for Post-Meld**
  - Update logic to show indicators during post-meld phase
  - Modify indicator visibility based on public meld possibilities
  - Ensure indicators work alongside existing personal meld indicators

- [ ] **Indicator State Management**
  - Update indicators in real-time as cards enter meld area in post-meld phase
  - Show count of meldable cards for each player during public melding
  - Coordinate with existing sparkle shader system for meld area feedback

## Phase 4: Drag & Drop Handling
- [ ] **Extend Meld Area Detection**
  - Modify `scripts/meld_area_area.gd` to detect post-meld state
  - Update drag-and-drop logic to check for public meld possibilities
  - Prevent invalid drops while still allowing valid ones

- [ ] **Real-time Feedback Updates**
  - Hook into card drag events to update "Meld!" indicators for post-meld
  - Debounce updates to avoid excessive calculations
  - Clear indicators when meld area is emptied

## Phase 5: Click Action Processing
- [ ] **Implement Player Indicator Click Handling**
  - Add click detection to "Meld!" indicators for post-meld actions
  - Calculate optimal meld from current meld area cards
  - Show confirmation dialog for complex melds (optional)

- [ ] **Execute Public Meld Action**
  - Move cards from meld area to target player's meld groups
  - Handle JOKER replacement and return to player's hand
  - Update all game state and visual representations

- [ ] **Multiplayer Synchronization**
  - Create new RPC functions: `rpc_public_meld_cards()` and `rpc_replace_joker()`
  - Ensure all clients see meld animations and state updates
  - Handle race conditions when multiple players try to meld simultaneously

## Phase 6: Animation & Visual Polish
- [ ] **Public Meld Animations**
  - Animate cards moving from meld area to target player's meld groups
  - Show JOKER replacement with card swap animations
  - Add particle effects for successful melds

## Phase 7: Edge Cases & Testing
- [ ] **Handle Complex Scenarios**
  - Multiple players with valid meld targets for same card
  - Cards that can meld in different ways (prioritize best option)
  - Partial melds when not all cards in area can be placed
  - Undo functionality for mistaken public melds

- [ ] **Multiplayer Edge Cases**
  - Handle disconnections during public meld operations
  - Prevent conflicts when multiple players target same meld
  - Ensure state consistency across all clients

- [ ] **Comprehensive Testing**
  - Add unit tests for all validation functions
  - Test multiplayer synchronization of public melds
  - Add integration tests for complete meld flows

## Phase 8: Performance Optimization
- [ ] **Optimize Validation Calculations**
  - Cache meld validity results where possible
  - Use efficient algorithms for large meld group checking
  - Limit real-time updates during card dragging
