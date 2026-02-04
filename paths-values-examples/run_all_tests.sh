#!/bin/bash

JOLIE="JOLIE_HOME=/home/matteo/jolie/dist/jolie timeout 10 /home/matteo/jolie/dist/launchers/unix/jolie"

echo "========================================"
echo "PATHS/VALUES Examples Test Suite"
echo "========================================"
echo ""

passed=0
failed=0

for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15; do
    example_file="example${i}.ol"
    
    if [ -f "$example_file" ]; then
        echo "Running Example $i..."
        
        output=$($JOLIE "$example_file" 2>&1)
        
        if echo "$output" | grep -q "✅ PASSED"; then
            ((passed++))
            echo "✅ PASSED"
        else
            ((failed++))
            echo "❌ FAILED"
            echo "$output"
        fi
        echo ""
    fi
done

echo "========================================"
echo "Test Results"
echo "========================================"
echo "Passed: $passed"
echo "Failed: $failed"
echo "Total:  $((passed + failed))"
echo ""

if [ $failed -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi
