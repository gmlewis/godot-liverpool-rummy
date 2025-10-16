#!/bin/bash -e
# Test runner script for Liverpool Rummy
# Makes it easier to run tests from the command line

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Godot is available
check_godot() {
    if ! command -v godot &> /dev/null; then
        print_colored $RED "Error: Godot not found in PATH"
        print_colored $YELLOW "Please install Godot or add it to your PATH"
        print_colored $YELLOW "You can download it from: https://godotengine.org/download"
        exit 1
    fi
}

# Function to run tests
run_tests() {
    local test_type=$1
    local godot_args="--headless --disable-render-loop"

    case $test_type in
        "all")
            print_colored $BLUE "Running all tests..."
            # Capture both stdout and stderr
            local output
            output=$(godot $godot_args tests/test_scene.tscn 2>&1 | tee /dev/tty)
            local exit_code=${PIPESTATUS[0]}

            # Check for SCRIPT ERROR messages in output
            if echo "$output" | grep -q -e "SCRIPT ERROR" -e "FAILED"; then
                print_colored $RED "✗ SCRIPT ERROR or FAILED detected in output - failing test run"
                return 1
            fi

            return $exit_code
            ;;
        "smoke")
            print_colored $BLUE "Running smoke tests..."
            # Capture both stdout and stderr
            local output
            output=$(godot $godot_args --script tests/test_runner.gd -- --quick 2>&1 | tee /dev/tty)
            local exit_code=${PIPESTATUS[0]}

            # Check for SCRIPT ERROR messages in output
            if echo "$output" | grep -q -e "SCRIPT ERROR" -e "FAILED"; then
                print_colored $RED "✗ SCRIPT ERROR or FAILED detected in output - failing test run"
                return 1
            fi

            return $exit_code
            ;;
        "hand")
            print_colored $BLUE "Running hand evaluation tests..."
            # Capture both stdout and stderr
            local output
            output=$(godot $godot_args tests/test_scene.tscn -- test_type=hand 2>&1 | tee /dev/tty)
            local exit_code=${PIPESTATUS[0]}

            # Check for SCRIPT ERROR messages in output
            if echo "$output" | grep -q -e "SCRIPT ERROR" -e "FAILED"; then
                print_colored $RED "✗ SCRIPT ERROR or FAILED detected in output - failing test run"
                return 1
            fi

            return $exit_code
            ;;
        "card")
            print_colored $BLUE "Running card logic tests..."
            # Capture both stdout and stderr
            local output
            output=$(godot $godot_args tests/test_scene.tscn -- test_type=card 2>&1 | tee /dev/tty)
            local exit_code=${PIPESTATUS[0]}

            # Check for SCRIPT ERROR messages in output
            if echo "$output" | grep -q -e "SCRIPT ERROR" -e "FAILED"; then
                print_colored $RED "✗ SCRIPT ERROR or FAILED detected in output - failing test run"
                return 1
            fi

            return $exit_code
            ;;
        "state")
            print_colored $BLUE "Running game state tests..."
            # Capture both stdout and stderr
            local output
            output=$(godot $godot_args tests/test_scene.tscn -- test_type=state 2>&1 | tee /dev/tty)
            local exit_code=${PIPESTATUS[0]}

            # Check for SCRIPT ERROR messages in output
            if echo "$output" | grep -q -e "SCRIPT ERROR" -e "FAILED"; then
                print_colored $RED "✗ SCRIPT ERROR or FAILED detected in output - failing test run"
                return 1
            fi

            return $exit_code
            ;;
        "sync")
            print_colored $BLUE "Running multiplayer sync tests..."
            # Capture both stdout and stderr
            local output
            output=$(godot $godot_args tests/test_scene.tscn -- test_type=sync 2>&1 | tee /dev/tty)
            local exit_code=${PIPESTATUS[0]}

            # Check for SCRIPT ERROR messages in output
            if echo "$output" | grep -q -e "SCRIPT ERROR" -e "FAILED"; then
                print_colored $RED "✗ SCRIPT ERROR or FAILED detected in output - failing test run"
                return 1
            fi

            return $exit_code
            ;;
        "bots")
            print_colored $BLUE "Running bot AI tests..."
            # Capture both stdout and stderr
            local output
            output=$(godot $godot_args tests/test_scene.tscn -- test_type=bots 2>&1 | tee /dev/tty)
            local exit_code=${PIPESTATUS[0]}

            # Check for SCRIPT ERROR messages in output
            if echo "$output" | grep -q -e "SCRIPT ERROR" -e "FAILED"; then
                print_colored $RED "✗ SCRIPT ERROR or FAILED detected in output - failing test run"
                return 1
            fi

            return $exit_code
            ;;
        *)
            print_colored $RED "Unknown test type: $test_type"
            show_help
            exit 1
            ;;
    esac

    if [ $? -ne 0 ]; then
        print_colored $RED "✗ Test failed"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Liverpool Rummy Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS] [TEST_TYPE]"
    echo ""
    echo "Test Types:"
    echo "  all     - Run all tests (default)"
    echo "  smoke   - Run quick smoke tests"
    echo "  hand    - Run hand evaluation tests"
    echo "  card    - Run card logic tests"
    echo "  state   - Run game state tests"
    echo "  sync    - Run multiplayer sync tests"
    echo "  bots    - Run bot AI tests"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo "  -q, --quiet    Suppress non-error output"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run all tests"
    echo "  $0 smoke           # Run smoke tests"
    echo "  $0 hand            # Run hand evaluation tests"
    echo "  $0 bots            # Run bot AI tests"
    echo "  $0 --verbose all   # Run all tests with verbose output"
}

# Function to run with timing
run_with_timing() {
    local start_time=$(date +%s.%N)
    run_tests "$@"
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    print_colored $GREEN "Tests completed in ${duration}s"
}

# Main script
main() {
    # Change to project directory
    cd "$(dirname "$0")/.."

    # Check if Godot is available
    check_godot

    # Parse command line arguments
    local verbose=false
    local quiet=false
    local test_type="all"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            all|smoke|hand|card|state|sync|bots)
                test_type=$1
                shift
                ;;
            *)
                print_colored $RED "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Set output level
    if $quiet; then
        exec 1>/dev/null
    fi

    # Print header
    if ! $quiet; then
        print_colored $YELLOW "====================================="
        print_colored $YELLOW "  Liverpool Rummy Test Suite"
        print_colored $YELLOW "====================================="
    fi

    # Run tests
    if $verbose; then
        print_colored $BLUE "Running tests in verbose mode..."
    fi

    run_with_timing $test_type

    # Check exit code
    if [ $? -eq 0 ]; then
        print_colored $GREEN "✓ Tests completed successfully"
    else
        print_colored $RED "✗ Tests failed"
        exit 1
    fi
}

# Run main function
main "$@"
