#!/bin/sh

# test_run.sh - Tests for run.sh

set -e

RUN_SH="./run.sh"
TMPDIR="./test_tmp"
IP_FILE="$TMPDIR/ips.txt"
XML_DIR="$TMPDIR/xml_files"
REPORTS_DIR="$TMPDIR/reports"

# Helper to clean up test artifacts
cleanup() {
    rm -rf "$TMPDIR"
    rm -rf ./xml_files ./reports
}
trap cleanup EXIT

mkdir -p "$TMPDIR"

# Create a dummy IPs file
echo "127.0.0.1" > "$IP_FILE"

# Mock nmap and python scripts
export PATH="$TMPDIR:$PATH"
echo -e '#!/bin/sh\necho "nmap called $@" > /dev/null' > "$TMPDIR/nmap"
chmod +x "$TMPDIR/nmap"
echo -e '#!/bin/sh\necho "aws_push called $@" > /dev/null' > "$TMPDIR/aws_push.py"
chmod +x "$TMPDIR/aws_push.py"
echo -e '#!/bin/sh\necho "gcp_push called $@" > /dev/null' > "$TMPDIR/gcp_push.py"
chmod +x "$TMPDIR/gcp_push.py"
echo -e '#!/bin/sh\necho "output_report called $@" > /dev/null' > "$TMPDIR/output_report.py"
chmod +x "$TMPDIR/output_report.py"

# Copy run.sh to TMPDIR for isolated testing
cp ./run.sh "$TMPDIR/run.sh"
cd "$TMPDIR"

# Test 1: Default run (no upload, no format)
export upload=""
export format=""
sh ./run.sh > test1.log 2>&1 || { echo "Test 1 failed"; exit 1; }
[ -d "xml_files" ] || { echo "Test 1: xml_files dir missing"; exit 1; }
[ -d "reports" ] || { echo "Test 1: reports dir missing"; exit 1; }
grep -q "nmap called" test1.log || { echo "Test 1: nmap not called"; exit 1; }
grep -q "output_report called" test1.log || { echo "Test 1: output_report not called"; exit 1; }

# Test 2: With upload=aws
export upload="aws"
sh ./run.sh > test2.log 2>&1 || { echo "Test 2 failed"; exit 1; }
grep -q "aws_push called" test2.log || { echo "Test 2: aws_push not called"; exit 1; }

# Test 3: With upload=gcp
export upload="gcp"
sh ./run.sh > test3.log 2>&1 || { echo "Test 3 failed"; exit 1; }
grep -q "gcp_push called" test3.log || { echo "Test 3: gcp_push not called"; exit 1; }

# Test 4: With format=pdf
export upload=""
export format="pdf"
sh ./run.sh > test4.log 2>&1 || { echo "Test 4 failed"; exit 1; }
grep -q "report_.*\.pdf" test4.log || { echo "Test 4: pdf report not generated"; exit 1; }

echo "All tests passed."
