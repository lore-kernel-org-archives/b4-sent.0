From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 14 Sep 2026 14:40:19 +0200
Subject: [PATCH] sysctl: Rewrite selftests on top of KTAP helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-lklm-sysctl-selftests-v1-1-160d90bf8f3e@kernel.org>
X-B4-Tracking: v=1; b=H4sIADLrp2oC/x3MSQqAMAxA0atI1gZqcUCvIi5qjRqsA00RRby7x
 eVb/P+AkGcSaJIHPJ0svG8RWZqAnc02EfIQDVrpUtVZjm5xK8otNjgUcmMgCYKFUpXpyeiy6iG
 2h6eRr//bdu/7AQSEAKxnAAAA
X-Change-ID: 20260914-lklm-sysctl-selftests-5007abea267b
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=46580;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=uCTbdM2yo0ugAKHW9LYAcxCyFoCBbnmHNX+f/B8cMCg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGqn6zpshtN2H8L9ScjCepftCSPdb0KHVrpPk
 wznDECwm3Fi9okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqp+s6AAoJELqXzVK3
 lkFPUL4L/A0C6uj3VqkM/uH6hrLVka2qXxQgoujhnoXCxf6EY24pZ9WCQtlvGYVOjN0PA67jpg5
 uSFTXifVn8jHpyK6a96Vhrpiw8ltmNDUNWdBJwTnUKaO7JheYnIElrHWglsCei4gNVeaC4xUXUD
 nzuuTCrOTz8TxEiSWM0M8w9UCndgUBngea9wUythQjg6vjsDR39NC+dEmghmh1RQxsNeCTS665a
 1Dd4gc7josYQPFKULhhEqpDQMtw2L8YmfjSrysIkezq0wmgagetOQl2qZQuwiU6Hr8O2ERlt8v1
 5GyM7jhv8DvmI3zfqvw0yKyf3MDIahTXN4ru1slnM7y20xmELP9RRzNaiALA/FQQJ0oR7xHK6+B
 LXACFyUtzZMhP/JudeL3k9OxjpSNB9xE89N1P8zGXGK7M74aNEkjmPZIcP4rOh302Rc2fr8R6Wx
 V/OjKJaeTC2iqlNk9av83+TJU2oan6Jo1dao8mCpcs0OHf6nPfFXeEu5hRbhh/ofXOhH94QdTb9
 D8=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use kselftest/ktap_helpers.sh so that each test reports its own KTAP
result. A failure names the test but continues with the rest of the
suite. Tests are functions prefixed by "test_", they run in a subshell
and do not leak state to other tests. Sysctl test assertions (assert*)
emit a KTAP diagnostic and return a status, never exit.

The sysctl selftests arguments are:
    -r N          repeat selected tests N times (default 1)
    -l            list discovered tests
    -t T          space separated tests list. For example "test_1 test_2"
    -s N          base seed for the randomized bitmap iterations.
    -h, --help    help

It is a single commit to avoid intermediate states where the runner
exists with no tests or where scaffolding is added only to be deleted
later in the same series. Neither bisects usefully.

Assisted-by: Claude:claude-opus-5
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 tools/testing/selftests/sysctl/sysctl.sh | 1497 +++++++++++-------------------
 1 file changed, 548 insertions(+), 949 deletions(-)

diff --git a/tools/testing/selftests/sysctl/sysctl.sh b/tools/testing/selftests/sysctl/sysctl.sh
index 95e93709088a3d3dd451b6368278bcf8c863c48f..ceb5cfa0cfd4d5e68bc9f4fb59bfe893c6ee878e 100755
--- a/tools/testing/selftests/sysctl/sysctl.sh
+++ b/tools/testing/selftests/sysctl/sysctl.sh
@@ -2,362 +2,239 @@
 # SPDX-License-Identifier: GPL-2.0-or-later OR copyleft-next-0.3.1
 # Copyright (C) 2017 Luis R. Rodriguez <mcgrof@kernel.org>
 
-# This performs a series tests against the proc sysctl interface.
-
+# Reduce noise by disabling "unreachable" check.
 # shellcheck disable=SC2317
-# Kselftest framework requirement - SKIP code is 4.
-ksft_skip=4
-
-TEST_NAME="sysctl"
-TEST_DRIVER="test_${TEST_NAME}"
-TEST_DIR=$(dirname $0)
-TEST_FILE=$(mktemp)
-
-# initialize for individual tests
-rc=0
-
-# This represents
-#
-# TEST_ID:TEST_COUNT:ENABLED:TARGET:SKIP_NO_TARGET
-#
-# TEST_ID: is the test id number
-# TEST_COUNT: number of times we should run the test
-# ENABLED: 1 if enabled, 0 otherwise
-# TARGET: test target file required on the test_sysctl module
-# SKIP_NO_TARGET: 1 skip if TARGET not there
-#                 0 run even though TARGET not there
-#
-# Once these are enabled please leave them as-is. Write your own test,
-# we have tons of space.
-ALL_TESTS="0001:1:1:int_0001:1"
-ALL_TESTS="$ALL_TESTS 0002:1:1:string_0001:1"
-ALL_TESTS="$ALL_TESTS 0003:1:1:int_0002:1"
-ALL_TESTS="$ALL_TESTS 0004:1:1:uint_0001:1"
-ALL_TESTS="$ALL_TESTS 0005:3:1:int_0003:1"
-ALL_TESTS="$ALL_TESTS 0006:50:1:bitmap_0001:1"
-ALL_TESTS="$ALL_TESTS 0007:1:1:boot_int:1"
-ALL_TESTS="$ALL_TESTS 0008:1:1:match_int:1"
-ALL_TESTS="$ALL_TESTS 0009:1:1:unregister_error:0"
-ALL_TESTS="$ALL_TESTS 0010:1:1:mnt/mnt_error:0"
-ALL_TESTS="$ALL_TESTS 0011:1:1:empty_add:0"
-ALL_TESTS="$ALL_TESTS 0012:1:1:u8_valid:0"
-ALL_TESTS="$ALL_TESTS 0013:1:1:int_0003:1"
-
-function allow_user_defaults()
+
+# This performs a series of tests against the proc sysctl interface.
+
+DIR="$(dirname "$(readlink -f "$0")")"
+source "${DIR}"/../kselftest/ktap_helpers.sh
+
+TEST_DRIVER="test_sysctl"
+
+assert_write_rejected() # <file> <value>
 {
-	if [ -z $DIR ]; then
-		DIR="/sys/module/test_sysctl/"
-	fi
-	if [ -z $DEFAULT_NUM_TESTS ]; then
-		DEFAULT_NUM_TESTS=50
-	fi
-	if [ -z $SYSCTL ]; then
-		SYSCTL="/proc/sys/debug/test_sysctl"
-	fi
-	if [ -z $PROD_SYSCTL ]; then
-		PROD_SYSCTL="/proc/sys"
-	fi
-	if [ -z $WRITES_STRICT ]; then
-		WRITES_STRICT="${PROD_SYSCTL}/kernel/sysctl_writes_strict"
+	local file=$1 val=$2
+	if printf '%s' "$val" > "$file" 2>/dev/null; then
+		ktap_print_msg "$file: write of '$val' succeeded, expected rejection"
+		return 1
 	fi
+	return 0
 }
 
