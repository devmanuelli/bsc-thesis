# PATHS/VALUES Examples Test Suite

This directory contains executable Jolie files for each example from the PATHS-VALUES-GUIDE.md.

## Structure

- `example01.ol` through `example15.ol` - Individual test files for each example
- `run_all_tests.sh` - Script to run all examples and verify results

## Running Tests

### Run all examples:
```bash
./run_all_tests.sh
```

### Run a specific example:
```bash
jolie example01.ol
```

Or if you have a custom Jolie installation:
```bash
/path/to/jolie/dist/launchers/unix/jolie example01.ol
```

## Examples Covered

### PATHS/VALUES Primitives (15 examples)

1. **Example 1**: Select All (Using WHERE true)
2. **Example 2**: Filtering by Age
3. **Example 3**: Array Matching (Existential Semantics)
4. **Example 4**: Multiple Conditions with AND
5. **Example 5**: The HAS Operator
6. **Example 6**: Combining HAS with Value Checks
7. **Example 7**: Independent Condition Evaluation
8. **Example 8**: Grandfather Name-Matching
9. **Example 9**: Deep Hierarchy Navigation
10. **Example 10**: Recursive Descent
11. **Example 11**: PATHS vs VALUES
12. **Example 12**: Finding Incomplete Records
13. **Example 13**: Complex Filtering
14. **Example 14**: OR Conditions
15. **Example 15**: Array Size Filtering

## Expected Output

Each example will:
- Set up test data
- Execute the PATHS/VALUES query
- Verify the results
- Print either "✅ PASSED" or "❌ FAILED"

## Notes

- All examples are self-contained and can be run independently
- The test runner script will report overall pass/fail statistics
- Each example includes comments explaining the expected behavior
