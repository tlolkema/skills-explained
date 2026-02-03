#!/bin/bash
# Wrapper script to run ESLint and convert exit code 1 to exit code 2
# So agent / skill hooks treat lint errors as blocking errors

# Capture both stdout and stderr
OUTPUT=$(pnpm --filter e2e-tests lint 2>&1)
EXIT_CODE=$?

# Print output to stderr
echo "$OUTPUT" >&2

# Convert ESLint's exit code 1 (lint errors) to exit code 2 (blocking error)
if [ $EXIT_CODE -eq 1 ]; then
  exit 2
fi

exit $EXIT_CODE