-function check_production_sysctl_writes_strict()
+assert_content() # <file> <want-file>
 {
-	echo -n "Checking production write strict setting ... "
-	if [ ! -e ${WRITES_STRICT} ]; then
-		echo "FAIL, but skip in case of old kernel" >&2
-	else
-		old_strict=$(cat ${WRITES_STRICT})
-		if [ "$old_strict" = "1" ]; then
-			echo "OK"
-		else
-			echo "FAIL, strict value is 0 but force to 1 to continue" >&2
-			echo "1" > ${WRITES_STRICT}
-		fi
-	fi
-
-	if [ -z $PAGE_SIZE ]; then
-		PAGE_SIZE=$(getconf PAGESIZE)
-	fi
-	if [ -z $MAX_DIGITS ]; then
-		MAX_DIGITS=$(($PAGE_SIZE/8))
-	fi
-	if [ -z $INT_MAX ]; then
-		INT_MAX=$(getconf INT_MAX)
-	fi
-	if [ -z $UINT_MAX ]; then
-		UINT_MAX=$(getconf UINT_MAX)
+	local file=$1 want_file=$2 got
+	got=$(cat "$file")
+	if [ "$got" == "$want_file" ]; then
+		return 0
 	fi
+	ktap_print_msg "$file: got '$got', want '$want_file'"
+	return 1
 }
 
-test_reqs()
+# compare ignoring whitespaces
+assert_content_loose() # <file> <want-file>
 {
-	uid=$(id -u)
-	if [ $uid -ne 0 ]; then
-		echo $msg must be run as root >&2
-		exit $ksft_skip
-	fi
-
-	if ! which perl 2> /dev/null > /dev/null; then
-		echo "$0: You need perl installed"
-		exit $ksft_skip
-	fi
-	if ! which getconf 2> /dev/null > /dev/null; then
-		echo "$0: You need getconf installed"
-		exit $ksft_skip
-	fi
-	if ! which diff 2> /dev/null > /dev/null; then
-		echo "$0: You need diff installed"
-		exit $ksft_skip
+	local file=$1 want_file=$2
+	if echo "$want_file" | diff -q -w -u - "$file" > /dev/null; then
+		return 0
 	fi
+	ktap_print_msg "$file: content does not match '$want_file' (whitespace-insensitive)"
+	return 1
 }
 
-function load_req_mod()
+# For checks where writes must NOT take effect
+assert_content_rejected() # <file> <bad>
 {
-	if [ ! -d $SYSCTL ]; then
-		if ! modprobe -q -n $TEST_DRIVER; then
-			echo "$0: module $TEST_DRIVER not found [SKIP]"
-			echo "You must set CONFIG_TEST_SYSCTL=m in your kernel" >&2
-			exit $ksft_skip
-		fi
-		modprobe $TEST_DRIVER
-		if [ $? -ne 0 ]; then
-			echo "$0: modprobe $TEST_DRIVER failed."
-			exit
-		fi
+	local file=$1 bad=$2
+	if echo "$bad" | diff -q -w -u - "$file" > /dev/null; then
+		ktap_print_msg "$file: unexpectedly now holds rejected value '$bad'"
+		return 1
 	fi
+	return 0
 }
 
-reset_vals()
+# proc files get read a page at a time, which can confuse diff resulting in
+# incorrect results. Use a temp file to diff.
+assert_diff_proc_file() # <file> <want-file>
 {
-	VAL=""
-	TRIGGER=$(basename ${TARGET})
-	case "$TRIGGER" in
-		int_0001)
-			VAL="60"
-			;;
-		int_0002)
-			VAL="1"
-			;;
-		uint_0001)
-			VAL="314"
-			;;
-		string_0001)
-			VAL="(none)"
-			;;
-		bitmap_0001)
-			VAL=""
-			;;
-		*)
-			;;
-	esac
-	echo -n $VAL > $TARGET
-}
+	local file=$1 want_file=$2 tmp
+	tmp=$(mktemp)
+	cat "$file" > "$tmp"
 
-set_orig()
-{
-	if [ ! -z $TARGET ] && [ ! -z $ORIG ]; then
-		if [ -f ${TARGET} ]; then
-			echo "${ORIG}" > "${TARGET}"
-		fi
+	if diff -w -q "$tmp" "$want_file" > /dev/null; then
+		rm -f "$tmp"
+		return 0
 	fi
+	ktap_print_msg "$file: content does not match expected file $want_file"
+	rm -f "$tmp"
+	return 1
 }
 
-set_test()
+# Verify that an erroneous update fails and does not change the baseline.
+assert_no_partial_update() # <file> <baseline> <bad-value>
 {
-	echo "${TEST_STR}" > "${TARGET}"
+	local file=$1 baseline=$2 bad=$3
+
+	printf '%s' "$baseline" > "$file"
+	assert_write_rejected "$file" "$bad" || return 1
+	assert_content_loose "$file" "$baseline"
 }
 
-verify()
+assert_grep() # <file> <pattern> - <pattern> must appear in <file>
 {
-	local seen
-	seen=$(cat "$1")
-	if [ "${seen}" != "${TEST_STR}" ]; then
-		return 1
+	local file=$1 pattern=$2
+	if grep -q "$pattern" "$file"; then
+		return 0
 	fi
-	return 0
+	ktap_print_msg "$file: pattern '$pattern' not found"
+	return 1
 }
 
-# proc files get read a page at a time, which can confuse diff,
-# and get you incorrect results on proc files with long data. To use
-# diff against them you must first extract the output to a file, and
-# then compare against that file.
-verify_diff_proc_file()
+assert_grep_absent() # <file> <pattern> - <pattern> must NOT appear
 {
-	TMP_DUMP_FILE=$(mktemp)
-	cat $1 > $TMP_DUMP_FILE
-
-	if ! diff -w -q $TMP_DUMP_FILE $2; then
-		return 1
-	else
+	local file=$1 pattern=$2
+	if ! grep -q "$pattern" "$file"; then
 		return 0
 	fi
+	ktap_print_msg "$file: pattern '$pattern' unexpectedly found"
+	return 1
 }
 
-verify_diff_w()
+assert_dmesg_count() # <pattern> <want-count>
 {
-	echo "$TEST_STR" | diff -q -w -u - $1 > /dev/null
-	return $?
+	local pattern=$1 want=$2 got
+	got=$(dmesg | grep -c "$pattern")
+	if [ "$got" -eq "$want" ]; then
+		return 0
+	fi
+	ktap_print_msg "dmesg: pattern '$pattern' seen $got times, want $want"
+	return 1
 }
 
-# Verify that an erroneous ($2) update fails and does not change TARGET
-verify_no_partial_update()
+# write <str> through dd in <bs>-sized chunks
+write_in_chunks()  # <file> <str> <bs>
 {
-	TEST_STR="$1"
-	echo -n "$TEST_STR" > "$TARGET"
-
-	if echo -n "$2" > "$TARGET" 2> /dev/null; then
-		return 1
-	fi
-	verify_diff_w "${TARGET}"
+	local file=$1 str=$2 bs=$3
+	printf '%s' "$str" | dd of="$file" bs="$bs" 2>/dev/null
 }
 
-test_rc()
+# write <str> through dd in <bs>-sized chunks. seeking <seek> blocks of size
+# <bs> into the output. skipping <skip> blocks of size <bs> from the input.
+# Unsyncrhonized when skip is not passed.
+write_at_offset()  # <file> <str> <bs> <seek> [skip]
 {
-	if [[ $rc != 0 ]]; then
-		echo "Failed test, return value: $rc" >&2
-		exit $rc
+	local file=$1 str=$2 bs=$3 seek=$4 skip=${5:-}
+	if [ -n "$skip" ]; then
+		printf '%s' "$str" | dd of="$file" bs="$bs" seek="$seek" skip="$skip" 2>/dev/null
+	else
+		printf '%s' "$str" | dd of="$file" bs="$bs" seek="$seek" 2>/dev/null
 	fi
 }
 
