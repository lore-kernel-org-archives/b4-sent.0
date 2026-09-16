From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:32:53 -0600
Subject: [PATCH v10 01/38] selftests/dyndbg: Add kselftest script to verify
 dynamic-debug
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-1-af4cf4767707@gmail.com>
References: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
In-Reply-To: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Jonathan Corbet <corbet@net.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=38251;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=Ub4ktuAINE2FKme3hh9OJfirPozcrLqOhO50Io9xP8M=;
 b=3etiamfd6J4GR+qYLydKJRSwXD9of0xj2VG0TSitWd+XAR2NrIQWZZMbWkI3NUv8RtEVqyTVj
 NbfsYyiWMZWDsHRWDT2hNS8dBkXScwQTPrB1GWDxBxg8cTe3wfLcfkP
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ad-hoc dynamic debug testing by grepping /proc/dynamic_debug/control for
counts (e.g. counting " =pmf ") is brittle: multi-query commands,
partial string matches, and broad module queries inadvertently alter
unrelated callsites and hide syntax regressions.

Introduce dyndbg_selftest.sh and reusable helper library
syslog_hash_validation.sh using "the canonical test" model
(baseline -> change -> verify) with two complementary validation
mechanisms:

0. Spatial control-file slicing:
   capture_before captures the baseline state for a target range
   ["$range"]. After applying "$query", verify_after_change computes
   a normalized diff against /proc/dynamic_debug/control, stripping
   source line numbers and hunk headers. This renders checksum
   verification immune to upstream C line churn while catching
   unintended state drift.

1. Temporal syslog slicing:
   log_start and log_stop emit bookend markers into /dev/kmsg around
   an executed workload, slicing exact dmesg prints while stripping
   system timestamp/CPU/PID headers to verify reproducible output.

This baseline introduces and executes the 3 built-in feature tests:
0. FT_grammar_ok:
   Validates valid syntax (keywords, line ranges, and colon-delimited
   file:line / file:func specs) using side-effect-free flags ("+_").
1. FT_grammar_errs:
   Validates core parser error handling, token limits, and EINVAL paths.
2. FT_basic_queries:
   Validates direct queries targeting the built-in kernel/params.c file.

Tests are verified against an embedded GOLDEN_RECORDS database of MD5
fingerprints. Downstream modular classmap tests
(FT_classmap_inheritance, FT_test_classes, FT_modprobe_w_param) are
left for commits that introduce corresponding kernel infrastructure.

Runtime configuration:
- V=0|1|2: output verbosity (0=silent pass, 1=summary, 2=full diff).
- K=0|1|2: golden record mode (0=strict fail, 1=fake pass, 2=soft pass).

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v9:
. sanitize "$K" integer input alongside "$V".
. drop duplicate ifrmmod function declaration.
. replace undeclared "$error_msg" with "$output" in handle_exit_code().
. rework LACK_DD_BUILTIN record filtering to check label column ($3).
. truncate temp files (: > "$SEEN_HASHES_FILE") instead of rm -f
  under mktemp.
. add handling for K=2 (silent soft-pass mode) to suppress
  DRIFT/UNREG blocks.

v8: sashiko prompted cleanups
. dont-skip-nomod-config
. mktmp-in-test-script
. fn-renames/cleanups: log_ddcmd, my_modname, set_param,
  verify_control_slice
---
 MAINTAINERS                                        |   1 +
 tools/testing/selftests/dynamic_debug/Makefile     |  10 +
 tools/testing/selftests/dynamic_debug/config       |   8 +
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 499 +++++++++++++++++++++
 .../dynamic_debug/syslog_hash_validation.sh        | 393 ++++++++++++++++
 5 files changed, 911 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c72453974dd7..74790be45d06 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9260,6 +9260,7 @@ S:	Maintained
 F:	include/linux/dynamic_debug.h
 F:	lib/dynamic_debug.c
 F:	lib/test_dynamic_debug.c
+F:	tools/testing/selftests/dynamic_debug/
 
 DYNAMIC INTERRUPT MODERATION
 M:	Tal Gilboa <talgi@nvidia.com>
