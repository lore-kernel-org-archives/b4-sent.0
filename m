From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:54:57 -0600
Subject: [PATCH v9 01/39] selftests/dyndbg: Add kselftest script to verify
 dynamic-debug
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-1-3a3f621f4a10@gmail.com>
References: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
In-Reply-To: <20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=62361;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=W/NfKc1r06KO1HjSrVqxHNlyrb9qVSV2GQ2pseLMxBw=;
 b=9k8Z3tTfrSa8yRkJhT+s3TIYY81i3Hz0HI+/FUF2it1dHOkxsS0e3iQVc4zzfWO0D+5eksroV
 KmQgKYNGWo1AML21FcT3Wo9x1ZaOLZsFa3Y7hRvQ3es7STnPsTvMeGJ
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a kselftest script to attempt full validation of dynamic-debug
behavior. The script tests query grammar as documented, responses to
bad input, and proper/expected effects on both the control-file
display of current state, and on pr_debug logging behavior.

NOTE: This script was finished last, then rebased to front; It gives
an easy functional test thru the series, not just a does-it-boot.  It
preserves but disables some tests to pass as a baseline; there are 3
Basics: FT_grammar_ok(), FT_grammar_errs(), FT_basic_queries().

The Canonical Test:

A naive dyndbg test might look like:
   echo "module main +mfp" > /proc/dynamic_debug/control
   local ct=$(grep -c " =pmf " /proc/dynamic_debug/control)
   (( $ct == $expected)) || FAIL

But you'll find that you've changed 4 different modules, and your
count is off.  Ad-hoc testing is hard, and fundamentally trades
test clarity against thoroughness, precision and brittleness.

Here, the canonical test tries harder:

1. Observe the prior dyndbg state-of-interest.
2. Send $cmd to change state-of-interest.
   a: echo $cmd > control
   b: echo 1 > "/sys/module/test_dynamic_debug/parameters/do_classes"
3. Observe the results, in control-file or dmesg

The key here is 'observe' means `md5sum $state-of-interest`. This
gives us total "checksum" precision, and with a little care,
$state-of-interest mostly solves the brittleness.

If a test should cause logging:
1. Sends a unique 'START_of_label' message directly to syslog/dmesg.
2. Sends the command or parameter configuration, as in b: above.
3. Sends a unique 'END_of_label' message directly to syslog/dmesg.
4. read dmesg, extract START..END

This bookended logging allows the script to isolate and reliably
extract the precise dmesg/syslog slice between the markers, and
fingerprint the state-of-interest cryptographically.  Its not truly
isolated from busy-kernel messages, unless its a test-vm.

Comprehensive Feature Test (FT_*) Script Mapping:

The Feature Test (FT_*) functions test major aspects of dynamic-debug,
they're in 3 categories:

1: Zero-Dependency Grammar & Core Parser Tests

These tests throw legal & illegal commands at the >control file, but
don't attempt to select any real pr_debug callsite.

* FT_grammar_ok:
  Verifies successful query grammar parses (exact line, open line
  range, closed line range, and colon-delimited file:line/file:func
  syntax) using side-effect-free empty placeholder flags ('+_').

* FT_grammar_errs:
  Verifies core query parser error-handling and EINVAL paths across
  multiple verbosity levels (0..3), catching even minor message drift.

2: Built-in Feature & Name Equivalence Tests (Kernel Core)

These tests verify the core features compiled directly into the kernel
image.  They validate "[main]" vs "[init/main]" resolution added recently.

* FT_basic_queries:
  Verifies basic, direct queries (module, func, format, and clear flags
  '=_') targeting the builtin kernel/params engine.

These tests are disabled until KBUILD_MODFILE:

* FT_path_module_queries: Verifies path-based and wildcard module
  query controls (such as module 'init/main', module '*/main')
  targeting builtin startup callsites. This specifically validates the
  back-compat resolution of the old 'module main' ambiguity (which
  selects 5-6 different built-in modules).

* FT_hyphen_underscore:
  Verifies literal name versus kbasename hyphen/underscore equivalence
  (e.g., kvm_intel vs. kvm-intel), proving that both queries select
  identical ranges-of-interest. This validates recent kernel fixes
  establishing name-normalization equivalence inside the query engine,
  ensuring that character substitutions work as they do in modprobe.

3: Tests which require test_dynamic_debug

These tests verify complex classmap configurations, multi-module
setups, and load-time/runtime parameter callback equivalence.

* FT_test_classes:
  Verifies classmap-based query enablers and class configurations on a
  modular target, proving dynamic runtime class configurations via
  /proc/dynamic_debug/control.