-test_finish()
+# pad (prefix) <str> with <pad> 'A' characters, then write it all to <file>
+# with dd block size <bs> (defaults to <pad>).
+write_overlong()  # <file> <pad> <str> [bs]
 {
-	set_orig
-	rm -f "${TEST_FILE}"
+	local file=$1 pad=$2 str=$3 bs=$4 p
+	: "${bs:=$pad}"
 
-	if [ ! -z ${old_strict} ]; then
-		echo ${old_strict} > ${WRITES_STRICT}
-	fi
-	exit $rc
+	# save a string with $pad spaces in $p
+	printf -v p '%*s' "$pad" ''
+	# replace " " with "A"
+	printf '%s%s' "${p// /A}" "$str" | dd of="$file" bs="$bs" 2>/dev/null
 }
 
-run_numerictests()
+# pad (prefix) <str> with <pad> ASCII spaces, then write with default block size.
+write_padded_digits()  # <file> <pad> <val>
 {
-	echo "== Testing sysctl behavior against ${TARGET} =="
+	local file=$1 pad=$2 val=$3 p
+	printf -v p '%*s' "$pad" ''
+	printf '%s%s' "$p" "$val" | dd of="$file" 2>/dev/null
+}
 
-	rc=0
+test_int_array_writes()
+{
+	local t="${SYSCTL}/int_0003"
+	local limit
 
-	echo -n "Writing test file ... "
-	echo "${TEST_STR}" > "${TEST_FILE}"
-	if ! verify "${TEST_FILE}"; then
-		echo "FAIL" >&2
-		exit 1
-	else
-		echo "OK"
-	fi
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
 
-	echo -n "Checking sysctl is not set to test value ... "
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		exit 1
-	else
-		echo "OK"
-	fi
+	printf '%s' "4 3 2 1" > "$t"
+	assert_content_loose "$t" "4 3 2 1" || RET=$KSFT_FAIL
 
-	echo -n "Writing sysctl from shell ... "
-	set_test
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		exit 1
-	else
-		echo "OK"
-	fi
+	# Skipping trailing elements leaves them intact
+	printf '%s' "100 101" > "$t"
+	assert_content_loose "$t" "100 101 2 1" || RET=$KSFT_FAIL
 
-	echo -n "Resetting sysctl to original value ... "
-	set_orig
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		exit 1
-	else
-		echo "OK"
-	fi
+	# Even for an int array, a single write is still capped at MAX_DIGITS
+	# (PAGE_SIZE/8) bytes; check right at, and just past, that boundary.
+	# Carries on the state from the writes above.
+	limit=$((MAX_DIGITS - 1))
+	write_padded_digits "$t" "$limit" "9"
+	assert_content_loose "$t" "9 101 2 1" || RET=$KSFT_FAIL
 
-	# Now that we've validated the sanity of "set_test" and "set_orig",
-	# we can use those functions to set starting states before running
-	# specific behavioral tests.
+	limit=$((MAX_DIGITS))
+	write_padded_digits "$t" "$limit" "7"
+	assert_content_rejected "$t" "7 101 2 1" || RET=$KSFT_FAIL
+}
 
-	echo -n "Writing entire sysctl in single write ... "
-	set_orig
-	dd if="${TEST_FILE}" of="${TARGET}" bs=4096 2>/dev/null
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
+test_int_array_no_partial_update()
+{
+	local t="${SYSCTL}/int_0003"
 
-	echo -n "Writing middle of sysctl after synchronized seek ... "
-	set_test
-	dd if="${TEST_FILE}" of="${TARGET}" bs=1 seek=1 skip=1 2>/dev/null
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
 
-	echo -n "Writing beyond end of sysctl ... "
-	set_orig
-	dd if="${TEST_FILE}" of="${TARGET}" bs=20 seek=2 2>/dev/null
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
+	# bad 3rd element (not a number)
+	assert_no_partial_update "$t" "1 2 3 4" "10 20 abc 40" || RET=$KSFT_FAIL
 
-	echo -n "Writing sysctl with multiple long writes ... "
-	set_orig
-	(perl -e 'print "A" x 50;'; echo "${TEST_STR}") | \
-		dd of="${TARGET}" bs=50 2>/dev/null
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
+	# bad 3rd element (overflows int)
+	assert_no_partial_update "$t" "1 2 3 4" "10 20 $((INT_MAX + 1)) 40" || RET=$KSFT_FAIL
+
+	# bad 1st element
+	assert_no_partial_update "$t" "1 2 3 4" "abc 20 30 40" || RET=$KSFT_FAIL
 }
 
-check_failure()
+# Exercise the write patterns
+assert_write_patterns()  # <file> <baseline> <val>
 {
-	echo -n "Testing that $1 fails as expected ... "
-	reset_vals
-	TEST_STR="$1"
-	orig="$(cat $TARGET)"
-	echo -n "$TEST_STR" > $TARGET 2> /dev/null
-
-	# write should fail and $TARGET should retain its original value
-	if [ $? = 0 ] || [ "$(cat $TARGET)" != "$orig" ]; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
+	local file=$1 baseline=$2 val=$3 status=0
+
+	printf '%s' "$val" > "$file"
+	assert_content "$file" "$val" || status=1
+	printf '%s' "$baseline" > "$file"
+	assert_content "$file" "$baseline" || status=1
+
+	printf '%s' "$baseline" > "$file"
+	write_in_chunks "$file" "$val" 4096
+	assert_content "$file" "$val" || status=1
+
+	printf '%s' "$val" > "$file"
+	write_at_offset "$file" "$val" 1 1 1
+	assert_content "$file" "$val" || status=1
+
+	printf '%s' "$baseline" > "$file"
+	write_at_offset "$file" "$val" 20 2
+	assert_content_rejected "$file" "$val" || status=1
+
+	printf '%s' "$baseline" > "$file"
+	write_overlong "$file" 50 "$val"
+	assert_content_rejected "$file" "$val" || status=1
+
+	return "$status"
 }
 
-run_wideint_tests()
+# None of these fit in 32 bits, so writing them to an int/uint sysctl must fail
+assert_wideint_writes_rejected()  # <file> <baseline>
 {
-	# sysctl conversion functions receive a boolean sign and ulong
-	# magnitude; here we list the magnitudes we want to test (each of
-	# which will be tested in both positive and negative forms).  Since
-	# none of these values fit in 32 bits, writing them to an int- or
-	# uint-typed sysctl should fail.
+	local file=$1 baseline=$2 sign mag status=0
 	local magnitudes=(
-		# common boundary-condition values (zero, +1, -1, INT_MIN,
-		# and INT_MAX respectively) if truncated to lower 32 bits
-		# (potential for being falsely deemed in range)
 		0x0000000100000000
 		0x0000000100000001
 		0x00000001ffffffff
 		0x0000000180000000
 		0x000000017fffffff
-
-		# these look like negatives, but without a leading '-' are
-		# actually large positives (should be rejected as above
-		# despite being zero/+1/-1/INT_MIN/INT_MAX in the lower 32)
 		0xffffffff00000000
 		0xffffffff00000001
 		0xffffffffffffffff
@@ -367,793 +244,515 @@ run_wideint_tests()
 
 	for sign in '' '-'; do
 		for mag in "${magnitudes[@]}"; do
-			check_failure "${sign}${mag}"
+			assert_no_partial_update "$file" "$baseline" "${sign}${mag}" || status=1
 		done
 	done
+	return "$status"
 }
 
-# Your test must accept digits 3 and 4 to use this
-run_limit_digit()
+# A single write is capped at MAX_DIGITS (PAGE_SIZE/8) bytes; check that
+# leading whitespace up to that limit is ignored, and that PAGE_SIZE of
+# leading whitespace pushes the value past the limit and fails.
+assert_digit_limit()  # <file> <baseline>
 {
-	echo -n "Checking ignoring spaces up to PAGE_SIZE works on write ... "
-	reset_vals
-
-	LIMIT=$((MAX_DIGITS -1))
-	TEST_STR="3"
-	(perl -e 'print " " x '$LIMIT';'; echo "${TEST_STR}") | \
-		dd of="${TARGET}" 2>/dev/null
-
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Checking passing PAGE_SIZE of spaces fails on write ... "
-	reset_vals
-
-	LIMIT=$((MAX_DIGITS))
-	TEST_STR="4"
-	(perl -e 'print " " x '$LIMIT';'; echo "${TEST_STR}") | \
-		dd of="${TARGET}" 2>/dev/null
-
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
+	local file=$1 baseline=$2 status=0
+
+	printf '%s' "$baseline" > "$file"
+	write_padded_digits "$file" "$((MAX_DIGITS - 1))" "3"
+	assert_content "$file" "3" || status=1
+
+	printf '%s' "$baseline" > "$file"
+	write_padded_digits "$file" "$MAX_DIGITS" "4"
+	assert_content_rejected "$file" "4" || status=1
+
+	return "$status"
 }
 
-# You are using an int
-run_limit_digit_int()
+# proc_dointvec()-specific range checks: INT_MAX must be accepted, INT_MAX+1
+# must be rejected, and negative values must be accepted.
+assert_int_range()  # <file> <baseline>
 {
-	echo -n "Testing INT_MAX works ... "
-	reset_vals
-	TEST_STR="$INT_MAX"
-	echo -n $TEST_STR > $TARGET
-
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing INT_MAX + 1 will fail as expected ... "
-	reset_vals
-	let TEST_STR=$INT_MAX+1
-	echo -n $TEST_STR > $TARGET 2> /dev/null
-
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing negative values will work as expected ... "
-	reset_vals
-	TEST_STR="-3"
-	echo -n $TEST_STR > $TARGET 2> /dev/null
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
+	local file=$1 baseline=$2 status=0
+
+	printf '%s' "$baseline" > "$file"
+	printf '%s' "$INT_MAX" > "$file"
+	assert_content "$file" "$INT_MAX" || status=1
+
+	assert_no_partial_update "$file" "$baseline" "$((INT_MAX + 1))" || status=1
+
+	printf '%s' "$baseline" > "$file"
+	printf '%s' "-3" > "$file" 2>/dev/null
+	assert_content "$file" "-3" || status=1
+
+	return "$status"
 }
 
-# You used an int array
-run_limit_digit_int_array()
+# proc_douintvec()-specific range checks: UINT_MAX must be accepted,
+# UINT_MAX+1 must be rejected, and negative values must be rejected too.
+assert_uint_range()  # <file> <baseline>
 {
-	echo -n "Testing array works as expected ... "
-	TEST_STR="4 3 2 1"
-	echo -n $TEST_STR > $TARGET
-
-	if ! verify_diff_w "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing skipping trailing array elements works ... "
-	# Do not reset_vals, carry on the values from the last test.
-	# If we only echo in two digits the last two are left intact
-	TEST_STR="100 101"
-	echo -n $TEST_STR > $TARGET
-	# After we echo in, to help diff we need to set on TEST_STR what
-	# we expect the result to be.
-	TEST_STR="100 101 2 1"
-
-	if ! verify_diff_w "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing PAGE_SIZE limit on array works ... "
-	# Do not reset_vals, carry on the values from the last test.
-	# Even if you use an int array, you are still restricted to
-	# MAX_DIGITS, this is a known limitation. Test limit works.
-	LIMIT=$((MAX_DIGITS -1))
-	TEST_STR="9"
-	(perl -e 'print " " x '$LIMIT';'; echo "${TEST_STR}") | \
-		dd of="${TARGET}" 2>/dev/null
-
-	TEST_STR="9 101 2 1"
-	if ! verify_diff_w "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing exceeding PAGE_SIZE limit fails as expected ... "
-	# Do not reset_vals, carry on the values from the last test.
-	# Now go over limit.
-	LIMIT=$((MAX_DIGITS))
-	TEST_STR="7"
-	(perl -e 'print " " x '$LIMIT';'; echo "${TEST_STR}") | \
-		dd of="${TARGET}" 2>/dev/null
-
-	TEST_STR="7 101 2 1"
-	if verify_diff_w "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
+	local file=$1 baseline=$2 status=0
+
+	printf '%s' "$baseline" > "$file"
+	printf '%s' "$UINT_MAX" > "$file"
+	assert_content "$file" "$UINT_MAX" || status=1
+
+	assert_no_partial_update "$file" "$baseline" "$((UINT_MAX + 1))" || status=1
+	assert_no_partial_update "$file" "$baseline" "-3" || status=1
+
+	return "$status"
 }
 
-# You used an int array and one of the elements is not acceptable
-run_int_array_no_partial_update()
+test_int_minmax()
 {
-	echo -n "Testing invalid array element does not partially update ... "
-	# Expect failure because of 3rd element (abc).
-	if ! verify_no_partial_update "1 2 3 4" "10 20 abc 40"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing out of range array element does not partially update ... "
-	# Expect failure because of 3rd element (greater than int)
-	if ! verify_no_partial_update "1 2 3 4" "10 20 $((INT_MAX + 1)) 40"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing invalid first array element does not update ... "
-	# Expect failure of 1st element
-	if ! verify_no_partial_update "1 2 3 4" "abc 20 30 40"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
+	local t="${SYSCTL}/int_0001"
+	local baseline="60" val="61"
+
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
+
+	assert_write_patterns "$t" "$baseline" "$val" || RET=$KSFT_FAIL
+	assert_wideint_writes_rejected "$t" "$baseline" || RET=$KSFT_FAIL
+	assert_digit_limit "$t" "$baseline" || RET=$KSFT_FAIL
 }
 
-# You are using an unsigned int
-run_limit_digit_uint()
+test_int_plain()
 {
-	echo -n "Testing UINT_MAX works ... "
-	reset_vals
-	TEST_STR="$UINT_MAX"
-	echo -n $TEST_STR > $TARGET
-
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing UINT_MAX + 1 will fail as expected ... "
-	reset_vals
-	TEST_STR=$(($UINT_MAX+1))
-	echo -n $TEST_STR > $TARGET 2> /dev/null
-
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
-
-	echo -n "Testing negative values will not work as expected ... "
-	reset_vals
-	TEST_STR="-3"
-	echo -n $TEST_STR > $TARGET 2> /dev/null
-
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-	test_rc
+	local t="${SYSCTL}/int_0002"
+	local baseline="1" val="2"
+
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
+
+	assert_write_patterns "$t" "$baseline" "$val" || RET=$KSFT_FAIL
+	assert_wideint_writes_rejected "$t" "$baseline" || RET=$KSFT_FAIL
+	assert_digit_limit "$t" "$baseline" || RET=$KSFT_FAIL
+	assert_int_range "$t" "$baseline" || RET=$KSFT_FAIL
 }
 
-run_stringtests()
+test_uint_plain()
 {
-	echo -n "Writing entire sysctl in short writes ... "
-	set_orig
-	dd if="${TEST_FILE}" of="${TARGET}" bs=1 2>/dev/null
-	if ! verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-
-	echo -n "Writing middle of sysctl after unsynchronized seek ... "
-	set_test
-	dd if="${TEST_FILE}" of="${TARGET}" bs=1 seek=1 2>/dev/null
-	if verify "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-
-	echo -n "Checking sysctl maxlen is at least $MAXLEN ... "
-	set_orig
-	perl -e 'print "A" x ('"${MAXLEN}"'-2), "B";' | \
-		dd of="${TARGET}" bs="${MAXLEN}" 2>/dev/null
-	if ! grep -q B "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-
-	echo -n "Checking sysctl keeps original string on overflow append ... "
-	set_orig
-	perl -e 'print "A" x ('"${MAXLEN}"'-1), "B";' | \
-		dd of="${TARGET}" bs=$(( MAXLEN - 1 )) 2>/dev/null
-	if grep -q B "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-
-	echo -n "Checking sysctl stays NULL terminated on write ... "
-	set_orig
-	perl -e 'print "A" x ('"${MAXLEN}"'-1), "B";' | \
-		dd of="${TARGET}" bs="${MAXLEN}" 2>/dev/null
-	if grep -q B "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-
-	echo -n "Checking sysctl stays NULL terminated on overwrite ... "
-	set_orig
-	perl -e 'print "A" x ('"${MAXLEN}"'-1), "BB";' | \
-		dd of="${TARGET}" bs=$(( $MAXLEN + 1 )) 2>/dev/null
-	if grep -q B "${TARGET}"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-	fi
-
-	test_rc
+	local t="${SYSCTL}/uint_0001"
+	local baseline="314" val="315"
+
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
+
+	assert_write_patterns "$t" "$baseline" "$val" || RET=$KSFT_FAIL
+	assert_wideint_writes_rejected "$t" "$baseline" || RET=$KSFT_FAIL
+	assert_digit_limit "$t" "$baseline" || RET=$KSFT_FAIL
+	assert_uint_range "$t" "$baseline" || RET=$KSFT_FAIL
 }
 
-target_exists()
+# proc_dostring()-specific write patterns
+assert_string_write_patterns()  # <file> <baseline> <val> <maxlen>
 {
-	TARGET="${SYSCTL}/$1"
-	TEST_ID="$2"
+	local file=$1 baseline=$2 val=$3 maxlen=$4 status=0
 
-	if [ ! -f ${TARGET} ] ; then
-		return 0
-	fi
-	return 1
-}
+	printf '%s' "$baseline" > "$file"
+	write_in_chunks "$file" "$val" 1
+	assert_content "$file" "$val" || status=1
+
+	printf '%s' "$val" > "$file"
+	write_at_offset "$file" "$val" 1 1
+	assert_content_rejected "$file" "$val" || status=1
+
+	# sysctl maxlen is at least $maxlen
+	printf '%s' "$baseline" > "$file"
+	write_overlong "$file" "$((maxlen - 2))" "B" "$maxlen"
+	assert_grep "$file" "B" || status=1
 
-run_bitmaptest() {
-	# Total length of bitmaps string to use, a bit under
-	# the maximum input size of the test node
-	LENGTH=$((RANDOM % 65000))
+	# keep original string on overflow append
+	printf '%s' "$baseline" > "$file"
+	write_overlong "$file" "$((maxlen - 1))" "B" "$((maxlen - 1))"
+	assert_grep_absent "$file" "B" || status=1
 
-	# First bit to set
-	BIT=$((RANDOM % 1024))
+	# sysctl stays NULL terminated on write
+	printf '%s' "$baseline" > "$file"
+	write_overlong "$file" "$((maxlen - 1))" "B" "$maxlen"
+	assert_grep_absent "$file" "B" || status=1
 
-	# String containing our list of bits to set
-	TEST_STR=$BIT
+	# sysctl stays NULL terminated on overwrite
+	printf '%s' "$baseline" > "$file"
+	write_overlong "$file" "$((maxlen - 1))" "BB" "$((maxlen + 1))"
+	assert_grep_absent "$file" "B" || status=1
 
-	# build up the string
-	while [ "${#TEST_STR}" -le "$LENGTH" ]; do
-		# Make sure next entry is discontiguous,
-		# skip ahead at least 2
-		BIT=$((BIT + $((2 + RANDOM % 10))))
+	return "$status"
+}
+
+test_string_dostring()
+{
+	local t="${SYSCTL}/string_0001"
+	local baseline="(none)" val="Testing sysctl" maxlen=65
 
-		# Add new bit to the list
-		TEST_STR="${TEST_STR},${BIT}"
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
 
-		# Randomly make it a range
-		if [ "$((RANDOM % 2))" -eq "1" ]; then
-			RANGE_END=$((BIT + $((1 + RANDOM % 10))))
-			TEST_STR="${TEST_STR}-${RANGE_END}"
-			BIT=$RANGE_END
+	assert_write_patterns "$t" "$baseline" "$val" || RET=$KSFT_FAIL
+	assert_string_write_patterns "$t" "$baseline" "$val" "$maxlen" || RET=$KSFT_FAIL
+}
+
+# Emit a random sysctl bit map
+random_bitmap_spec()
+{
+	local length=$((RANDOM % 65000))
+	local bit=$((RANDOM % 1024))
+	local spec=$bit
+	local range_end
+
+	while [ "${#spec}" -le "$length" ]; do
+		# Keep entries discontiguous, skip ahead by at least 2.
+		bit=$((bit + 2 + RANDOM % 10))
+		spec="${spec},${bit}"
+
+		if [ "$((RANDOM % 2))" -eq 1 ]; then
+			range_end=$((bit + 1 + RANDOM % 10))
+			spec="${spec}-${range_end}"
+			bit=$range_end
 		fi
 	done
 
-	echo -n "Checking bitmap handler ... "
-	TEST_FILE=$(mktemp)
-	echo -n "$TEST_STR" > $TEST_FILE
-
-	cat $TEST_FILE > $TARGET 2> /dev/null
-	if [ $? -ne 0 ]; then
-		echo "FAIL" >&2
-		rc=1
-		test_rc
-	fi
-
-	if ! verify_diff_proc_file "$TARGET" "$TEST_FILE"; then
-		echo "FAIL" >&2
-		rc=1
-	else
-		echo "OK"
-		rc=0
-	fi
-	test_rc
+	echo -n "$spec"
 }
 
-sysctl_test_0001()
+# Do *not* prefix with "test_". All autogenerate bitmap tests call this helper
+bitmap_range_check_once()  # <iter>
 {
-	TARGET="${SYSCTL}/$(get_test_target 0001)"
-	reset_vals
-	ORIG=$(cat "${TARGET}")
-	TEST_STR=$(( $ORIG + 1 ))
+	local t="${SYSCTL}/bitmap_0001"
+	local spec_file seed
 
-	run_numerictests
-	run_wideint_tests
-	run_limit_digit
-}
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
 
-sysctl_test_0002()
-{
-	TARGET="${SYSCTL}/$(get_test_target 0002)"
-	reset_vals
-	ORIG=$(cat "${TARGET}")
-	TEST_STR="Testing sysctl"
-	# Only string sysctls support seeking/appending.
-	MAXLEN=65
+	seed=$((BITMAP_SEED + $1))
+	RANDOM=$seed
 
-	run_numerictests
-	run_stringtests
-}
+	spec_file=$(mktemp)
+	random_bitmap_spec > "$spec_file"
 
-sysctl_test_0003()
-{
-	TARGET="${SYSCTL}/$(get_test_target 0003)"
-	reset_vals
-	ORIG=$(cat "${TARGET}")
-	TEST_STR=$(( $ORIG + 1 ))
+	if ! cat "$spec_file" > "$t" 2>/dev/null; then
+		ktap_print_msg "$t: write of random bitmap spec rejected (seed $seed)"
+		RET=$KSFT_FAIL
+	elif ! assert_diff_proc_file "$t" "$spec_file"; then
+		ktap_print_msg "$t: readback mismatch (seed $seed)"
+		RET=$KSFT_FAIL
+	fi
 
-	run_numerictests
-	run_wideint_tests
-	run_limit_digit
-	run_limit_digit_int
+	rm -f "$spec_file"
 }
 
-sysctl_test_0004()
+test_unregister_removes_dir()
 {
-	TARGET="${SYSCTL}/$(get_test_target 0004)"
-	reset_vals
-	ORIG=$(cat "${TARGET}")
-	TEST_STR=$(( $ORIG + 1 ))
+	local t="${SYSCTL}/unregister_error"
 
-	run_numerictests
-	run_wideint_tests
-	run_limit_digit
-	run_limit_digit_uint
+	if [[ -d "$t" ]]; then
+		ktap_print_msg "$t: directory still exists, expected it to be unregistered"
+		RET=$KSFT_FAIL
+	fi
 }
 
-sysctl_test_0005()
+test_mount_point_error()
 {
-	TARGET="${SYSCTL}/$(get_test_target 0005)"
-	reset_vals
-	ORIG=$(cat "${TARGET}")
+	local t="${SYSCTL}/mnt/mnt_error"
 
-	run_limit_digit_int_array
-}
-
-sysctl_test_0006()
-{
-	TARGET="${SYSCTL}/$(get_test_target 0006)"
-	reset_vals
-	ORIG=""
-	run_bitmaptest
+	if [[ -d "$t" ]]; then
+		ktap_print_msg "$t: directory unexpectedly created"
+		RET=$KSFT_FAIL
+	fi
 }
 
-sysctl_test_0007()
+test_empty_dir_registration()
 {
-	TARGET="${SYSCTL}/$(get_test_target 0007)"
-	echo -n "Testing if $TARGET is set to 1 ... "
-
-	if [ ! -f $TARGET ]; then
-		echo -e "SKIPPING\n$TARGET is not present"
-		return $ksft_skip
-	fi
-
-	if [ -d $DIR ]; then
-		echo -e "SKIPPING\nTest only possible if sysctl_test is built-in, not module:"
-		cat $TEST_DIR/config >&2
-		return $ksft_skip
-	fi
-
-	ORIG=$(cat "${TARGET}")
+	local t="${SYSCTL}/empty_add"
 
-	if [ x$ORIG = "x1" ]; then
-		echo "OK"
-		return 0
+	if [[ ! -d "$t" ]]; then
+		ktap_print_msg "$t: directory was not created"
+		RET=$KSFT_FAIL
+		return
 	fi
-
-	if [ ! -f /proc/cmdline ]; then
-		echo -e "SKIPPING\nThere is no /proc/cmdline to check for parameter"
-		return $ksft_skip
-	fi
-
-	FOUND=$(grep -c "sysctl[./]debug[./]test_sysctl[./]boot_int=1" /proc/cmdline)
-	if [ $FOUND = "1" ]; then
-		echo -e "FAIL\nKernel param found but $TARGET is not 1." >&2
-		rc=1
-		test_rc
+	if [[ ! -d "$t/empty" ]]; then
+		ktap_print_msg "$t/empty: directory was not created"
+		RET=$KSFT_FAIL
 	fi
-
-	echo -e "SKIPPING\nExpected kernel parameter missing."
-	echo "Kernel must be booted with parameter: sysctl.debug.test_sysctl.boot_int=1"
-	return $ksft_skip
 }
 
-sysctl_test_0008()
+test_u8_range_check()
 {
-	TARGET="${SYSCTL}/$(get_test_target 0008)"
-	echo -n "Testing if $TARGET is matched in kernel ... "
-
-	if [ ! -f $TARGET ]; then
-		echo -e "SKIPPING\n$TARGET is not present"
-		return $ksft_skip
-	fi
-
-	ORIG_VALUE=$(cat "${TARGET}")
+	local t="${SYSCTL}/u8_valid"
 
-	if [ $ORIG_VALUE -ne 1 ]; then
-		echo "FAIL" >&2
-		rc=1
-		test_rc
+	if [[ ! -f "$t" ]]; then
+		ktap_print_msg "$t: file was not created"
+		RET=$KSFT_FAIL
+		return
 	fi
 
-	echo "OK"
-	return 0
+	assert_dmesg_count "u8_over range value" 1 || RET=$KSFT_FAIL
+	assert_dmesg_count "u8_under range value" 1 || RET=$KSFT_FAIL
 }
 
-sysctl_test_0009()
+test_boot_param_int()
 {
-	TARGET="${SYSCTL}/$(get_test_target 0009)"
-	echo -n "Testing if $TARGET unregistered correctly ... "
-	if [ -d $TARGET ]; then
-		echo "FAIL" >&2
-		rc=1
-		test_rc
-	fi
+	local t="${SYSCTL}/boot_int"
+	local orig found
 
-	echo "OK"
-	return 0
-}
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
 
-sysctl_test_0010()
-{
-	TARGET="${SYSCTL}/$(get_test_target 0010)"
-	echo -n "Testing that $TARGET was not created ... "
-	if [ -d $TARGET ]; then
-		echo "FAIL" >&2
-		rc=1
-		test_rc
+	# Boot cmdline params only apply when test_sysctl is built in, not
+	# loaded as a module.
+	if [[ -d "$MODULE_DIR" ]]; then
+		ktap_print_msg "$t: test only possible if test_sysctl is built-in, not a module"
+		RET=$KSFT_SKIP
+		return
 	fi
 
-	echo "OK"
-	return 0
-}
+	orig=$(cat "$t")
+	if [[ "$orig" == "1" ]]; then
+		return
+	fi
 
-sysctl_test_0011()
-{
-	TARGET="${SYSCTL}/$(get_test_target 0011)"
-	echo -n "Testing empty dir handling in ${TARGET} ... "
-	if [ ! -d ${TARGET} ]; then
-		echo -e "FAIL\nCould not create ${TARGET}" >&2
-		rc=1
-		test_rc
+	if [[ ! -f /proc/cmdline ]]; then
+		ktap_print_msg "$t: no /proc/cmdline to check for the boot parameter"
+		RET=$KSFT_SKIP
+		return
 	fi
 
-	TARGET2="${TARGET}/empty"
-	if [ ! -d ${TARGET2} ]; then
-		echo -e "FAIL\nCould not create ${TARGET2}" >&2
-		rc=1
-		test_rc
+	found=$(grep -c "sysctl[./]debug[./]test_sysctl[./]boot_int=1" /proc/cmdline)
+	if [[ "$found" == "1" ]]; then
+		ktap_print_msg "$t: kernel param found on cmdline but value is not 1"
+		RET=$KSFT_FAIL
+		return
 	fi
 
-	echo "OK"
-	return 0
+	ktap_print_msg "$t: kernel not booted with sysctl.debug.test_sysctl.boot_int=1"
+	RET=$KSFT_SKIP
 }
 
-sysctl_test_0012()
+test_sysctl_macro_match()
 {
-	TARGET="${SYSCTL}/$(get_test_target 0012)"
-	echo -n "Testing u8 range check in sysctl table check in ${TARGET} ... "
-	if [ ! -f ${TARGET} ]; then
-		echo -e "FAIL\nCould not create ${TARGET}" >&2
-		rc=1
-		test_rc
-	fi
+	local t="${SYSCTL}/match_int"
 
-	local u8over_msg=$(dmesg | grep "u8_over range value" | wc -l)
-	if [ ! ${u8over_msg} -eq 1 ]; then
-		echo -e "FAIL\nu8 overflow not detected" >&2
-		rc=1
-		test_rc
-	fi
+	[[ -f "$t" ]] || { RET=$KSFT_SKIP; return; }
 
-	local u8under_msg=$(dmesg | grep "u8_under range value" | wc -l)
-	if [ ! ${u8under_msg} -eq 1 ]; then
-		echo -e "FAIL\nu8 underflow not detected" >&2
-		rc=1
-		test_rc
-	fi
-
-	echo "OK"
-	return 0
+	assert_content "$t" "1" || RET=$KSFT_FAIL
 }
 
-sysctl_test_0013()
+run_one()
 {
-	TARGET="${SYSCTL}/$(get_test_target 0013)"
-	reset_vals
+	local name=$1
 
-	run_int_array_no_partial_update
-}
+	# Subshell: a test cannot leak vars/cwd/traps into the next one, and an
+	# accidental `exit` inside a test kills only its own subshell.
+	( RET=$KSFT_PASS; "$name"; exit $RET )
 
-list_tests()
-{
-	echo "Test ID list:"
-	echo
-	echo "TEST_ID x NUM_TEST"
-	echo "TEST_ID:   Test ID"
-	echo "NUM_TESTS: Recommended number of times to run the test"
-	echo
-	echo "0001 x $(get_test_count 0001) - tests proc_dointvec_minmax()"
-	echo "0002 x $(get_test_count 0002) - tests proc_dostring()"
-	echo "0003 x $(get_test_count 0003) - tests proc_dointvec()"
-	echo "0004 x $(get_test_count 0004) - tests proc_douintvec()"
-	echo "0005 x $(get_test_count 0005) - tests proc_douintvec() array"
-	echo "0006 x $(get_test_count 0006) - tests proc_do_large_bitmap()"
-	echo "0007 x $(get_test_count 0007) - tests setting sysctl from kernel boot param"
-	echo "0008 x $(get_test_count 0008) - tests sysctl macro values match"
-	echo "0009 x $(get_test_count 0009) - tests sysct unregister"
-	echo "0010 x $(get_test_count 0010) - tests sysct mount point"
-	echo "0011 x $(get_test_count 0011) - tests empty directories"
-	echo "0012 x $(get_test_count 0012) - tests range check for u8 proc_handler"
-	echo "0013 x $(get_test_count 0013) - tests partially update vectors on error"
+	case $? in
+	"$KSFT_PASS") ktap_test_pass "$name" ;;
+	"$KSFT_SKIP") ktap_test_skip "$name" ;;
+	*)          ktap_test_fail "$name" ;;
+	esac
 }
 
 usage()
 {
-	NUM_TESTS=$(grep -o ' ' <<<"$ALL_TESTS" | grep -c .)
-	let NUM_TESTS=$NUM_TESTS+1
-	MAX_TEST=$(printf "%04d\n" $NUM_TESTS)
-	echo "Usage: $0 [ -t <4-number-digit> ] | [ -w <4-number-digit> ] |"
-	echo "		 [ -s <4-number-digit> ] | [ -c <4-number-digit> <test- count>"
-	echo "           [ all ] [ -h | --help ] [ -l ]"
-	echo ""
-	echo "Valid tests: 0001-$MAX_TEST"
-	echo ""
-	echo "    all     Runs all tests (default)"
-	echo "    -t      Run test ID the recommended number of times"
-	echo "    -w      Watch test ID run until it runs into an error"
-	echo "    -c      Run test ID once"
-	echo "    -s      Run test ID x test-count number of times"
-	echo "    -l      List all test ID list"
-	echo " -h|--help  Help"
-	echo
-	echo "If an error every occurs execution will immediately terminate."
-	echo "If you are adding a new test try using -w <test-ID> first to"
-	echo "make sure the test passes a series of tests."
-	echo
-	echo Example uses:
-	echo
-	echo "$TEST_NAME.sh            -- executes all tests"
-	echo "$TEST_NAME.sh -t 0002    -- Executes test ID 0002 the recommended number of times"
-	echo "$TEST_NAME.sh -w 0002    -- Watch test ID 0002 run until an error occurs"
-	echo "$TEST_NAME.sh -s 0002    -- Run test ID 0002 once"
-	echo "$TEST_NAME.sh -c 0002 3  -- Run test ID 0002 three times"
-	echo
-	list_tests
-	exit 1
-}
+	cat <<-EOF
+	Usage: $0 [-r N] [-l] [-t T] [-s N] [-h|--help]
 
-function test_num()
-{
-	re='^[0-9]+$'
-	if ! [[ $1 =~ $re ]]; then
-		usage
-	fi
-}
-function remove_leading_zeros()
-{
-	echo $1 | sed 's/^0*//'
-}
+	Runs every auto-discovered test_* function. Setting SYSCTL_TESTS will
+	override the default and passing -t will override both env var and the
+	default.
 
-function get_test_count()
-{
-	test_num $1
-	awk_field=$(remove_leading_zeros $1)
-	TEST_DATA=$(echo $ALL_TESTS | awk '{print $'$awk_field'}')
-	echo ${TEST_DATA} | awk -F":" '{print $2}'
-}
+	    -r N          repeat selected tests N times (default 1)
+	    -l            list discovered tests
+	    -t T          space separated tests list. For example "test_1 test_2"
+	    -s N          base seed for the randomized bitmap iterations.
+	    -h, --help    help
 
-function get_test_enabled()
-{
-	test_num $1
-	awk_field=$(remove_leading_zeros $1)
-	TEST_DATA=$(echo $ALL_TESTS | awk '{print $'$awk_field'}')
-	echo ${TEST_DATA} | awk -F":" '{print $3}'
+	    SYSCTL_TESTS='test_1 test_2' $0  run only the named tests
+	EOF
 }
 