diff --git a/tools/testing/selftests/dynamic_debug/Makefile b/tools/testing/selftests/dynamic_debug/Makefile
new file mode 100644
index 000000000000..d998f485a9bc
--- /dev/null
+++ b/tools/testing/selftests/dynamic_debug/Makefile
@@ -0,0 +1,10 @@
+# SPDX-License-Identifier: GPL-2.0-only
+# borrowed from Makefile for user memory selftests
+
+# No binaries, but make sure arg-less "make" doesn't trigger "run_tests"
+all:
+
+TEST_PROGS := dyndbg_selftest.sh
+TEST_FILES := syslog_hash_validation.sh
+
+include ../lib.mk
diff --git a/tools/testing/selftests/dynamic_debug/config b/tools/testing/selftests/dynamic_debug/config
new file mode 100644
index 000000000000..ec478b17873d
--- /dev/null
+++ b/tools/testing/selftests/dynamic_debug/config
@@ -0,0 +1,8 @@
+
+# basic tests ref the builtin params module
+CONFIG_DYNAMIC_DEBUG=y
+
+# more testing is possible with these,
+# but insisting on them here skips testing entirely for such configs
+# CONFIG_TEST_DYNAMIC_DEBUG=m
+# CONFIG_TEST_DYNAMIC_DEBUG_SUBMOD=m
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
new file mode 100755
index 000000000000..73c2a4b07bd3
--- /dev/null
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -0,0 +1,499 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0-only
+
+# Standard kselftest exit codes
+ksft_pass=0
+ksft_fail=1
+ksft_skip=4
+
+ESC=$'\033'
+RED="${ESC}[0;31m"
+GREEN="${ESC}[0;32m"
+YELLOW="${ESC}[0;33m"
+BLUE="${ESC}[0;34m"
+MAGENTA="${ESC}[0;35m"
+CYAN="${ESC}[0;36m"
+NC="${ESC}[0;0m"
+# Environment Controls:
+#   V=0,1,2 : Verbosity (0=concise summary, 1=verified assertions, 2=full captured outputs)
+#   K=0     : Strict mode (fails with exit 1 on checksum drift or stale records)
+#   K=1     : Soft-pass mode (prints DRIFT/STALE diffs, exits 0 with 'fake success')
+#   K=2     : Silent soft-pass mode (suppresses DRIFT/STALE diffs, exits 0 with 'fake success')
+V=${V:=0}
+K=${K:=0}
+
+# Sanitize V and K to ensure they are valid integers
+if [[ ! "$V" =~ ^[0-9]+$ ]]; then
+    V=0
+fi
+if [[ ! "$K" =~ ^[0-9]+$ ]]; then
+    K=0
+fi
+
+function v_echo {
+    [ "${V:-0}" -ge 1 ] && echo -e "$@"
+}
+
+[ -e /proc/dynamic_debug/control ] || {
+    echo -e "${RED}: this test requires CONFIG_DYNAMIC_DEBUG=y ${NC}"
+    exit $ksft_skip # nothing to test here, no good reason to fail.
+}
+
+lsmod >/dev/null 2>&1 || {
+    echo -e "${RED}: lsmod requires /proc/modules ${NC}"
+    # exit $ksft_skip # maybe later we can do more
+}
+
+# need info to avoid failures due to untestable configs
+
+[ -f "$KCONFIG_CONFIG" ] || KCONFIG_CONFIG=".config"
+if [ -f "$KCONFIG_CONFIG" ]; then
+    v_echo "# consulting KCONFIG_CONFIG: $KCONFIG_CONFIG"
+    grep -q "CONFIG_DYNAMIC_DEBUG=y" $KCONFIG_CONFIG ; LACK_DD_BUILTIN=$?
+    grep -q "CONFIG_TEST_DYNAMIC_DEBUG=m" $KCONFIG_CONFIG ; LACK_TMOD=$?
+else
+    # if no config, try runtime probes
+    modprobe -n test_dynamic_debug 2>/dev/null ; LACK_TMOD=$?
+    # assume builtin dyndbg if control exists (checked above)
+    LACK_DD_BUILTIN=0
+fi
+
+function ifrmmod {
+    [ "${LACK_TMOD:-0}" -eq 1 ] && return
+    grep -q "^$1 " /proc/modules 2>/dev/null && rmmod $1
+}
+
+# Clean up any leftover loaded test modules at initialization
+ifrmmod test_dynamic_debug
+
+# ===========================================================================
+# TESTING STRATEGY 1.
+#   Change and observe control-file settings:
+#     ddcmd: ie echo $dd_query_cmd > /proc/dynamic_debug/control
+#     read back control, count changes due to query_cmd
+# ===========================================================================
+DDCMD_LOG=""	# accumulate
+
+function log_ddcmd {
+    local cmd="$1"
+    if [ "${IN_BOOKEND:-0}" -eq 1 ] && [ -n "$DDCMD_LOG" ]; then
+        DDCMD_LOG="${DDCMD_LOG}; $cmd"
+    else
+        DDCMD_LOG="$cmd"
+    fi
+}
+
+function my_modprobe {
+    log_ddcmd "modprobe $*"
+    modprobe "$@"
+}
+
+function set_param {
+    local val="$1"
+    local path="$2"
+    log_ddcmd "echo $val > $path"
+    echo "$val" > "$path"
+}
+
+function ddcmd () {
+    # ddcmd <query_args> [range_pattern] [pass|fail|log]
+    local args="$1"
+    local range="$2"
+    local action="${3:-pass}"
+    local exp_exit=0
+
+    [ "$action" = "fail" ] && exp_exit=1
+    log_ddcmd "$args"
+
+    # Update cumulative state-machine lineage
+    if [[ "$args" == *"=_"* ]]; then
+        CUMULATIVE_DDCMDS="$args"
+    else
+        CUMULATIVE_DDCMDS="${CUMULATIVE_DDCMDS}; $args"
+    fi
+
+    [ "$action" != "pass" ] && log_start
+    [ -n "$range" ] && capture_before "$range"
+
+    output=$( (echo "$args" > /proc/dynamic_debug/control) 2>&1 )
+    handle_exit_code $BASH_LINENO $FUNCNAME $? $exp_exit
+
+    [ "$action" != "pass" ] && log_stop
+    [ -n "$range" ] && verify_after_change
+}
+
+function ddcmd_err () {
+    # ddcmd_err <query_args>
+    # Semantic wrapper for parser syntax & error validation
+    ddcmd "$1" "" fail
+}
+
+function ddcmd_load () {
+    # ddcmd_load <query_args> <range_pattern> <workload_param_path> <workload_val>
+    # Semantic wrapper for end-to-end filter setup and live workload logging
+    local query="$1"
+    local range="$2"
+    local param_path="$3"
+    local val="$4"
+
+    # 1. Setup the control filters (using positional ddcmd range-check)
+    echo  "$query" "$range"
+    ddcmd "$query" "$range"
+
+    # 2. Execute the workload and capture syslog prints
+    log_start
+    echo "$val" > "$param_path"
+    log_stop
+}
+
+function handle_exit_code() {
+    local exp_exit_code=0
+    [ $# == 4 ] && exp_exit_code=$4
+    if [ "$3" -ne $exp_exit_code ]; then
+        echo -e "${RED}: $BASH_SOURCE:$1 $2() " \
+            "expected to exit with code $exp_exit_code, got $3${NC}"
+	[ "$3" == 1 ] && echo "Error: '$output'"
+        exit $ksft_fail
+    fi
+}
+
+# ==============================================================================
+# TESTING STRATEGY 2.
+#   do 1 to setup test expectations.
+#   run logging-workload
+#   capture output
+#   hash-validate it against GOLDEN_SAMPLE db (at file end)
+#
+# ==============================================================================
+# Source hash-based validation and state verification helper library
+DIR="$(dirname "$(readlink -f "$0")")"
+. "$DIR/syslog_hash_validation.sh"
+
+# Define target validation file path
+CONTROL_FILE="/proc/dynamic_debug/control"
+
+# App-specific wrappers mapping to generic library helpers
+function verify_control_slice {
+    # $1 - pattern to slice
+    # $2 - optional extra args
+    verify_file_slice "$1" $CONTROL_FILE "$2"
+}
+
+function slice_and_hash_ddctrl {
+    local slice=$(slice_by_grep "$1" "$CONTROL_FILE" | strip_control_linenos)
+    echo "$slice" | tr -d '\r' | md5sum | cut -d' ' -f1
+}
+
+# ==============================================================================
+# FEATURE TESTS (FT_*)
+#
+# test legal queries which should execute and return 0 (success)
+# so we dont look for errors in dmesg
+function FT_grammar_ok {
+    v_echo "${GREEN}# GRAMMAR_OK_TESTS ${NC}"
+    ddcmd "+_"
+    ddcmd "-_"
+
+    # use 4 keywords (max 9 words inc flags)
+    ddcmd "module foo file bar.c func buz class D2_CORE +_"	# 4 keywords
+    #ddcmd "module foo file bar.c func buz class D2 line 100 +_" # 5 keywords
+
+    # 3. Dedicated lineno range grammar assertions (side-effect-free proofs)
+    ddcmd "line 42 +_"		# test exact line syntax
+    ddcmd "line 10- +_"		# test open-ended line range (starting at 10)
+    ddcmd "line -100 +_"	# test open-ended line range (ending at 100)
+    ddcmd "line 10-100 +_"	# test closed-interval line range
+
+    # 4. Dedicated colon-delimited file:line and file:func assertions
+    ddcmd "file a_file.c:1-100 +_"	# test file:linerange syntax
+    ddcmd "file b_file.c:30 +_"		# test file:exact_line syntax
+    ddcmd "file c_file.c:c_func +_"	# test file:function_name syntax
+    ddcmd "file c_file.c:start_* +_"	# test file:wildcard_function syntax
+
+    # 5. Advanced formatting and separator checks (side-effect-free proofs)
+    ddcmd "format \"space\\040here\" +_"	# test format query with octal escape
+    #ddcmd "module,foo +_"		# test comma token separator syntax
+    ddcmd "func *my_func* +_"		# test wildcard func syntax
+    ddcmd "file drivers/usb/* +_"	# test wildcard file path syntax
+}
+
+# test grammar, no actual sites chosen/changed
+# use dyndbg's embedded comments in queries
+function FT_grammar_errs {
+    v_echo "${GREEN}# GRAMMAR_ERROR_TESTS ${NC}"
+    ddcmd =_
+    local verbose
+
+    # Reset before loop
+    echo 0 > /sys/module/dynamic_debug/parameters/verbose
+
+    # Sequence verbose level 0..3 to verify error diagnostics across all verbosity states!
+    for verbose in 1 2 3; do
+	echo $verbose > /sys/module/dynamic_debug/parameters/verbose
+
+	ddcmd_err 'module foo format "parse +p #! unclosed quote: parse +p'
+
+	# comments in queries tell the error in the logs
+	ddcmd_err "module foo unknown_keyword value	#! bad flag-op v, at start of value"
+	ddcmd_err "module foo %pm	#! bad flag-op %, at start of %pm"
+	ddcmd_err "module foo +pfmHKDD	#! unknown flag 'H'"
+
+	ddcmd_err "w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w 14 w15 w16 #! too many words, legal max <=15"
+	ddcmd_err "func w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 +p #! unknown keyword \"w3\""
+	ddcmd_err "module foo line =_ #! expecting pairs of match-spec <value>"
+
+	# match-spec duplicate keywords
+	ddcmd_err "func foo func bar =_	#! match-spec:func val:foo overridden by bar"
+	ddcmd_err "file foo.c file bar.c =_	#! match-spec:file val:foo.c overridden by bar.c"
+	ddcmd_err "module foo module baz =_	#! match-spec:module val:foo overridden by baz"
+	ddcmd_err "format foo format bar =_	#! match-spec:format val:foo overridden by bar"
+	ddcmd_err "class D2_CORE class D2_KMS +p #! match-spec:class val:D2_CORE overridden by D2_KMS"
+	ddcmd_err "module foo +x	#! unknown flag 'x'"
+
+	# line value errs
+	ddcmd_err "line 10 line 20 +l	#! match-spec: line used 2x"
+	ddcmd_err "line 10a +pl		#! bad line-number: 10a"
+	ddcmd_err "line 100-10 +pf	#! last-line:10 < 1st-line:100"
+
+	# colon-delimited syntax errs
+	ddcmd_err "func foo file bar.c:func_bar =_	#! match-spec:func val:foo overridden by func_bar"
+	ddcmd_err "file bar.c:100-10 +pf	#! last-line:10 < 1st-line:100"
+	ddcmd_err "file bar.c:10a +pl		#! bad line-number: 10a"
+	ddcmd_err "line 10-20 file bar.c:30 +pl	#! match-spec: line used 2x"
+    done
+
+    # Reset to default verbose level 0 at the end of basic errors
+    echo 0 > /sys/module/dynamic_debug/parameters/verbose
+    ddcmd =_
+}
+
+# these queries run against the builtin module: params, and change
+# flags.  The control file state-of-interest is found by path,
+# kernel/params.c, to avoid module keyword entirely
+function FT_basic_queries {
+    v_echo "${GREEN}# BASIC_TESTS ${NC}"
+    if [ $LACK_DD_BUILTIN -eq 1 ]; then
+	echo "SKIP - test requires params, which is a builtin module"
+	return
+    fi
+    ddcmd =_ # zero everything
+
+    ddcmd "module params +mf" 'kernel/params.c'
+    ddcmd "module params +l"  'kernel/params.c'
+    ddcmd "module params -m"  'kernel/params.c'
+    ddcmd "module params =_"  'kernel/params.c'
+
+    # multi-query commands split on ; on a single line
+    ddcmd "module params +mf ; module params func parse_args +sl"  'kernel/params.c'
+
+    # verify multi-cmd input, newline separated, with embedded comments
+    ddcmd =_ # reset before multiline query to capture full transition
+    ddcmd "module params =_		# clear params
+      module params +ml			# set flags
+      module params func parse_args +fs # set other flags" \
+	  'kernel/params.c'
+
+    # clear flags and verify
+    ddcmd "module params =_"  'kernel/params.c'
+}
+
+# Built-in Feature Tests (Can run on any CONFIG_DYNAMIC_DEBUG kernel, modular or monolithic)
+builtin_tests=(
+    FT_grammar_ok
+    FT_grammar_errs
+    FT_basic_queries
+)
+
+# Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
+modular_tests=(
+)
+
+# ==============================================================================
+# GOLDEN_RECORDS (MD5 Fingerprint Verification Database)
+#
+# This database stores the expected invariant log content hashes for our tests.
+# Since the key has the line-number of the callsite, we dont yet
+# support looping over a test-call, maybe we'll need to address that
+# later.
+#
+# NB: records have lineno of the test in code above. table at bottom
+# means inserts dont shift test-lines.
+#
+# ==============================================================================
+function GOLDEN_RECORDS {
+    cat << 'EOF' | {
+#K= b938440930e5f1297d524e6c0c1ec85c FT_grammar_errs.1
+#K= b9a397e807148d13ba07da7db7e69817 FT_grammar_errs.2
+#K= 5abefa504937a329f974504f1896e368 FT_grammar_errs.3
+#K= 1d94d0f239bf40bf51280caeab499de0 FT_grammar_errs.4
+#K= 135035c8a17ae100cc4ec954c4d75b2f FT_grammar_errs.5
+#K= a9cc14244f91a12d3174ad1314144a8e FT_grammar_errs.6
+#K= 5d400aad1a7d71f548b6b81274d00a55 FT_grammar_errs.7
+#K= 61cd359b10f9051862d3745eda07a295 FT_grammar_errs.8
+#K= 567379f4f4d099f00f37d1469d9370bd FT_grammar_errs.9
+#K= 31a026d10f85e8f4c9f8cf3e1cef3c61 FT_grammar_errs.10
+#K= ba62952b671a553d4b14e344a61926f7 FT_grammar_errs.11
+#K= 49aec6c2e99cc70a1e4137f86e94f6f4 FT_grammar_errs.12
+#K= cc02cccf15988a98dfd5b1df1e492e31 FT_grammar_errs.13
+#K= 2bbf3fac2b77b88b6cebe459ff9631d3 FT_grammar_errs.14
+#K= 93b67411c254875a6bae5c01c0239729 FT_grammar_errs.15
+#K= b22f2efe54a1637156b9521b2794806e FT_grammar_errs.16
+#K= de410dba40d8b097524f91da8ae2b1c5 FT_grammar_errs.17
+#K= 6c922048c21f6198720dfd68ae16fdad FT_grammar_errs.18
+#K= 4ddd57e9cbc3da2613ac59eb285ad8c1 FT_grammar_errs.19
+#K= ba65062f6be00a1d04907dd176d26c19 FT_grammar_errs.20
+#K= 94cdf3b32afa4f12a00a704208aa2e53 FT_grammar_errs.21
+#K= 1f6fedfe222af475211b3bfc6d08bc63 FT_grammar_errs.22
+#K= c67dfeca97697b707acdd70672816dff FT_grammar_errs.23
+#K= 9574dbfdac063409b41a44e6251fbcd9 FT_grammar_errs.24
+#K= 644b81753949ac1285e38ac995eeba46 FT_grammar_errs.25
+#K= 1bf2a93a39961f40e0c2dd4c5e2edc6d FT_grammar_errs.26
+#K= cdddf4ffd7fde3c12eb0c73770b872bf FT_grammar_errs.27
+#K= cdf7a2e2740ec007efbd29feda478420 FT_grammar_errs.28
+#K= f6650d69963cef433c50e1f2acb899fc FT_grammar_errs.29
+#K= e150a96693eb561a20eebebfd637e667 FT_grammar_errs.30
+#K= b63514cf73a93962311d098284d7b491 FT_grammar_errs.31
+#K= b253cde723889c42d2c944c1b14f5a45 FT_grammar_errs.32
+#K= 7ad3dfb73e82f4d75b0770179e6dc264 FT_grammar_errs.33
+#K= f4d905e4f72dbd535bb80d7fe9df84b0 FT_grammar_errs.34
+#K= 5bf50b198d8e5fe300541adfce92e073 FT_grammar_errs.35
+#K= 7c4d73d42cff377cd84a7683b0c3e0b9 FT_grammar_errs.36
+#K= 19f1aa8d33d71888be74b19a3143938f FT_grammar_errs.37
+#K= 84309c1322631ae74ecf2c729b6aa210 FT_grammar_errs.38
+#K= 8cfe48871f91a90e6eaaef9123892394 FT_grammar_errs.39
+#K= 8aaa5fdd50ead5cd429fbba4123b215c FT_grammar_errs.40
+#K= 94cdf3b32afa4f12a00a704208aa2e53 FT_grammar_errs.41
+#K= 1a402ada248d0d50cec13a1af150ea33 FT_grammar_errs.42
+#K= 5b46a8eb0d74009462f74cf7553e3228 FT_grammar_errs.43
+#K= 546e440044828d86135dd63f1eb9ed17 FT_grammar_errs.44
+#K= 644b81753949ac1285e38ac995eeba46 FT_grammar_errs.45
+#K= 1bf2a93a39961f40e0c2dd4c5e2edc6d FT_grammar_errs.46
+#K= 3e3acfb800cfb1bcb0cc07f33b75830a FT_grammar_errs.47
+#K= 42dc6cb4fe938bb82b64c82924ef28d8 FT_grammar_errs.48
+#K= cf9320d2188f5b48d508d610d95298b2 FT_grammar_errs.49
+#K= 1f33fb1fd2365e77c3cfbd61d1ae2a7c FT_grammar_errs.50
+#K= 67588c71f92f319c6224d5917456ecd2 FT_grammar_errs.51
+#K= 22e7795f7dbeb6dc2fce5e113312781c FT_grammar_errs.52
+#K= 66d253407728c1f8a850519eadd66880 FT_grammar_errs.53
+#K= 27e8345aaeed85c1de5516871e0bbd0c FT_grammar_errs.54
+#K= 43cc8a154f28f1a668ab409a1af4e77a FT_grammar_errs.55
+#K= eda21551fcdd76ef2f192e1d9950a05f FT_grammar_errs.56
+#K= 0a8a986b5610630cb75c0568deff8315 FT_grammar_errs.57
+#K= 29bfae73351c3157a5fe409febcef276 FT_grammar_errs.58
+#K= 73a9e53428d1fb1a9813e3eab7d0ea18 FT_grammar_errs.59
+#K= 800951095b297532e25785ab101a2ba9 FT_grammar_errs.60
+#K= 6e8599556a312200fb6d484565b6c52f FT_basic_queries.1
+#K= db17180b59444e5e34a8fc20c40e4530 FT_basic_queries.2
+#K= f7bd56bd407ff255ef2e3b5fb093ae6a FT_basic_queries.3
+#K= 4ce44468b3b5f80ae42ade1f261b952f FT_basic_queries.4
+#K= 02e4fd94602e108cb89bfc70d47a5dad FT_basic_queries.5
+#K= f03a7ca7316e8db4c0e16523dc41e75d FT_basic_queries.6
+#K= c518a50ba30ba8099d0dc874a27ecf16 FT_basic_queries.7
+EOF
+        # Read the K-recs and skip those for tests that can't run
+        while read -r line; do
+            # Filter built-in if needed
+            if [ "${LACK_DD_BUILTIN:-0}" -eq 1 ]; then
+                # Extract label (3rd field) from #K= line
+                local label=$(echo "$line" | awk '{print $3}')
+                if [[ "$label" == FT_basic_queries* \
+			  || "$label" == FT_comma_terminators* \
+			  || "$label" == FT_multi_query* ]]; then
+                    continue
+                fi
+            fi
+            # Filter modular if needed
+            if [ "${LACK_TMOD:-0}" -eq 1 ]; then
+                # Extract label (3rd field) from #K= line
+                local label=$(echo "$line" | awk '{print $3}')
+                if [[ "$label" == FT_test_classes* \
+			  || "$label" == FT_classmap_inheritance* \
+			  || "$label" == FT_modprobe_w_param* ]]; then
+                    continue
+                fi
+            fi
+            echo "$line"
+        done
+    }
+}
+
+# ==============================================================================
+# Run tests
+
+# Clear any stale seen/unregistered/drifted hashes from previous runs
+: > "$SEEN_HASHES_FILE"
+: > "$UNREG_HASHES_FILE"
+: > "$DRIFT_HASHES_FILE"
+
+ifrmmod test_dynamic_debug
+
+# Check if loadable module support or our test modules are missing/builtin
+LACK_TMOD=0
+if [ -d "/sys/module/test_dynamic_debug" ]; then
+    # If module is present but not in /proc/modules,
+    # it is a builtin module (cannot unload/reload)
+    if ! grep -q "^test_dynamic_debug " /proc/modules 2>/dev/null; then
+        LACK_TMOD=1
+    fi
+else
+    # Check if we can modprobe it from disk
+    modprobe -q -n test_dynamic_debug || LACK_TMOD=1
+fi
+
+# 1. Run all Built-in Feature Tests
+v_echo "${GREEN}# RUNNING BUILT-IN FEATURE TESTS ${NC}"
+for test_func in "${builtin_tests[@]}"; do
+    $test_func
+    v_echo ""
+done
+
+# 2. Run Modular Feature Tests only if test modules are available
+if [ $LACK_TMOD -eq 0 ]; then
+    v_echo "${GREEN}# RUNNING MODULAR FEATURE TESTS ${NC}"
+    for test_func in "${modular_tests[@]}"; do
+        $test_func
+        v_echo ""
+    done
+else
+    v_echo "${YELLOW}# SKIPPING MODULAR TESTS: test_dynamic_debug.ko not available ${NC}"
+fi
+
+if [ "$V" -ge 1 ]; then
+    echo -en "${GREEN}# Done on: "
+    date
+    echo -en "${NC}"
+fi
+
+audit_golden_records
+
+# Output consolidated blocks of unregistered and drifted fingerprints
+failed=0
+
+if [ -s "$UNREG_HASHES_FILE" ]; then
+    if [ "$K" -ne 2 ]; then
+        echo -e "${YELLOW}\n# --- Unregistered Baselines ---"
+        cat "$UNREG_HASHES_FILE"
+        echo -e "# ------------------------------${NC}"
+    fi
+    : > "$UNREG_HASHES_FILE"
+    failed=1
+fi
+
+if [ -s "$DRIFT_HASHES_FILE" ]; then
+    if [ "$K" -ne 2 ]; then
+        echo -e "${RED}\n# --- Drifted Baselines ---"
+        cat "$DRIFT_HASHES_FILE"
+        echo -e "# -------------------------${NC}"
+    fi
+    : > "$DRIFT_HASHES_FILE"
+    failed=1
+fi
+
+if [ $failed -eq 1 ]; then
+    [ "$K" -eq 1 ] && echo "fake success" && exit $ksft_pass
+    [ "$K" -eq 2 ] && exit $ksft_pass
+    exit $ksft_fail
+fi
+
+exit $ksft_pass
+
diff --git a/tools/testing/selftests/dynamic_debug/syslog_hash_validation.sh b/tools/testing/selftests/dynamic_debug/syslog_hash_validation.sh
new file mode 100644
index 000000000000..8c6e91f5d9c2
--- /dev/null
+++ b/tools/testing/selftests/dynamic_debug/syslog_hash_validation.sh
@@ -0,0 +1,393 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# Generic, zero-dependency syslog and file-slicing verification helper library.
+#
+# Provides 2 validation mechanisms:
+# 1. Spatial Control-File Slicing (State Checks & Transitions):
+#    - verify_file_slice: Hashes module state in /proc/.../control.
+#    - capture_before / verify_after_change: Hashes normalized diff between
+#      pre- and post-stimulus states. Strips line numbers and hunk headers,
+#      making the hash immune to upstream line churn in C source files.
+# 2. Temporal Syslog Slicing (Workload Logging Checks):
+#    - log_start / log_stop / verify_dmesg_slice: Emits bookend markers to
+#      /dev/kmsg, slicing exact dmesg prints produced during a workload while
+#      stripping multi-bracket timestamp/CPU/PID headers.
+
+# Default APP to DYNDBG if not already set
+APP="${APP:-DYNDBG}"
+APP_LOWER=$(echo "$APP" | tr '[:upper:]' '[:lower:]')
+
+# Global files for tracking seen, unregistered, and drifted hashes securely via mktemp
+SEEN_HASHES_FILE=$(mktemp -t "${APP_LOWER}_seen_hashes.XXXXXX")
+UNREG_HASHES_FILE=$(mktemp -t "${APP_LOWER}_unreg_hashes.XXXXXX")
+DRIFT_HASHES_FILE=$(mktemp -t "${APP_LOWER}_drift_hashes.XXXXXX")
+
+# Secure trap handler to clean up temp files on exit or interrupt
+trap 'rm -f "$SEEN_HASHES_FILE" "$UNREG_HASHES_FILE" "$DRIFT_HASHES_FILE"' EXIT INT TERM HUP
+
+# Global variables for tracking active function transitions and sequence resets
+LAST_FT_FUNC=""
+TEST_SEQ_CTR=0
+ACTIVE_RESOLVED_LABEL=""
+
+# Global variables for bookending state transitions and local stimulus tracking
+IN_BOOKEND=0
+DDCMD_LOG=""
+
+# Global variable to track the active dmesg block label
+ACTIVE_LOG_LABEL=""
+
+# Helper function to auto-resolve active FT_ test and sequence label
+function rdi_resolve_label {
+    local caller_fn=""
+    # Traverse the call stack to find the active Feature Test function (FT_*)
+    for fn in "${FUNCNAME[@]}"; do
+        if [[ "$fn" == FT_* ]]; then
+            caller_fn="$fn"
+            break
+        fi
+    done
+
+    # Fallback to the immediate caller if no FT_ is in the stack
+    if [ -z "$caller_fn" ]; then
+        caller_fn="${FUNCNAME[1]:-}"
+    fi
+
+    # Automatically reset sequence counter if the executing function has transitioned
+    if [ -n "$caller_fn" ] && [ "$caller_fn" != "$LAST_FT_FUNC" ]; then
+        TEST_SEQ_CTR=1
+        LAST_FT_FUNC="$caller_fn"
+    fi
+
+    if [ -n "$caller_fn" ]; then
+        ACTIVE_RESOLVED_LABEL="${caller_fn}.${TEST_SEQ_CTR}"
+    else
+        ACTIVE_RESOLVED_LABEL="${TEST_SEQ_CTR}"
+    fi
+}
+
+function log_start {
+    ((TEST_SEQ_CTR++))
+
+    rdi_resolve_label
+    ACTIVE_LOG_LABEL="$ACTIVE_RESOLVED_LABEL"
+
+    IN_BOOKEND=1
+
+    echo "${APP}_START_${ACTIVE_LOG_LABEL}_$$" > /dev/kmsg
+}
+
+function log_stop {
+    # Ends the dmesg capture block and verifies the slice
+    if [ -z "$ACTIVE_LOG_LABEL" ]; then
+        echo "Error: log_stop called without a matching log_start!" >&2
+        return 1
+    fi
+
+    echo "${APP}_END_${ACTIVE_LOG_LABEL}_$$" > /dev/kmsg
+
+    # Verify the dmesg slice
+    verify_dmesg_slice "$ACTIVE_LOG_LABEL"
+
+    # Reset active state, bookend flag, and command tracker at teardown
+    ACTIVE_LOG_LABEL=""
+    IN_BOOKEND=0
+    DDCMD_LOG=""
+}
+
+function verify_fingerprint {
+    # Verifies a calculated fingerprint against the GOLDEN_RECORDS database
+    # $1 - unique test key (e.g. normal_513)
+    # $2 - the calculated fingerprint hash to verify
+    # $3 - description of what was captured (e.g. "Dmesg Log" or "File Slice")
+    # $4 - the raw captured text block (to display in case of mismatch)
+
+    local label="$1"
+    local fingerprint="$2"
+    local capture_desc="$3"
+    local raw_capture="$4"
+
+    # Require GOLDEN_RECORDS to be defined in the caller script
+    if ! declare -f GOLDEN_RECORDS >/dev/null; then
+        echo "Error: GOLDEN_RECORDS() is not defined in the caller script." >&2
+        return 1
+    fi
+
+    # Resolve the expected hash specifically for this label
+    local expected_hash_field
+    expected_hash_field=$(GOLDEN_RECORDS | \
+        grep -E "[[:space:]]${label}([[:space:]]|$)" | head -n1 | awk '{print $2}')
+
+    local matched=0
+    local h
+    local OLD_IFS="$IFS"
+    IFS=","
+    for h in $expected_hash_field; do
+        if [ "$h" = "$fingerprint" ]; then
+            matched=1
+            break
+        fi
+    done
+    IFS="$OLD_IFS"
+
+    # Strictly verify that the computed fingerprint matches any
+    # expected hash for this label
+    if [ -n "$expected_hash_field" ] && [ $matched -eq 1 ]; then
+        local short_hash="${fingerprint:0:12}"
+        [ "$V" -ge 1 ] && echo -e "${GREEN}✔ Verified '${label}' " \
+            "(${short_hash}) [via: '${DDCMD_LOG}']${NC}"
+
+        if [ "$V" -ge 2 ]; then
+            echo -e "${CYAN}--- Captured Invariant ${capture_desc} Output ($label) ---"
+	    printf "#K= %-32s %-24s\n" "${fingerprint}" "${label}"
+            echo "$raw_capture"
+            echo -e "-----------------------------------${NC}"
+        fi
+        echo "$fingerprint" >> "$SEEN_HASHES_FILE"
+    else
+        # Failure path: display mismatch and append to corrections
+        local status_str="UNREGISTERED"
+        local stimulus="${DDCMD_LOG:-direct write to control}"
+        if [ -n "$expected_hash_field" ]; then
+            local short_expected="${expected_hash_field:0:12}"
+            local short_got="${fingerprint:0:12}"
+            if [ "${K:-0}" -ne 2 ]; then
+                echo -e "${RED}: DRIFT for '${label}'${NC}"
+                echo -e "  Stimulus:  ${stimulus}"
+                echo -e "  Expected:  '${short_expected}' (${expected_hash_field})"
+                echo -e "  Got:       '${short_got}' (${fingerprint})${NC}"
+            fi
+            status_str="DRIFTED"
+        else
+            if [ "${K:-0}" -ne 2 ]; then
+                echo -e "${YELLOW}: NO RECORD for '${label}'${NC}"
+                echo -e "  Stimulus:  ${stimulus}${NC}"
+            fi
+        fi
+
+        if [ "${K:-0}" -ne 2 ]; then
+            echo -e "\nAdd or replace this line in GOLDEN_RECORDS():"
+            printf "#K= %-32s %-24s\n" "${fingerprint}" "${label}"
+            echo -e "\n--- Captured Invariant ${capture_desc} Output ---"
+            if [ "$capture_desc" = "File Slice" ]; then
+                echo "$raw_capture" | \
+                    sed -E "s/ =([_a-z]*[a-z][_a-z]*) / ${YELLOW}=\1${NC} /g"
+            else
+                echo "$raw_capture"
+            fi
+            echo -e "-----------------------------------${NC}"
+        fi
+
+        if [ "$status_str" = "DRIFTED" ]; then
+            printf "#K= %-32s %s\n" \
+                "${fingerprint}" "${label}" \
+                >> "$DRIFT_HASHES_FILE"
+        else
+            printf "#K= %-32s %s\n" \
+                "${fingerprint}" "${label}" \
+                >> "$UNREG_HASHES_FILE"
+        fi
+    fi
+}
+
+function verify_dmesg_slice {
+    # Slices dmesg, computes its hash, and verifies it against the database.
+    # $1 - unique test key (e.g. normal_513)
+    # $2 - optional start marker (defaults to ${APP}_START_${label})
+    # $3 - optional end marker (defaults to ${APP}_END_${label})
+
+    local label="$1"
+    local app="${APP:-DYNDBG}"
+    local start_marker="${2:-${app}_START_${label}_$$}"
+    local end_marker="${3:-${app}_END_${label}_$$}"
+
+    # 1. Capture the log slice (exactly once!)
+    local log_slice=$(dmesg | sed -n "/$start_marker/,/$end_marker/p" | \
+	grep -E -v "$start_marker|$end_marker" | \
+        sed -E -e 's/^(\[[^]]*\][[:space:]]*)+//' )
+
+    # 2. Compute its fingerprint
+    local fingerprint=$(echo "$log_slice" | tr -d '\r' | md5sum | cut -d' ' -f1)
+
+    # 3. Verify
+    verify_fingerprint "$label" "$fingerprint" "Dmesg Log" "$log_slice"
+}
+
+function strip_control_linenos {
+    # Normalizes 'filename:123' to 'filename:0' for /proc/dynamic_debug/control output
+    sed -E 's/^([^:]+):[0-9]+/\1:0/'
+}
+
+function slice_by_grep {
+    # Isolate lines matching a pattern from a file
+    # $1 - pattern to grep (returns entire file if empty or "*")
+    # $2 - file path (reads $CONTROL_FILE if not provided)
+    local pattern="$1"
+    local file_path="${2:-$CONTROL_FILE}"
+
+    if [ -z "$pattern" ] || [ "$pattern" = "*" ]; then
+        cat "$file_path"
+    else
+        grep "$pattern" "$file_path"
+    fi
+}
+
+function verify_file_slice {
+    # Captures a file slice by pattern, computes its hash,
+    # and verifies it against the database.
+    # $1 - pattern to slice
+    # $2 - optional file path (defaults to $CONTROL_FILE)
+
+    local pattern="$1"
+    local file="${2:-$CONTROL_FILE}"
+
+    # Always auto-resolve label via call stack sequence resets!
+    ((TEST_SEQ_CTR++))
+    rdi_resolve_label
+    local label="$ACTIVE_RESOLVED_LABEL"
+
+    # 1. Capture the file slice (exactly once!)
+    local slice=$(slice_by_grep "$pattern" "$file")
+    if [ "$file" = "$CONTROL_FILE" ]; then
+        slice=$(echo "$slice" | strip_control_linenos)
+    fi
+
+    # 2. Compute its fingerprint
+    local fingerprint=$(echo "$slice" | tr -d '\r' | md5sum | cut -d' ' -f1)
+
+    # 3. Verify
+    verify_fingerprint "$label" "$fingerprint" "File Slice" "$slice"
+
+    # Reset state, bookend flag, and command tracker at teardown
+    IN_BOOKEND=0
+    DDCMD_LOG=""
+}
+
+# Global variables for bookending state transitions
+BEFORE_CAPTURE_SLICE=""
+BEFORE_CAPTURE_PATTERN=""
+BEFORE_CAPTURE_FILE=""
+
+function capture_before {
+    # Captures and stores the 'before' state for a file slice transition
+    # $1 - pattern to slice
+    # $2 - optional file path (defaults to $CONTROL_FILE)
+
+    BEFORE_CAPTURE_PATTERN="$1"
+    BEFORE_CAPTURE_FILE="${2:-$CONTROL_FILE}"
+    BEFORE_CAPTURE_SLICE=$(slice_by_grep "$BEFORE_CAPTURE_PATTERN" "$BEFORE_CAPTURE_FILE")
+    if [ "$BEFORE_CAPTURE_FILE" = "$CONTROL_FILE" ]; then
+        BEFORE_CAPTURE_SLICE=$(echo "$BEFORE_CAPTURE_SLICE" | strip_control_linenos)
+    fi
+
+    IN_BOOKEND=1
+}
+
+function verify_after_change {
+    # Verifies the transition between the stored 'before' state and the current state
+    # $1 - optional unique test key (resolved via stack if empty)
+
+    local label="$1"
+
+    if [ -z "$label" ]; then
+        ((TEST_SEQ_CTR++))
+        rdi_resolve_label
+        label="$ACTIVE_RESOLVED_LABEL"
+    fi
+
+    if [ -z "$BEFORE_CAPTURE_PATTERN" ]; then
+        echo "Error: verify_after_change called without a matching capture_before!" >&2
+        return 1
+    fi
+
+    # 1. Capture the 'after' state (exactly once!)
+    local after_slice=$(slice_by_grep "$BEFORE_CAPTURE_PATTERN" "$BEFORE_CAPTURE_FILE")
+    if [ "$BEFORE_CAPTURE_FILE" = "$CONTROL_FILE" ]; then
+        after_slice=$(echo "$after_slice" | strip_control_linenos)
+    fi
+
+    # 2. Generate the unified diff, stripped of volatile diff headers AND hunk line-numbers
+    local transition_diff=$(diff -u <(echo "$BEFORE_CAPTURE_SLICE") <(echo "$after_slice") | \
+        tail -n +3 | \
+        sed -E 's/^@@ -[0-9]+.* \+[0-9]+.* @@/@@/g')
+
+    # 3. Compute its fingerprint
+    local fingerprint=$(echo "$transition_diff" | tr -d '\r' | md5sum | cut -d' ' -f1)
+
+    # 4. Verify the diff as the captured text block
+    verify_fingerprint "$label" "$fingerprint" "File Change Diff" "$transition_diff"
+
+    # Reset state, bookend flag, and command tracker at teardown
+    BEFORE_CAPTURE_SLICE=""
+    BEFORE_CAPTURE_PATTERN=""
+    BEFORE_CAPTURE_FILE=""
+    IN_BOOKEND=0
+    DDCMD_LOG=""
+}
+
+function audit_golden_records {
+    local seen_file="$SEEN_HASHES_FILE"
+
+    if [ ! -f "$seen_file" ]; then
+        return
+    fi
+
+    # Require GOLDEN_RECORDS to be defined in the caller script
+    if ! declare -f GOLDEN_RECORDS >/dev/null; then
+        return
+    fi
+
+    [ "${V:-0}" -ge 1 ] && echo -e "${YELLOW}# --- GOLDEN_RECORDS Audit ---${NC}"
+    local stale_found=0
+    local total_records=$(GOLDEN_RECORDS | grep -c "^#K=")
+
+    # Read each active record line from GOLDEN_RECORDS
+    while read -r line; do
+        # Extract the hash/hashes (second word) from the #K= line
+        local hash_field=$(echo "$line" | awk '{print $2}')
+
+        # Check if at least one of the comma-separated hashes was seen
+        local hash_seen=0
+        local h
+        local OLD_IFS="$IFS"
+        IFS=","
+        for h in $hash_field; do
+            if grep -q "$h" "$seen_file" 2>/dev/null; then
+                hash_seen=1
+                break
+            fi
+        done
+        IFS="$OLD_IFS"
+
+        # Check if this hash field was seen during the run
+        if [ $hash_seen -eq 0 ]; then
+            if [ "${K:-0}" -ne 2 ]; then
+                if [ $stale_found -eq 0 ]; then
+                    # On first failure, print header if not already printed
+                    [ "${V:-0}" -eq 0 ] && \
+                        echo -e "${YELLOW}# --- GOLDEN_RECORDS Audit ---${NC}"
+                    echo -e "${YELLOW}# The following GOLDEN_RECORDS entries " \
+                        "were never hit and may be stale:${NC}"
+                fi
+                echo -e "${YELLOW}#K_STALE= $line${NC}"
+            fi
+            stale_found=1
+        fi
+    done < <(GOLDEN_RECORDS | grep "^#K=" | grep -v "<md5_hash>")
+
+    if [ $stale_found -eq 0 ] && [ "${V:-0}" -ge 1 ]; then
+        echo -e "${GREEN}# All $total_records GOLDEN_RECORDS entries " \
+            "were successfully hit!${NC}"
+    fi
+
+    # Detect duplicate labels in the database
+    local dupes=$(GOLDEN_RECORDS | grep "^#K=" | awk '{print $3}' | sort | uniq -d)
+    if [ -n "$dupes" ]; then
+        echo -e "\n${RED}# WARNING: Duplicate labels detected in GOLDEN_RECORDS():${NC}"
+        echo "$dupes" | sed 's/^/#   /'
+    fi
+
+    # Clean up
+    rm -f "$seen_file"
+}

-- 
2.55.0

