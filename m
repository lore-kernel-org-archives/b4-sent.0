From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:21 -0600
Subject: [PATCH v9 25/39] selftests/dyndbg: enable FT_classmap_inheritance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-25-3a3f621f4a10@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=8242;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=/cFPIETtUjUbabQ5jVBgHBmuSAF3mz8WzsTe35wVcBU=;
 b=7tDeBxhx2rGs16Nz4bYaLQWanrmyqODJeXW0eeGUQ1c0IcczqTJnkRCJiHhtOBT+ukMPz8ZfY
 LcxfJx//Co9C/Ab5ibjjrf/vzzN/e+oGj4kNPbum219QcbUptvgplWL
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

re-enable FT_classmap_inheritance, and comment out writes to missing
test-mod params. tbd where they are.

fix-some-tests-sysl test-tweaks
selftests/dyndbg: sync all results checksums
happened on gandalf, at end of progress_from master+5 in this tree.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 lib/dynamic_debug.c                                |  7 +-
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 76 +++++++---------------
 2 files changed, 30 insertions(+), 53 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 0e25b4d53942..e55747d26515 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -1109,6 +1109,8 @@ static bool ddebug_class_in_range(const int class_id, const struct ddebug_class_
 
 static bool ddebug_user_class_in_range(const int class_id, const struct ddebug_class_user *cli)
 {
+	if (!cli || !cli->map)
+		return false;
 	int base = cli->map->base + cli->offset;
 	return (class_id >= base && class_id < base + cli->map->length);
 }
@@ -1270,14 +1272,12 @@ static void ddebug_sync_classbits(const struct kernel_param *kp, const char *mod
 	switch (dcp->map->map_type) {
 	case DD_CLASS_TYPE_DISJOINT_BITS:
 		val = READ_ONCE(*dcp->bits);
-		ddebug_class_param_clamp_input(&val, kp);
 		new_bits = val;
 		v2pr_info("  %s: classbits: 0x%x\n", KP_NAME(kp), new_bits);
 		ddebug_apply_class_bitmap(dcp, &new_bits, 0UL, modname);
 		break;
 	case DD_CLASS_TYPE_LEVEL_NUM:
 		val = READ_ONCE(*dcp->lvl);
-		ddebug_class_param_clamp_input(&val, kp);
 		new_bits = CLASSMAP_BITMASK(val);
 		v2pr_info("  %s: lvl:%d bits:0x%x\n", KP_NAME(kp), val, new_bits);
 		ddebug_apply_class_bitmap(dcp, &new_bits, 0UL, modname);
@@ -1309,6 +1309,9 @@ static void ddebug_match_apply_kparam(const struct kernel_param *kp,
 static void ddebug_apply_params(const struct ddebug_class_map *cm, const char *mod_name)
 {
 	const struct kernel_param *kp;
+
+	if (!cm)
+		return;
 #if IS_ENABLED(CONFIG_MODULES)
 	int i;
 
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 5ef6e313fa4b..0c9af93aef7c 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -188,7 +188,7 @@ function slice_and_hash_ddctrl {
 # ==============================================================================
 
 function verify_modprobe_param_logging {
-    # $1 - parameter name (e.g. do_classes)
+    # $1 - parameter name (e.g. do_prints)
     # $2 - parameter value (e.g. 1)
     local param="$1"
     local val="$2"
@@ -245,7 +245,7 @@ function FT_grammar_ok {
 
     # use 4 keywords (max 9 words inc flags)
     ddcmd "module foo file bar.c func buz class D2_CORE +_"	# 4 keywords
-    #ddcmd "module foo file bar.c func buz class D2 line 100 +_" # 5 keywords
+    ddcmd "module foo file bar.c func buz class D2 line 100 +_" # 5 keywords
 
     # 3. Dedicated lineno range grammar assertions (side-effect-free proofs)
     ddcmd "line 42 +_"		# test exact line syntax
@@ -484,9 +484,9 @@ function FT_test_classes {
     verify_control_slice '\[test_dynamic_debug\]'
 
     # 2. Verify state transition and live-printing end-to-end via ddcmd_load!
-    ddcmd_load "class,D2_CORE,+pmf@class,D2_KMS,+pls@class,D2_ATOMIC,+pml" \
+    ddcmd_load "class,D2_CORE,+pmf;class,D2_KMS,+pls;class,D2_ATOMIC,+pml" \
         '\[test_dynamic_debug\]' \
-        "/sys/module/test_dynamic_debug/parameters/do_classes" "1"
+        "/sys/module/test_dynamic_debug/parameters/do_prints" "1"
 
     ifrmmod test_dynamic_debug
 }
@@ -502,27 +502,26 @@ function FT_classmap_inheritance {
 	"dyndbg=+p;class D2_CORE +pf;class D2_KMS +pt;class D2_ATOMIC +pm"
     verify_control_slice '\[test_dynamic_debug\]'
 
+    set_param 5 /sys/module/test_dynamic_debug/parameters/p_level_num
+    verify_control_slice '\[test_dynamic_debug\]'
+
+    my_modprobe test_dynamic_debug_submod
+    verify_control_slice 'test_dynamic_debug_submod'
+
     # fresh start, to clear all above flags (test-fn limits)
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
 
-    # act on submod, which loads supermod
+    # load submod, which loads supermod
     my_modprobe test_dynamic_debug_submod \
 	"dyndbg=+p;class D2_CORE +pfs;class D2_KMS +pts;class D2_ATOMIC +pmf"
+    verify_control_slice 'test_dynamic_debug'
 
+    # runtime changes to both
     set_param 0x57 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
     set_param 4 /sys/module/test_dynamic_debug/parameters/p_level_num
     verify_control_slice 'test_dynamic_debug'
 
-    set_param 3 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
-    set_param 0 /sys/module/test_dynamic_debug/parameters/p_level_num
-    verify_control_slice 'test_dynamic_debug'
-
-    set_param 0x16 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
-    set_param 0 /sys/module/test_dynamic_debug/parameters/p_level_num
-    verify_control_slice 'test_dynamic_debug'
-
-    # recap DRM_USE_DYNAMIC_DEBUG regression
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
 
@@ -553,47 +552,16 @@ function FT_classmap_inheritance {
     else
         v_echo "${GREEN}: Proven: parameter load-time (modprobe) " \
             "and runtime (sysfs write) are equivalent!${NC}"
-    fi
-
-    # --- Live Content Fingerprinting Phase ---
+    fi    # --- Live Content Fingerprinting Phase ---
     log_start
-    echo 1 > /sys/module/test_dynamic_debug/parameters/do_classes
-    echo 1 > /sys/module/test_dynamic_debug_submod/parameters/do_classes
+    echo 1 > /sys/module/test_dynamic_debug/parameters/do_prints
+    echo 1 > /sys/module/test_dynamic_debug_submod/parameters/do_prints
     log_stop
 
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
 }
 
-function FT_modprobe_w_param {
-    v_echo "${GREEN}# TEST_MODPROBES ${NC}"
-    local verbose
-
-    ifrmmod test_dynamic_debug_submod
-    ifrmmod test_dynamic_debug
-
-    for verbose in 1 2; do # 3 4 0; do
-	echo $verbose > /sys/module/dynamic_debug/parameters/verbose
-
-	# Verify each parameter load sequence with 100% DRY modularity
-	verify_modprobe_param_logging "do_prints" "1"
-
-	#verify_modprobe_param_logging "do_classes" "1"
-	#verify_modprobe_param_logging "do_bulk" "1"
-
-	# Sequence composite bitmasks to verify disjoint bit transitions
-	for mask in "0x05" "0x12" "0x1f" "0x00"; do
-            verify_modprobe_param_logging "p_disjoint_bits" "$mask"
-	done
-
-	# Sequence levels to verify both growing and shrinking verbose transitions
-	for lvl in "3" "5" "4" "0"; do
-            verify_modprobe_param_logging "p_level_num" "$lvl"
-	done
-    done
-    ddcmd =_
-}
-
 # Built-in Feature Tests (Can run on any CONFIG_DYNAMIC_DEBUG kernel, modular or monolithic)
 builtin_tests=(
     FT_grammar_ok
@@ -605,9 +573,7 @@ builtin_tests=(
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
 modular_tests=(
-    #FT_test_classes
-    #FT_classmap_inheritance
-    #FT_modprobe_w_param
+    FT_classmap_inheritance
 )
 
 # ==============================================================================
@@ -673,6 +639,14 @@ function GOLDEN_RECORDS {
 #K= f2b4f24fece9c55f5a5d28323c2019f8 FT_basic_queries.5
 #K= 8c2dd1164fbcefb721345ce62a864a37 FT_basic_queries.6
 #K= 4542e1e5e7eadcbe8f90a9c934635618 FT_basic_queries.7
+#K= fb294f02a4207b28b2a874524ef07afd FT_classmap_inheritance.1
+#K= 7a0b87016fdc237077dfe96bbbb3661b FT_classmap_inheritance.2
+#K= 2784d60f5056fc5cc03b3ceb854293f5 FT_classmap_inheritance.3
+#K= bf66aaf8ff612272c0cda29778ed2131 FT_classmap_inheritance.4
+#K= 49fdd29d91a4c1d16f8b59bb431e741b FT_classmap_inheritance.5
+#K= a8aa244285d048b5ebe33061fa99c424 FT_classmap_inheritance.6
+#K= 3060b86a0f553dd5a826bb7023284925 FT_classmap_inheritance.7
+#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.8
 EOF
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do

-- 
2.55.0

