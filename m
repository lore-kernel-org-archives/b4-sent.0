From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:19 -0600
Subject: [PATCH v10 27/38] dyndbg-test: add do_bulk testpoint, rename
 do_prints to do_classes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-27-af4cf4767707@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=18048;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=BbVWO2CUWoqwRkFpvSv00hF1NF3LUkYxIrEl0SeQGrw=;
 b=WBvq6N+TjydOXXp0+TusA7T9jHiu18/56aFNnmP+XcQvbgluFS8p0YQLzkVbeRj+pzqf5NUQ6
 vSBtDQ1OpA/CMYQ/wUY1QpnVfrOJ3WKz/QRtSQ8nfTW97WzNhP0X20C
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

test_dynamic_debug.ko currently has the do_prints sysnode to support
testing of the classmaps feature, it calls ~16 class'd pr_debug()s,
*once* for each class defined in the module.

Improve the versatility of this support by:

 1. changing do_prints() to do_classes()
    to better align with its actual purpose

 2. new parameters/do_bulk & do_bulk(N):
    loops over 10 pr_debugs, N times
    creates idempotent non-repetetive (ie 1..N lines) output
    meant for creating high-volume workloads

 3. using common param-ops for both (no reason not to)
    ie: do_classes(N) now accepts work-count.

So now we can generate significant workloads with a single write.

    modprobe test_dynamic_debug dyndbg=+p
    echo 100  > /sys/module/test_dynamic_debug/parameters/do_classes
    echo 2000 > /sys/module/test_dynamic_debug/parameters/do_bulk

TODO: enable do_bulk() callsites by default, since the modprobe is an
explicit act, the user intends to use it, lets turn it on.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v9:
. use unsigned int for loop index in do_bulk() to prevent wrapping lockups on UINT_MAX.
. add cond_resched() to do_classes() and do_bulk() loops.
v8: fix a test which had commas, from the future, adjust KRECs
---
 lib/test_dynamic_debug.c                           | 111 ++++++++++----
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 170 +++++++++++++++++----
 2 files changed, 224 insertions(+), 57 deletions(-)

diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 01ce07001d4c..560e23f14ac8 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -28,25 +28,45 @@
 #endif
 
 #include <linux/module.h>
+#include <linux/sched.h>
 
-/* re-gen output by reading or writing sysfs node: do_prints */
+/* re-trigger debug output by reading or writing sysfs nodes: do_classes or do_bulk */
+static void do_classes(unsigned int); /* device under test */
+static void do_bulk(unsigned int);    /* device under test */
 
-static void do_prints(void); /* device under test */
-static int param_set_do_prints(const char *instr, const struct kernel_param *kp)
+static int param_set_do_repeats(const char *instr, const struct kernel_param *kp)
 {
-	do_prints();
+	int rc;
+	unsigned int ct;
+	void (*repeat_fn)(unsigned int) = kp->arg;
+
+	rc = kstrtouint(instr, 0, &ct);
+	if (rc) {
+		pr_err("expecting numeric input, using 1 instead\n");
+		ct = 1;
+	}
+
+	repeat_fn(ct);
+
 	return 0;
 }
-static int param_get_do_prints(char *buffer, const struct kernel_param *kp)
+
+static int param_get_do_repeats(char *buffer, const struct kernel_param *kp)
 {
-	do_prints();
-	return scnprintf(buffer, PAGE_SIZE, "did do_prints\n");
+	void (*repeat_fn)(unsigned int) = kp->arg;
+
+	repeat_fn(1);
+
+	return scnprintf(buffer, PAGE_SIZE, "did 1 %s\n", kp->name);
 }
-static const struct kernel_param_ops param_ops_do_prints = {
-	.set = param_set_do_prints,
-	.get = param_get_do_prints,
+
+static const struct kernel_param_ops param_ops_do_repeats = {
+	.set = param_set_do_repeats,
+	.get = param_get_do_repeats,
 };
-module_param_cb(do_prints, &param_ops_do_prints, NULL, 0600);
+
+module_param_cb(do_classes, &param_ops_do_repeats, do_classes, 0600);
+module_param_cb(do_bulk, &param_ops_do_repeats, do_bulk, 0600);
 
 /*
  * Using the CLASSMAP api:
@@ -103,7 +123,10 @@ enum cat_disjoint_bits {
 	D2_DRMRES };
 
 /* numeric verbosity, V2 > V1 related.  V1 is > D2_DRMRES */
-enum cat_level_num { V1 = 16, V2, V3, V4, V5, V6, V7 };
+enum cat_level_num { V1 = 16, V2, V3, V4, V5, V6, V7, V8 };
+
+/* test _USE_ w offset */
+enum cat_level_offset { Vu1 = V1 + 8, Vu2, Vu3, Vu4, Vu5, Vu6, Vu7, Vu8 };
 
 /* recapitulate DRM's multi-classmap setup */
 #if !defined(TEST_DYNAMIC_DEBUG_SUBMOD)
@@ -126,7 +149,7 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_disjoint_bits, DD_CLASS_TYPE_DISJOINT_BITS,
 			      "D2_DRMRES");
 
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_level_num, DD_CLASS_TYPE_LEVEL_NUM,
-			      V1, "V1", "V2", "V3", "V4", "V5", "V6", "V7");
+			      V1, "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8");
 
 #ifdef FORCE_CLASSID_CONFLICT
 /*
@@ -136,18 +159,6 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_level_num, DD_CLASS_TYPE_LEVEL_NUM,
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(classid_range_conflict, 0, D2_CORE + 1, "D3_CORE");
 #endif
 
-#else /* TEST_DYNAMIC_DEBUG_SUBMOD */
-
-/*
- * in submod/drm-drivers, use the classmaps defined in top/parent
- * module above.
- */
-
-DYNAMIC_DEBUG_CLASSMAP_USE(map_disjoint_bits);
-DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 7);
-
-enum cat_level_offset { Vu1 = V1 + 7, Vu2, Vu3, Vu4, Vu5, Vu6, Vu7 };
-
 #if defined(DD_MACRO_ARGCHECK)
 /*
  * Exersize compile-time arg-checks in DYNAMIC_DEBUG_CLASSMAP_DEFINE.
@@ -160,6 +171,19 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(fail_emptyclass, 0, 0 /* ,empty */);
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(fail_maptype, 3, 10, "no such type");
 DYNAMIC_DEBUG_CLASSMAP_DEFINE(fail_base_len, 0, 60,
 			      "base", "plus", "classes", "length", "too-big");
+#endif
+
+#else /* TEST_DYNAMIC_DEBUG_SUBMOD */
+
+/*
+ * in submod/drm-drivers, use the classmaps defined in top/parent
+ * module above.
+ */
+
+DYNAMIC_DEBUG_CLASSMAP_USE(map_disjoint_bits);
+DYNAMIC_DEBUG_CLASSMAP_USE_(map_level_num, 7);
+
+#if defined(DD_MACRO_ARGCHECK)
 DYNAMIC_DEBUG_CLASSMAP_USE_(fail_offset_big, 100);
 #endif /* DD_MACRO_ARGCHECK */
 
@@ -202,6 +226,7 @@ static void do_levels(void)
 	prdbg(V5);
 	prdbg(V6);
 	prdbg(V7);
+	prdbg(V8);
 #else
 	prdbg(Vu1);
 	prdbg(Vu2);
@@ -210,20 +235,46 @@ static void do_levels(void)
 	prdbg(Vu5);
 	prdbg(Vu6);
 	prdbg(Vu7);
+	prdbg(Vu8);
 #endif
 }
 
-static void do_prints(void)
+static void do_classes(unsigned int ct)
 {
-	pr_debug("do_prints:\n");
-	do_cats();
-	do_levels();
+	/* maybe clamp this */
+	pr_debug("do_classes %u times:\n", ct);
+	for (; ct; ct--) {
+		do_cats();
+		do_levels();
+		cond_resched();
+	}
+}
+
+static void do_bulk(unsigned int ct)
+{
+	unsigned int i;
+
+	pr_debug("do_bulk %u times:\n", ct);
+	for (i = 0; i < ct; i++) {
+		pr_debug("bulk msg %u.0\n", i + 1);
+		pr_debug("bulk msg %u.1\n", i + 1);
+		pr_debug("bulk msg %u.2\n", i + 1);
+		pr_debug("bulk msg %u.3\n", i + 1);
+		pr_debug("bulk msg %u.4\n", i + 1);
+		pr_debug("bulk msg %u.5\n", i + 1);
+		pr_debug("bulk msg %u.6\n", i + 1);
+		pr_debug("bulk msg %u.7\n", i + 1);
+		pr_debug("bulk msg %u.8\n", i + 1);
+		pr_debug("bulk msg %u.9\n", i + 1);
+		cond_resched();
+	}
 }
 
 static int __init test_dynamic_debug_init(void)
 {
 	pr_debug("init start\n");
-	do_prints();
+	do_classes(1);
+	do_bulk(1);
 	pr_debug("init done\n");
 	return 0;
 }
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 51338ebc74bf..1bea45507352 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -185,6 +185,54 @@ function slice_and_hash_ddctrl {
     echo "$slice" | tr -d '\r' | md5sum | cut -d' ' -f1
 }
 
+# ==============================================================================
+
+function verify_modprobe_param_logging {
+    # $1 - parameter name (e.g. do_prints)
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
+        set_param 1 /sys/module/test_dynamic_debug/parameters/do_classes
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
 # ==============================================================================
 # FEATURE TESTS (FT_*)
 #
@@ -299,33 +347,38 @@ function FT_basic_queries {
     ddcmd "file $f =_" "$f"
 }
 
-function FT_classmap_inheritance {
-    v_echo "${GREEN}# TEST_MOD_SUBMOD ${NC}"
+# testing classmap-based query enablers and class configurations
+function FT_test_classes {
+    v_echo "${GREEN}# TEST_CLASSES - classmap-based query enablers and class configs ${NC}"
 
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
+    ddcmd =_
 
-    # modprobe with plain-old +p & 3 class enablements
+    # 1. Verify initial multi-query enablement state via file slice
     my_modprobe test_dynamic_debug \
-	"dyndbg=+p;class D2_CORE +pf;class D2_KMS +pt;class D2_ATOMIC +pm"
+        dyndbg="class D2_CORE,+pf;class D2_KMS,+ps;class D2_ATOMIC +pm"
     verify_control_slice '\[test_dynamic_debug\]'
 
-    set_param 5 /sys/module/test_dynamic_debug/parameters/p_level_num
-    verify_control_slice '\[test_dynamic_debug\]'
+    # 2. Verify state transition and live-printing end-to-end via ddcmd_load!
+    ddcmd_load "class D2_CORE +pmf;class D2_KMS +pls;class D2_ATOMIC +pml" \
+        '\[test_dynamic_debug\]' \
+        "/sys/module/test_dynamic_debug/parameters/do_classes" "1"
 
-    my_modprobe test_dynamic_debug_submod
-    verify_control_slice 'test_dynamic_debug_submod'
+    ifrmmod test_dynamic_debug
+}
+function FT_classmap_inheritance {
+    v_echo "${GREEN}# TEST_MOD_SUBMOD - Classmap state inheritance between supermod and submod ${NC}"
 
-    # fresh start, to clear all above flags (test-fn limits)
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
 
-    # load submod, which loads supermod
+    # 1. Load submod directly (which auto-loads supermod with default parameters)
     my_modprobe test_dynamic_debug_submod \
 	"dyndbg=+p;class D2_CORE +pfs;class D2_KMS +pts;class D2_ATOMIC +pmf"
     verify_control_slice 'test_dynamic_debug'
 
-    # runtime changes to both
+    # 2. Runtime parameter changes to supermod propagate to submod descriptors
     set_param 0x57 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
     set_param 4 /sys/module/test_dynamic_debug/parameters/p_level_num
     verify_control_slice 'test_dynamic_debug'
@@ -333,19 +386,17 @@ function FT_classmap_inheritance {
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
 
-    # set super-mod params at load-time
+    # 3. Pre-initialize supermod parameter state at load-time
     my_modprobe test_dynamic_debug p_disjoint_bits=0x16 p_level_num=5
     verify_control_slice '\[test_dynamic_debug\]'
 
-    # see them picked up by submod
+    # 4. Verify submod inherits pre-initialized supermod classmap parameter state upon load
     my_modprobe test_dynamic_debug_submod
     verify_control_slice 'test_dynamic_debug'
 
-    # Real-time mathematical proof that load-time (modprobe) parameter parsing
-    # and runtime (sysfs write) parameter configurations are perfectly equivalent!
+    # 5. Prove load-time (modprobe) and runtime (sysfs write) parameter equivalence
     local hash_modprobe=$(slice_and_hash_ddctrl '\[test_dynamic_debug\]')
 
-    # Fresh load with default parameters, then configure them dynamically at runtime
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
     my_modprobe test_dynamic_debug
@@ -361,16 +412,43 @@ function FT_classmap_inheritance {
         v_echo "${GREEN}: Proven: parameter load-time (modprobe) " \
             "and runtime (sysfs write) are equivalent!${NC}"
     fi
-    # --- Live Content Fingerprinting Phase ---
+    # 6. End-to-end syslog content logging verification
     log_start
-    echo 1 > /sys/module/test_dynamic_debug/parameters/do_prints
-    echo 1 > /sys/module/test_dynamic_debug_submod/parameters/do_prints
+    echo 1 > /sys/module/test_dynamic_debug/parameters/do_classes
+    echo 1 > /sys/module/test_dynamic_debug_submod/parameters/do_classes
     log_stop
 
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
 }
 
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
+	verify_modprobe_param_logging "do_classes" "1"
+	verify_modprobe_param_logging "do_bulk" "1"
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
 # Built-in Feature Tests (Can run on any CONFIG_DYNAMIC_DEBUG kernel, modular or monolithic)
 builtin_tests=(
     FT_grammar_ok
@@ -380,7 +458,9 @@ builtin_tests=(
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
 modular_tests=(
+    FT_test_classes
     FT_classmap_inheritance
+    FT_modprobe_w_param
 )
 
 # ==============================================================================
@@ -464,14 +544,50 @@ function GOLDEN_RECORDS {
 #K= 02e4fd94602e108cb89bfc70d47a5dad FT_basic_queries.5
 #K= f03a7ca7316e8db4c0e16523dc41e75d FT_basic_queries.6
 #K= c518a50ba30ba8099d0dc874a27ecf16 FT_basic_queries.7
-#K= fb294f02a4207b28b2a874524ef07afd FT_classmap_inheritance.1
-#K= 7a0b87016fdc237077dfe96bbbb3661b FT_classmap_inheritance.2
-#K= 2784d60f5056fc5cc03b3ceb854293f5 FT_classmap_inheritance.3
-#K= bf66aaf8ff612272c0cda29778ed2131 FT_classmap_inheritance.4
-#K= 49fdd29d91a4c1d16f8b59bb431e741b FT_classmap_inheritance.5
-#K= a8aa244285d048b5ebe33061fa99c424 FT_classmap_inheritance.6
-#K= 3060b86a0f553dd5a826bb7023284925 FT_classmap_inheritance.7
-#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.8
+#K= 69f1958beef98211d4181f9ded9787c4 FT_test_classes.1
+#K= 5516e3d13cba7ea4197a7fb6c033887a FT_test_classes.2
+#K= 22213a7bf431c3e0efd3edbfcba69677 FT_test_classes.3
+#K= 934d8677872fe26bd636a6c3d6416aa2 FT_classmap_inheritance.1
+#K= cd1389958807063baa1ea4b06c61fa02 FT_classmap_inheritance.2
+#K= 0708a283f0f1959135c797e36119e4af FT_classmap_inheritance.3
+#K= 05f6efb80299d24cde65174f64d97308 FT_classmap_inheritance.4
+#K= 7e92245008439ee79fe2460aeaa16a9b FT_classmap_inheritance.5
+#K= 53d1b6875b65c79cfd759e209ae50b11 FT_modprobe_w_param.1
+#K= 53d1b6875b65c79cfd759e209ae50b11 FT_modprobe_w_param.2
+#K= 79d912e2aeb04dea70f9c7e701333f0a FT_modprobe_w_param.3
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.4
+#K= 7cd75277388a6e7cf9c849442388f4af FT_modprobe_w_param.5
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.6
+#K= 9196c43693f5e6059f3512e4d87e7347 FT_modprobe_w_param.7
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.8
+#K= f9cee4512e5604603e0262fba4bea223 FT_modprobe_w_param.9
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.10
+#K= b6a62433165f6423b81417f782551ab9 FT_modprobe_w_param.11
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.12
+#K= de89753b843449d11da14240c4da4cad FT_modprobe_w_param.13
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.14
+#K= 1d966d0cae735457791c93a86e9e1650 FT_modprobe_w_param.15
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.16
+#K= 1aacb7c196a8354c46c60c73d78c6bf2 FT_modprobe_w_param.17
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.18
+#K= e62014acf5ab6a76dfbfbcf67b2ca0e8 FT_modprobe_w_param.19
+#K= e62014acf5ab6a76dfbfbcf67b2ca0e8 FT_modprobe_w_param.20
+#K= 58c009cb287fa5df3f8c1c72c832cb42 FT_modprobe_w_param.21
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.22
+#K= e7831be2aac4a82daba43966b9d31e19 FT_modprobe_w_param.23
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.24
+#K= 4df2fbc0cae329debb14bedb5e7d86c0 FT_modprobe_w_param.25
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.26
+#K= 7fa4c84490c42c750986614c3539d56a FT_modprobe_w_param.27
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.28
+#K= 1eb866a813551061cd73178ba7833543 FT_modprobe_w_param.29
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.30
+#K= a9e7424ed7b02696b5e12108971792dd FT_modprobe_w_param.31
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.32
+#K= 5323d7746d983cdcfda4866255cd5123 FT_modprobe_w_param.33
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.34
+#K= 7f961a7d3facd89bdd4b9d8e7b5541e9 FT_modprobe_w_param.35
+#K= 6a320774e2b535ceb89d6cdde6f5d0fb FT_modprobe_w_param.36
 EOF
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do

-- 
2.55.0