-function get_test_target()
+list_tests()
 {
-	test_num $1
-	awk_field=$(remove_leading_zeros $1)
-	TEST_DATA=$(echo $ALL_TESTS | awk '{print $'$awk_field'}')
-	echo ${TEST_DATA} | awk -F":" '{print $4}'
+	echo "Discovered tests:"
+	local t
+	for t in $ALL_TESTS; do
+		echo "  $t"
+	done
 }
 
-function get_test_skip_no_target()
+check_reqs()
 {
-	test_num $1
-	awk_field=$(remove_leading_zeros $1)
-	TEST_DATA=$(echo $ALL_TESTS | awk '{print $'$awk_field'}')
-	echo ${TEST_DATA} | awk -F":" '{print $5}'
-}
+	local uid
+	uid=$(id -u)
 
-function skip_test()
-{
-	TEST_ID=$1
-	TEST_TARGET=$2
-	if target_exists $TEST_TARGET $TEST_ID; then
-		TEST_SKIP=$(get_test_skip_no_target $TEST_ID)
-		if [[ $TEST_SKIP -eq "1" ]]; then
-			echo "Target $TEST_TARGET for test $TEST_ID does not exist ... SKIPPING"
-			return 0
-		fi
+	if [ "$uid" -ne 0 ]; then
+		ktap_skip_all "must be run as root"
+		exit "$KSFT_SKIP"
 	fi
-	return 1
-}
 