* FT_classmap_inheritance:
  Verifies multi-module classmap propagation and class inheritance
  checks between a parent and submodule sharing a classmap. This
  actively demonstrates a key systems distinction: one-time bare class
  queries (dyndbg=class...) do NOT inherit at load-time, whereas
  classmap module parameters (p_disjoint_bits, p_level_num) are
  persistent and successfully propagate state to submodules upon loading.
  These tests recapitulate the scenario where classmaps-v1 [1] hit
  regressions and was marked BROKEN.

* FT_modprobe_w_param:
  Verifies load-time parameter callback initialization (via modprobe
  $param=$val) and subsequent runtime sysfs-write unsetting callbacks
  sequentially, by looping over verbose levels, and varying
  (p_disjoint_bits, p_level_num) and (do_classes, do_bulk).

NB: within each FT_, tests are numbered and cataloged. This isolates
each FT_* test's sequence numbers from each other.

Main Test Runner (dyndbg_selftest.sh) Support Functions:

* ddcmd("$query", ["$range"], ["$action"]):
  The core test primitive. Writes a query string to the control file.
  - ["$range"]: Optional slice filter pattern (triggers transition
    verification R1 on non-empty values).
  - ["$action"]: Expected outcome action ('pass' default, 'fail' asserts
    return code 1 and logs dmesg, 'log' asserts 0 and logs dmesg).

* ddcmd_err("$query"):
  Semantic error query wrapper. Invokes ddcmd expected to fail.

* ddcmd_load("$query", "$range", "$param_path", "$val"):
  Workload-driven syslog verification helper.
  - "$param_path": Sysfs parameter path of workload trigger.
  - "$val": Integer trigger value written to workload param.

* verify_modprobe_param_logging("$param", "$val", "$tag"):
  Dynamic parameter test primitive. Coordinates load-time modprobe and
  runtime sysfs unsetting in a single sequence.
  - "$param": Module parameter name to configure at load-time.
  - "$val": Initial value or composite bitmask/level integer.
  - "$tag": Suffix used to construct the dmesg golden record label.

* slice_and_hash_ddctrl("$grep_pattern"):
  Local control-file wrapper.

* ifrmmod("$module"):
  Defensive module unloader.

* handle_exit_code("$lineno", "$func", "$exit_code", ["$expected_code"]):
  Core exit code verifier.
  - "$lineno": Caller line number ($BASH_LINENO).
  - "$func": Caller function name ($FUNCNAME).
  - ["$expected_code"]: Expected exit code, default 0.

Verification Library (syslog_hash_validation.sh) Support Functions:

* log_start() / log_stop():
  Slicing syslog capture bookends. Marks the start and end of a
  stimulus-triggered test execution by writing tags to /dev/kmsg.

* rdi_resolve_label():
  Active sequence resolver. Leverages Bash call-stack reflection
  (FUNCNAME) to determine active FT_ test functions and automatically
  re-index sequence numbers.

* slice_by_grep("$pattern", ["$file"]):
  Text slice extractor. Narrows the scope of a captured log or file.
  - <pattern>: Regex pattern to narrow the capture scope.
  - [file_path]: Target file path to slice (defaults to dmesg).

* verify_file_slice(<slice_pattern>, [file_path], [extra_args]):
  Standard file transition verifier. Captures a state slice, auto-
  resolves the label, and verifies its cryptographic hash.
  - <slice_pattern>: Regex pattern defining the capture scope.
  - [file_path]: Target file to slice, defaulting to control-file.
  - [extra_args]: Optional tag appended to the golden record.

* verify_dmesg_slice(<label>, ["$start"], ["$end"], ["$filter"],
  ["$extra_args"]):
  Active dmesg syslog slice verifier.
  - ["$start"]: Starting bookend marker, defaulting to START_of_label.
  - ["$end"]: Ending bookend marker, defaulting to END_of_label.
  - ["$filter"]: Optional filter grep regex to isolate target prints.
  - ["$extra_args"]: Suffix tag, defaulting to "dmesg".

* capture_before("$range_pattern", ["$file"]):
  Pre-stimulus snapshot helper. Saves a snapshot of a target slice.
  - ["$file"]: Target file to snapshot, defaulting to control-file.

* verify_after_change(["$extra_args"]):
  Post-stimulus delta verifier. Compares post-state slices to pre-state
  snapshots, generating a portable, line-number-free unified diff.
  - ["$extra_args"]: Optional tag, defaulting to the pre-state pattern.

* verify_fingerprint("$label", "$extra_args", "$computed_hash", "$desc"):
  Exact-label cryptographic matching engine.
  - "$desc": Human-readable trace description type (e.g. "Dmesg Log").

* audit_golden_records():
  Self-auditing reporting utility. Called at the end of the script, it
  identifies fingerprint/result entries that weren't encountered in the
  run, and which are probably stale entries.

What happens when tests fail/drift ?

The script tests against kernel/params (params module) for several reasons;
it is stable, it is always built-in, since a kernel can't read boot-options
without it, and modprobes cause it to run enabled pr_debugs.

Those tests left it enabled for the modprobe tests, which exposed a
pr_debug("%p"...) latent in kernel/params.

   -----------------------------------
   : DRIFT for 'FT_basic_queries.6'
     Range:     "\[kernel/params\]"
     Stimulus:  module params =_                      # clear params
         module params +ml                             # set flags
         module params func parse_args +fs             # other flags
     Expected:  'baea1247680e' (baea1247680e8151c121539f4b90a6d8)
     Got:       '4b4d46577a1c' (4b4d46577a1cd930c7a6d5298f6ca24c)

   Add or replace this line in GOLDEN_RECORDS():
   #K= 4b4d46577a1cd930c7a6d5298f6ca24c FT_basic_queries.6 \
       "\[kernel/params\]"

   --- Captured Invariant File Change Diff Output ---
   @@
   -kernel/params.c:139 [kernel/params]parse_one =_ "handling %s with %p\n"
   -kernel/params.c:152 [kernel/params]parse_one =_ "doing %s: %s='%s'\n"
   -kernel/params.c:156 [kernel/params]parse_one =_ "Unknown argument '%s'\n"
   -kernel/params.c:175 [kernel/params]parse_args =_ "doing %s, parsing ARGS: '%s'\n"
   +kernel/params.c:139 [kernel/params]parse_one =ml "handling %s with %p\n"
   +kernel/params.c:152 [kernel/params]parse_one =ml "doing %s: %s='%s'\n"
   +kernel/params.c:156 [kernel/params]parse_one =ml "Unknown argument '%s'\n"
   +kernel/params.c:175 [kernel/params]parse_args =mfsl "doing %s, parsing ARGS: '%s'\n"
   -----------------------------------

   Similarly, the engine catches dmesg syslog format drifts under the
   load-time and runtime parameter interfaces (R2 capturing):

   : DRIFT for 'FT_modprobe_w_param.7'
     Range:     dmesg
     Stimulus:  modprobe test_dynamic_debug p_level_num=3
     Expected:  '6e811e3b169a' (6e811e3b169acf94410fbda0747b4e78)
     Got:       '36c4f8b6363b' (36c4f8b6363b79ead3ab5a25e1795525)

   Add or replace this line in GOLDEN_RECORDS():
   #K= 36c4f8b6363b79ead3ab5a25e1795525 FT_modprobe_w_param.7    dmesg

   --- Captured Invariant Dmesg Log Output ---
   dyndbg:  34 debug prints in module test_dynamic_debug
   kernel/params:parse_args: doing test_dynamic_debug, parsing ARGS: 'p_level_num=3'
   kernel/params:parse_one: handling p_level_num with 000000005c252bc5
   dyndbg: p_level_num: total matches: 2
   test_dd: V1 msg
   test_dd: V2 msg
   -----------------------------------

NOTES:

By default script runs with V=0 envar, and runs silently on success.

With V=1, script runs show status, like:

 # BASIC_TESTS
 ✔ Verified 'FT_basic_queries.1' (24d85e3b86f3) [via: 'module params +mf']
 ✔ Verified 'FT_basic_queries.2' (958898bcd973) [via: 'module params +l']
 ✔ Verified 'FT_basic_queries.3' (130118da5a29) [via: 'module params -m']
 ✔ Verified 'FT_basic_queries.4' (da6bd1c6a299) [via: 'module params =_']
 ✔ Verified 'FT_basic_queries.5' (82572e8d20c4) [via: 'module params +mf @ module params func parse_args +sl']
 ✔ Verified 'FT_basic_queries.6' (baea1247680e) [via: 'module params =_                      # clear params
      module params +ml                             # set flags
      module params func parse_args +fs             # other flags']

With V=2, script runs show full context, like:

 ✔ Verified 'FT_grammar_errs.44' (2d3af67031a3) [via: 'module foobar +x']
 --- Captured Invariant Dmesg Log Output (FT_grammar_errs.44) ---
 dyndbg: read 17 bytes from userspace
 dyndbg: query 0: "module foobar +x"
 dyndbg: split into words: "module" "foobar" "+x"
 dyndbg: unknown flag 'x'
 dyndbg: flags parse failed
 dyndbg: query parse failed
 dyndbg: processed 1 queries, with 0 matches, 1 errs
 -----------------------------------

 # BASIC_TESTS
 ✔ Verified 'FT_basic_queries.1' (24d85e3b86f3) [via: 'module params +mf']
 --- Captured Invariant File Change Diff Output (FT_basic_queries.1) ---
 @@
 -kernel/params.c:139 [kernel/params]parse_one =_ "handling %s with value '%s'\n"
 -kernel/params.c:152 [kernel/params]parse_one =_ "doing %s: %s='%s'\n"
 -kernel/params.c:156 [kernel/params]parse_one =_ "Unknown argument '%s'\n"
 -kernel/params.c:175 [kernel/params]parse_args =_ "doing %s, parsing ARGS: '%s'\n"
 +kernel/params.c:139 [kernel/params]parse_one =mf "handling %s with value '%s'\n"
 +kernel/params.c:152 [kernel/params]parse_one =mf "doing %s: %s='%s'\n"
 +kernel/params.c:156 [kernel/params]parse_one =mf "Unknown argument '%s'\n"
 +kernel/params.c:175 [kernel/params]parse_args =mf "doing %s, parsing ARGS: '%s'\n"
 -----------------------------------

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v9:
. sanitize "$K" integer input alongside "$V".
. drop duplicate ifrmmod function declaration.
. replace undeclared "$error_msg" with "$output" in handle_exit_code().
. rework LACK_DD_BUILTIN record filtering to check label column ($3).
. truncate temp files (: > "$SEEN_HASHES_FILE") instead of rm -f under mktemp.
. add handling for K=2 (silent soft-pass mode) to suppress DRIFT/UNREG blocks.

- selftests/dyndbg: drop builtin enablements in FT_modprobe_w_param()
- selftests/dyndbg: V=2 output needs #K=$fingerprint too

 -----------------------------------
 ✔ Proven Runtime Unset:  echo 0 > p_disjoint_bits successfully cleared callsites
 ✔ Verified 'FT_modprobe_w_param.42'  (146a1294f452) [via: 'modprobe test_dynamic_debug p_level_num=3; echo 1 > /sys/module/test_dynamic_debug/parameters/do_prints']
 --- Captured Invariant Dmesg Log Output (FT_modprobe_w_param.42) ---
 #K= 146a1294f452e51c12837bbd3ea723fa FT_modprobe_w_param.42
 kernel/params:parse_args: doing test_dynamic_debug, parsing ARGS: 'p_level_num=3'
 kernel/params:parse_one: handling p_level_num with value '3'
 test_dd: V1 msg
 test_dd: V2 msg
 test_dd: V1 msg
 test_dd: V2 msg
 -----------------------------------

The new element/line above is the #K= record, which is the format used
in the GOLDEN-RECORDS.  Having this captured output, with the #K=rec,
saved off to a reference file somewhere, should help when dealing with
a drift report:

 -----------------------------------
 : DRIFT for 'FT_modprobe_w_param.42'
   Range:     dmesg
   Stimulus:  modprobe test_dynamic_debug p_level_num=3; echo 1 > /sys/module/test_dynamic_debug/parameters/do_prints
   Expected:  '146a1294f452' (146a1294f452e51c12837bbd3ea723fa)
   Got:       '14cf091423c6' (14cf091423c69a188ba45cc39414c1b9)

 Add or replace this line in GOLDEN_RECORDS():
 #K= 14cf091423c69a188ba45cc39414c1b9 FT_modprobe_w_param.42   dmesg

 --- Captured Invariant Dmesg Log Output ---
 test_dd: V1 msg
 test_dd: V2 msg
 test_dd: V1 msg
 test_dd: V2 msg
 -----------------------------------

NB: this drift report came from a CONFIG_DYNAMIC_DEBUG_CORE=y only
build, where the GOLDEN_RECORDS were done on a CONFIG_DYNAMIC_DEBUG=y
build, which had the builtin pr-debugs present and enabled.  This
resulted in a commit to remove the enablement of those builtin
pr_debugs.

Signed-off-by Jim Cromie <jim.cromie@gmail.com>
---
v8: sashiko prompted cleanups
. dont-skip-nomod-config - sashiko complaint vs some comment/statement somewhere
. mktmp-in-test-script
. fn-renames/cleanups: log_ddcmd, my_modname, set_param, verify_control_slice
---
 MAINTAINERS                                        |   1 +
 tools/testing/selftests/dynamic_debug/Makefile     |  10 +
 tools/testing/selftests/dynamic_debug/config       |   8 +
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 775 +++++++++++++++++++++
 .../dynamic_debug/syslog_hash_validation.sh        | 393 +++++++++++
 5 files changed, 1187 insertions(+)

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
index 000000000000..49dd85adb36c
--- /dev/null
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -0,0 +1,775 @@
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
+ifrmmod test_dynamic_debug_submod
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
+
+function verify_modprobe_param_logging {
+    # $1 - parameter name (e.g. do_classes)
+    # $2 - parameter value (e.g. 1)
+    local param="$1"
+    local val="$2"
+
+    # Make sure both modules are completely unloaded to trigger a fresh load
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+
+    # Capture and verify the load-time (modprobe) dmesg logs
+    log_start
+    my_modprobe test_dynamic_debug "${param}=${val}"
+    my_modprobe test_dynamic_debug_submod
+
+    # If it is a state-controlling parameter, trigger the
+    # print-workload 'do_prints=1' inside the same syslog dmesg
+    # capture bookends to verify their actual pr_debug logging!
+
+    if [ "$param" = "p_disjoint_bits" ] || [ "$param" = "p_level_num" ]; then
+        set_param 1 /sys/module/test_dynamic_debug/parameters/do_prints
+    fi
+
+    log_stop
+
+    # Verify param write by direct readback
+    if [ "$param" = "p_disjoint_bits" ] || [ "$param" = "p_level_num" ]; then
+        local readback=$(cat "/sys/module/test_dynamic_debug/parameters/${param}")
+        if (( readback != val )); then
+            echo -e "${RED}: param readback failed: ${param} ${val} != ${readback}${NC}"
+            exit $ksft_fail
+        else
+            [ "$V" -ge 1 ] && \
+		echo -e "${GREEN}✔ Parameter Readback Verified: ${param}=${readback}${NC}"
+        fi
+    fi
+
+    # verify runtime unsetting
+    if [ "$param" = "p_disjoint_bits" ] || [ "$param" = "p_level_num" ]; then
+
+        set_param 0 "/sys/module/test_dynamic_debug/parameters/${param}"
+	verify_control_slice '\[test_dynamic_debug\]'
+
+    fi
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
+	ddcmd_err 'module foo format "parse +p'		# unclosed double quote
+
+	# comments in queries tell the error in the logs
+	ddcmd_err "module foo unknown_keyword value	# no flag err"
+	ddcmd_err "module foo %pm	# bad flag-op "
+	ddcmd_err "module foo +pfmHKDD	# bad flags after good "
+
+	ddcmd_err "w1 w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 w13 w 14 w15 w16 # too many tokens"
+	ddcmd_err "func w2 w3 w4 w5 w6 w7 w8 w9 w10 w11 w12 +p # bad keyword w3"
+	ddcmd_err "module foo line =_ # no line val"
+
+	#
+	ddcmd_err "func foo func bar =_		# func used 2x"
+	ddcmd_err "module foo module baz =_	# module used 2x"
+	ddcmd_err "class D2_CORE class D2_KMS +p # class used 2x"
+	ddcmd_err "module foo +x		# unrecognized flag character"
+
+	# line value errs
+	ddcmd_err "line 10 line 20 +l		# line used 2x"
+	ddcmd_err "line 10a +pl			# line value trailing garbage"
+	ddcmd_err "line 100-10 +pf		# line range error (last < 1st)"
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
+function FT_path_module_queries {
+    v_echo "${GREEN}# TEST_PATH_MODULE_QUERIES ${NC}"
+    ddcmd =_
+
+    # Find how many 'main' modules we have in total (by basename)
+    # Use a precise OR pattern to match exactly [main] or [*/main] and avoid irqdomain
+    local total_main=$(grep -c "\[main\]\|\[[^]]*/main\]" /proc/dynamic_debug/control)
+    v_echo "# found $total_main total 'main' modules"
+
+    if [ $total_main -eq 0 ]; then
+        echo "SKIP - no 'main' modules found to test slashes"
+        return
+    fi
+
+    # Verify a robust, cross-query state-interaction handshake between
+    # narrow path and wide wildcard/basename queries. This dynamically
+    # proves they interact with the exact same underlying callsites!
+
+    # 1. Turn ON specific path, verified under '[init/main]' range
+    ddcmd "module 'init/main' +p" "init/main.c"
+
+    # 2. Turn OFF using wide wildcard query,
+    ddcmd "module '*/main' =_" "init/main.c"
+
+    # 3. Turn ON using wide unscoped basename,
+    ddcmd "module 'main' +p" "init/main.c"
+
+    # 4. Turn OFF using specific narrow path,
+    ddcmd "module 'init/main' =_" "init/main.c"
+}
+
+function FT_hyphen_underscore {
+    v_echo "${GREEN}# TEST_HYPHEN_UNDERSCORE ${NC}"
+    ddcmd =_
+
+    # Find a module with a hyphen in its name (e.g., from the control file)
+    local mod_with_hyphen
+    mod_with_hyphen=$(awk -F'[][]' \
+        '/^[^#:]+:[0-9]+/ { if ($2 ~ /-/) { print $2; exit } }' \
+        /proc/dynamic_debug/control)
+
+    if [ -z "$mod_with_hyphen" ]; then
+        echo "SKIP - no module with hyphen found in /proc/dynamic_debug/control"
+        return
+    fi
+
+    v_echo "# testing hyphen/underscore equivalence for module: $mod_with_hyphen"
+    local mod_with_underscore=$(echo "$mod_with_hyphen" | tr '-' '_')
+    local base_hyphen=$(basename "$mod_with_hyphen")
+    local slice_pattern="\[[^]]*$base_hyphen\]"
+
+    # 1. Enable using literal hyphen name, and record the state fingerprint
+    v_echo "#   trying hyphen name: $mod_with_hyphen"
+    ddcmd "module $mod_with_hyphen +p"
+    # verify_control_slice "$slice_pattern"
+    local hash_hyphen=$(slice_and_hash_ddctrl "$slice_pattern")
+
+    # 2. Disable and enable using underscore name, record the state fingerprint
+    ddcmd =_
+    v_echo "#   trying underscore name: $mod_with_underscore"
+    ddcmd "module $mod_with_underscore +p"
+    # verify_control_slice "$slice_pattern"
+    local hash_underscore=$(slice_and_hash_ddctrl "$slice_pattern")
+
+    # Real-time mathematical proof of hyphen/underscore name equivalence!
+    if [ "$hash_hyphen" != "$hash_underscore" ]; then
+        echo -e "${RED}: Hyphen/Underscore equivalence check failed! " \
+            "Fingerprints do not match.${NC}"
+        echo -e "Hyphen name state hash:     $hash_hyphen"
+        echo -e "Underscore name state hash: $hash_underscore"
+        exit $ksft_fail
+    else
+        v_echo "${GREEN}: Proven: Hyphen/Underscore literal name equivalence matches!${NC}"
+    fi
+
+        # Try kbasename with hyphen (if it has a path)
+    if [ "$base_hyphen" != "$mod_with_hyphen" ]; then
+        ddcmd =_
+        v_echo "#   trying hyphen kbasename: $base_hyphen"
+        ddcmd "module $base_hyphen +pmf"
+        # verify_control_slice "$slice_pattern" # omitted: slice contains dynamic
+        # module info which drifts across different targets
+        local hash_base_hyphen=$(slice_and_hash_ddctrl "$slice_pattern")
+
+        # Prove kbasename hyphen name matches literal path hyphen name (with different flags)!
+        v_echo "#   trying full path hyphen with pmf flags"
+        ddcmd =_
+        ddcmd "module $mod_with_hyphen +pmf"
+        local hash_path_pmf=$(slice_and_hash_ddctrl "$slice_pattern")
+        if [ "$hash_path_pmf" != "$hash_base_hyphen" ]; then
+            echo -e "${RED}: Hyphen kbasename check failed! " \
+                "Fingerprints do not match full-path hyphen enablement.${NC}"
+            exit $ksft_fail
+        else
+            v_echo "${GREEN}: Proven: Hyphen kbasename matches " \
+                "full-path hyphen enablement!${NC}"
+        fi
+    fi
+
+    # 4. Try kbasename with underscore
+    local base_underscore=$(echo "$base_hyphen" | tr '-' '_')
+    ddcmd =_
+    v_echo "#   trying underscore kbasename: $base_underscore"
+    ddcmd "module $base_underscore +pmf"
+    # verify_control_slice "$slice_pattern" # omitted: slice contains dynamic
+    # module info which drifts across different targets
+    local hash_base_underscore=$(slice_and_hash_ddctrl "$slice_pattern")
+
+    # Real-time mathematical proof of hyphen/underscore kbasename equivalence!
+    if [ "$hash_base_hyphen" != "$hash_base_underscore" ] && \
+       [ -n "$hash_base_hyphen" ]; then
+        echo -e "${RED}: Hyphen/Underscore kbasename equivalence check " \
+            "failed! Fingerprints do not match.${NC}"
+        exit $ksft_fail
+    elif [ -n "$hash_base_hyphen" ]; then
+        v_echo "${GREEN}: Proven: Hyphen/Underscore kbasename " \
+            "equivalence matches!${NC}"
+    fi
+
+    ddcmd =_
+}
+
+
+# testing classmap-based query enablers and class configurations
+function FT_test_classes {
+    v_echo "${GREEN}# TEST_CLASSES - classmap-based query enablers and class configs ${NC}"
+
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+    ddcmd =_
+
+    # 1. Verify initial multi-query enablement state via file slice
+    my_modprobe test_dynamic_debug \
+        dyndbg="class,D2_CORE,+pf;class,D2_KMS,+ps;class,D2_ATOMIC,+pm"
+    verify_control_slice '\[test_dynamic_debug\]'
+
+    # 2. Verify state transition and live-printing end-to-end via ddcmd_load!
+    ddcmd_load "class,D2_CORE,+pmf@class,D2_KMS,+pls@class,D2_ATOMIC,+pml" \
+        '\[test_dynamic_debug\]' \
+        "/sys/module/test_dynamic_debug/parameters/do_classes" "1"
+
+    ifrmmod test_dynamic_debug
+}
+
+function FT_classmap_inheritance {
+    v_echo "${GREEN}# TEST_MOD_SUBMOD ${NC}"
+
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+
+    # modprobe with plain-old +p & 3 class enablements
+    my_modprobe test_dynamic_debug \
+	"dyndbg=+p;class D2_CORE +pf;class D2_KMS +pt;class D2_ATOMIC +pm"
+    verify_control_slice '\[test_dynamic_debug\]'
+
+    # fresh start, to clear all above flags (test-fn limits)
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+
+    # act on submod, which loads supermod
+    my_modprobe test_dynamic_debug_submod \
+	"dyndbg=+p;class D2_CORE +pfs;class D2_KMS +pts;class D2_ATOMIC +pmf"
+
+    set_param 0x57 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
+    set_param 4 /sys/module/test_dynamic_debug/parameters/p_level_num
+    verify_control_slice 'test_dynamic_debug'
+
+    set_param 3 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
+    set_param 0 /sys/module/test_dynamic_debug/parameters/p_level_num
+    verify_control_slice 'test_dynamic_debug'
+
+    set_param 0x16 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
+    set_param 0 /sys/module/test_dynamic_debug/parameters/p_level_num
+    verify_control_slice 'test_dynamic_debug'
+
+    # recap DRM_USE_DYNAMIC_DEBUG regression
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+
+    # set super-mod params at load-time
+    my_modprobe test_dynamic_debug p_disjoint_bits=0x16 p_level_num=5
+    verify_control_slice '\[test_dynamic_debug\]'
+
+    # see them picked up by submod
+    my_modprobe test_dynamic_debug_submod
+    verify_control_slice 'test_dynamic_debug'
+
+    # Real-time mathematical proof that load-time (modprobe) parameter parsing
+    # and runtime (sysfs write) parameter configurations are perfectly equivalent!
+    local hash_modprobe=$(slice_and_hash_ddctrl '\[test_dynamic_debug\]')
+
+    # Fresh load with default parameters, then configure them dynamically at runtime
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+    my_modprobe test_dynamic_debug
+    my_modprobe test_dynamic_debug_submod
+    echo 0x16 > /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
+    echo 5 > /sys/module/test_dynamic_debug/parameters/p_level_num
+
+    local hash_sysfs=$(slice_and_hash_ddctrl '\[test_dynamic_debug\]')
+    if [ "$hash_modprobe" != "$hash_sysfs" ]; then
+        echo -e "${RED}: Load-time vs runtime parameter equivalence check failed!${NC}"
+        exit $ksft_fail
+    else
+        v_echo "${GREEN}: Proven: parameter load-time (modprobe) " \
+            "and runtime (sysfs write) are equivalent!${NC}"
+    fi
+
+    # --- Live Content Fingerprinting Phase ---
+    log_start
+    echo 1 > /sys/module/test_dynamic_debug/parameters/do_classes
+    echo 1 > /sys/module/test_dynamic_debug_submod/parameters/do_classes
+    log_stop
+
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+}
+
+function FT_modprobe_w_param {
+    v_echo "${GREEN}# TEST_MODPROBES ${NC}"
+    local verbose
+
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+
+    for verbose in 1 2; do # 3 4 0; do
+	echo $verbose > /sys/module/dynamic_debug/parameters/verbose
+
+	# Verify each parameter load sequence with 100% DRY modularity
+	verify_modprobe_param_logging "do_prints" "1"
+
+	#verify_modprobe_param_logging "do_classes" "1"
+	#verify_modprobe_param_logging "do_bulk" "1"
+
+	# Sequence composite bitmasks to verify disjoint bit transitions
+	for mask in "0x05" "0x12" "0x1f" "0x00"; do
+            verify_modprobe_param_logging "p_disjoint_bits" "$mask"
+	done
+
+	# Sequence levels to verify both growing and shrinking verbose transitions
+	for lvl in "3" "5" "4" "0"; do
+            verify_modprobe_param_logging "p_level_num" "$lvl"
+	done
+    done
+    ddcmd =_
+}
+
+# Built-in Feature Tests (Can run on any CONFIG_DYNAMIC_DEBUG kernel, modular or monolithic)
+builtin_tests=(
+    FT_grammar_ok
+    FT_grammar_errs
+    FT_basic_queries
+    #FT_path_module_queries
+    #FT_hyphen_underscore
+)
+
+# Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
+modular_tests=(
+    #FT_test_classes
+    #FT_classmap_inheritance
+    #FT_modprobe_w_param
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
+#K= bb85d28739876b0fdf1eb426baae8ef7 FT_grammar_errs.1
+#K= 9c405e06fcea50284df82d1ae9692403 FT_grammar_errs.2
+#K= 0b0d9b0e6f4c45c7d75d699fd3b6aa93 FT_grammar_errs.3
+#K= e008644e159c2a9d99a8d0806c06e71e FT_grammar_errs.4
+#K= 11833e6cf8fe8b03869aa4f669b63398 FT_grammar_errs.5
+#K= e85a4b665f5ef141e3f4d4505dec1da1 FT_grammar_errs.6
+#K= 3e1eba65bd936e1276c7e1d76b399595 FT_grammar_errs.7
+#K= e3ac86676e309d4e72ff3da287736c29 FT_grammar_errs.8
+#K= 466d325c23519119f754fa7860bae7c6 FT_grammar_errs.9
+#K= 51c489366cd86c16280858b95adf34ac FT_grammar_errs.10
+#K= dfc632c6c0cd6206b6141dbc5fb989db FT_grammar_errs.11
+#K= 69650fc26e97a78082bd851eb4a5c83b FT_grammar_errs.12
+#K= 5cfe5665962a482f416836793067f2a2 FT_grammar_errs.13
+#K= 661cc9a2d8d3c381bfeae41392432575 FT_grammar_errs.14
+#K= 5dd0accf9be37ce2f4bf697e9bdebe30 FT_grammar_errs.15
+#K= bd8d9cf661c9aca54dac93c74cfc1501 FT_grammar_errs.16
+#K= e991391048f2fdffaaed99ba36b787ed FT_grammar_errs.17
+#K= 82d99278f471ebfbf47eeb19898525cf FT_grammar_errs.18
+#K= 3c8d268c94b0bf97e64999654cd840c4 FT_grammar_errs.19
+#K= 1a448ff3f1df9155cc3acf1e124f24f5 FT_grammar_errs.20
+#K= 76c8a33c585d414fcc3f1c8b5ea5b4b3 FT_grammar_errs.21
+#K= 90cfc66e9d61f5c448353b97baa99145 FT_grammar_errs.22
+#K= 37a51dfd6e84cb64b69d3a0e23e68ceb FT_grammar_errs.23
+#K= 3aefa325b63742710b45e4531152c9d8 FT_grammar_errs.24
+#K= bc8d2c23282cd6834879bc1f1b303d05 FT_grammar_errs.25
+#K= 092ec5530d875be1dc96ad4202fc7dc3 FT_grammar_errs.26
+#K= 98caa2677e9070953a852b27ab57861e FT_grammar_errs.27
+#K= 8d755baa707c7b3b67491bf84708ef08 FT_grammar_errs.28
+#K= 5dd0accf9be37ce2f4bf697e9bdebe30 FT_grammar_errs.29
+#K= 2e37642dc8aee3d04b8a54a76b3b891c FT_grammar_errs.30
+#K= 593c8b4c41932e3bde564a0008627ced FT_grammar_errs.31
+#K= 85a2a0bee8d0cd10f883aa5477d62efb FT_grammar_errs.32
+#K= 3c8d268c94b0bf97e64999654cd840c4 FT_grammar_errs.33
+#K= 1a448ff3f1df9155cc3acf1e124f24f5 FT_grammar_errs.34
+#K= d9f0cffb0898c54690735a71b0d4f3bf FT_grammar_errs.35
+#K= 4cf728b6a32043ea5336a14d0c435312 FT_grammar_errs.36
+#K= a11ae3f86f4e5f539fd6168d318f74b4 FT_grammar_errs.37
+#K= c7d3830b0391f6a773205066b64e15f9 FT_grammar_errs.38
+#K= 5c506ea2bfd050439b580b91543e9be7 FT_grammar_errs.39
+#K= a257660007408f7bb0cb43c99b1c7bb8 FT_grammar_errs.40
+#K= 0082939f100300a7b327b143cf40cb43 FT_grammar_errs.41
+#K= 657ac4360f978687ad25a705b2bb89f1 FT_grammar_errs.42
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
+			  || "$label" == FT_path_module_queries* \
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