-function run_all_tests()
-{
-	for i in $ALL_TESTS ; do
-		TEST_ID=${i%:*:*:*:*}
-		ENABLED=$(get_test_enabled $TEST_ID)
-		TEST_COUNT=$(get_test_count $TEST_ID)
-		TEST_TARGET=$(get_test_target $TEST_ID)
+	if ! which getconf > /dev/null 2>&1; then
+		ktap_skip_all "$0: You need getconf installed"
+		exit "$KSFT_SKIP"
+	fi
 
-		if [[ $ENABLED -eq "1" ]]; then
-			test_case $TEST_ID $TEST_COUNT $TEST_TARGET
-		fi
-	done
+	if ! which diff > /dev/null 2>&1; then
+		ktap_skip_all "$0: You need diff installed"
+		exit "$KSFT_SKIP"
+	fi
 }
 
-function watch_log()
+check_args()  # <repeat> <selected> <seed>
 {
-	if [ $# -ne 3 ]; then
-		clear
+	local repeat_arg="$1"
+	local selected_arg="$2"
+	local seed_arg="$3"
+	local t
+
+	if [ -z "$selected_arg" ]; then
+		ktap_exit_fail_msg "no test selected"
 	fi
-	date
-	echo "Running test: $2 - run #$1"
-}
 
-function watch_case()
-{
-	i=0
-	while [ 1 ]; do
+	if ! [[ "$repeat_arg" =~ ^[0-9]+$ ]]; then
+		ktap_exit_fail_msg "repeat argument '$repeat_arg' is not a number"
+	fi
+
+	if ! [[ "$seed_arg" =~ ^[0-9]+$ ]]; then
+		ktap_exit_fail_msg "seed argument '$seed_arg' is not a number"
+	fi
 
-		if [ $# -eq 1 ]; then
-			test_num $1
-			watch_log $i ${TEST_NAME}_test_$1
-			${TEST_NAME}_test_$1
-		else
-			watch_log $i all
-			run_all_tests
+	for t in $selected_arg; do
+		if ! declare -F "$t" > /dev/null; then
+			ktap_exit_fail_msg "unknown selected test '$t'"
 		fi
-		let i=$i+1
 	done
 }
 
-function test_case()
+allow_user_defaults()
 {
-	TEST_ID=$1
-	NUM_TESTS=$2
-	TARGET=$3
-
-	if skip_test $TEST_ID $TARGET; then
-		return
+	if [ -z "${MODULE_DIR}" ]; then
+		MODULE_DIR="/sys/module/test_sysctl/"
+	fi
+	if [ -z "${SYSCTL}" ]; then
+		SYSCTL="/proc/sys/debug/test_sysctl"
+	fi
+	if [ -z "${PROD_SYSCTL}" ]; then
+		PROD_SYSCTL="/proc/sys"
+	fi
+	if [ -z "${WRITES_STRICT}" ]; then
+		WRITES_STRICT="${PROD_SYSCTL}/kernel/sysctl_writes_strict"
+	fi
+	if [ -z "${BITMAP_ITERATIONS}" ]; then
+		BITMAP_ITERATIONS=50
+	fi
+	# Set seed for bitmap random tests
+	if [ -z "${BITMAP_SEED}" ]; then
+		BITMAP_SEED=$RANDOM
 	fi
-
-	i=0
-	while [ $i -lt $NUM_TESTS ]; do
-		test_num $TEST_ID
-		watch_log $i ${TEST_NAME}_test_${TEST_ID} noclear
-		RUN_TEST=${TEST_NAME}_test_${TEST_ID}
-		$RUN_TEST
-		let i=$i+1
-	done
 }
 
-function parse_args()
+check_production_sysctl_writes_strict()
 {
-	if [ $# -eq 0 ]; then
-		run_all_tests
+	if [ ! -e "${WRITES_STRICT}" ]; then
+		ktap_print_msg "${WRITES_STRICT} missing, skipping strict write check (old kernel?)"
 	else
-		if [[ "$1" = "all" ]]; then
-			run_all_tests
-		elif [[ "$1" = "-w" ]]; then
-			shift
-			watch_case $@
-		elif [[ "$1" = "-t" ]]; then
-			shift
-			test_num $1
-			test_case $1 $(get_test_count $1) $(get_test_target $1)
-		elif [[ "$1" = "-c" ]]; then
-			shift
-			test_num $1
-			test_num $2
-			test_case $1 $2 $(get_test_target $1)
-		elif [[ "$1" = "-s" ]]; then
-			shift
-			test_case $1 1 $(get_test_target $1)
-		elif [[ "$1" = "-l" ]]; then
-			list_tests
-		elif [[ "$1" = "-h" || "$1" = "--help" ]]; then
-			usage
-		else
-			usage
+		old_strict=$(cat "${WRITES_STRICT}")
+		if [ "$old_strict" != "1" ]; then
+			ktap_print_msg "forcing ${WRITES_STRICT} to 1 (was ${old_strict})"
+			echo "1" > "${WRITES_STRICT}"
 		fi
 	fi
+
+	if [ -z "${PAGE_SIZE}" ]; then
+		PAGE_SIZE=$(getconf PAGESIZE)
+	fi
+	if [ -z "${MAX_DIGITS}" ]; then
+		MAX_DIGITS=$((PAGE_SIZE / 8))
+	fi
+	if [ -z "${INT_MAX}" ]; then
+		INT_MAX=$(getconf INT_MAX)
+	fi
+	if [ -z "${UINT_MAX}" ]; then
+		UINT_MAX=$(getconf UINT_MAX)
+	fi
+}
+
+load_req_mod()
+{
+	if [ ! -d "${SYSCTL}" ]; then
+		if ! modprobe -q -n "${TEST_DRIVER}"; then
+			ktap_skip_all "module ${TEST_DRIVER} not found. \
+				You must set CONFIG_TEST_SYSCTL=m in your kernel"
+			exit "$KSFT_SKIP"
+		fi
+		if ! modprobe "${TEST_DRIVER}"; then
+			ktap_exit_fail_msg "modprobe ${TEST_DRIVER} failed"
+		fi
+	fi
+}
+
+# Cleanup only! Do not call exit here or it will silently override KTAP exit status
+restore_sysctl_writes_strict()
+{
+	if [ -n "${old_strict}" ]; then
+		echo "${old_strict}" > "${WRITES_STRICT}"
+	fi
 }
 
-test_reqs
 allow_user_defaults
+
+# Each bitmap iteration is one function to generate one KTAP report per iteration
+for i in $(seq 1 "$BITMAP_ITERATIONS"); do
+	eval "test_bitmap_range_check_$(printf '%02d' "$i")() \
+		{ \
+			bitmap_range_check_once $i; \
+		}"
+done
+
+# Discover test_* functions above this line
+ALL_TESTS=$(declare -F | awk '{print $3}' | grep '^test_' | sort)
+
+REPEAT=1
+while [ $# -gt 0 ]; do
+	case "$1" in
+	-r )
+		shift
+		REPEAT=$1
+		;;
+	-l )
+		list_tests
+		exit 0
+		;;
+	-h | --help )
+		usage
+		exit 0
+		;;
+	-t )
+		shift
+		SYSCTL_TESTS="$1"
+		;;
+	-s )
+		shift
+		BITMAP_SEED="$1"
+		;;
+	* )
+		usage
+		exit 1
+		;;
+	esac
+	shift
+done
+
+SELECTED=${SYSCTL_TESTS-$ALL_TESTS}
+
+ktap_print_header
+trap restore_sysctl_writes_strict EXIT
+check_args "$REPEAT" "$SELECTED" "$BITMAP_SEED"
+check_reqs
 check_production_sysctl_writes_strict
 load_req_mod
 
-trap "test_finish" EXIT
+ktap_print_msg "bitmap base seed: $BITMAP_SEED (replay with -s $BITMAP_SEED)"
 
-parse_args $@
+ktap_set_plan "$(( $(wc -w <<< "$SELECTED") * REPEAT ))"
 
-exit 0
+for ((i = 0; i < REPEAT; i++)); do
+	for t in $SELECTED; do
+		run_one "$t"
+	done
+done
+
+ktap_finished

---
base-commit: 99156fbf3562bed74aa57d93b0b3eeec7c7f1ca6
change-id: 20260914-lklm-sysctl-selftests-5007abea267b

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

