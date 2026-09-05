From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 05 Sep 2026 12:13:45 -0600
Subject: [PATCH v8 31/43] dyndbg-test: add do_bulk testpoint, rename
 do_prints to do_classes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-dd-cmap-part2-clean-v8-31-a4cc0674f6fd@gmail.com>
References: <20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com>
In-Reply-To: <20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com>
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=16144;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=R5mr9zsC1BxicGXwFV3x7f22yjS39YvYsdCri/1Vebc=;
 b=Xa72bU5wNO/2UwQenV4Tb2H8Yg/iJO4Zym4+6gPF9dqf069xM7YHyCwUB00M5QgmXxYRNsyTh
 ha4W3x6Ke9VAd6i5SyPQZmGUrojdcASvKbpoXUHXz1YOrMHYGH4oYhe
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
v8: fix a test which had commas, from the future, adjust KRECs
---
 lib/test_dynamic_debug.c                           | 104 ++++++++++++-----
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 128 ++++++++++++++-------
 2 files changed, 164 insertions(+), 68 deletions(-)

diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 01ce07001d4c..39499e52d7c0 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -29,24 +29,43 @@
 
 #include <linux/module.h>
 
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
@@ -103,7 +122,10 @@ enum cat_disjoint_bits {
 	D2_DRMRES };
 
 /* numeric verbosity, V2 > V1 related.  V1 is > D2_DRMRES */
-enum cat_level_num { V1 = 16, V2, V3, V4, V5, V6, V7 };
+enum cat_level_num { V1 = 16, V2, V3, V4, V5, V6, V7, V8 };
+
+/* test _USE_ w offset */
+enum cat_level_offset { Vu1 = V1 + 8, Vu2, Vu3, Vu4, Vu5, Vu6, Vu7, Vu8 };
 
 /* recapitulate DRM's multi-classmap setup */
 #if !defined(TEST_DYNAMIC_DEBUG_SUBMOD)
@@ -136,18 +158,6 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(map_level_num, DD_CLASS_TYPE_LEVEL_NUM,
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
@@ -160,6 +170,19 @@ DYNAMIC_DEBUG_CLASSMAP_DEFINE(fail_emptyclass, 0, 0 /* ,empty */);
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
 
@@ -213,17 +236,40 @@ static void do_levels(void)
 #endif
 }
 
-static void do_prints(void)
+static void do_classes(unsigned int ct)
 {
-	pr_debug("do_prints:\n");
-	do_cats();
-	do_levels();
+	/* maybe clamp this */
+	pr_debug("do_classes %d times:\n", ct);
+	for (; ct; ct--) {
+		do_cats();
+		do_levels();
+	}
+}
+
+static void do_bulk(unsigned int ct)
+{
+	int i;
+
+	pr_debug("do_bulk %d times:\n", ct);
+	for (i = 1; i <= ct; i++) {
+		pr_debug("bulk msg %d.0\n", i);
+		pr_debug("bulk msg %d.1\n", i);
+		pr_debug("bulk msg %d.2\n", i);
+		pr_debug("bulk msg %d.3\n", i);
+		pr_debug("bulk msg %d.4\n", i);
+		pr_debug("bulk msg %d.5\n", i);
+		pr_debug("bulk msg %d.6\n", i);
+		pr_debug("bulk msg %d.7\n", i);
+		pr_debug("bulk msg %d.8\n", i);
+		pr_debug("bulk msg %d.9\n", i);
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
index 485773f49eb2..3d9c777a0fc3 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -209,7 +209,7 @@ function verify_modprobe_param_logging {
     # capture bookends to verify their actual pr_debug logging!
 
     if [ "$param" = "p_disjoint_bits" ] || [ "$param" = "p_level_num" ]; then
-        set_param 1 /sys/module/test_dynamic_debug/parameters/do_prints
+        set_param 1 /sys/module/test_dynamic_debug/parameters/do_classes
     fi
 
     log_stop
@@ -472,44 +472,29 @@ function FT_test_classes {
 
     # 1. Verify initial multi-query enablement state via file slice
     my_modprobe test_dynamic_debug \
-        dyndbg="class,D2_CORE,+pf;class,D2_KMS,+ps;class,D2_ATOMIC,+pm"
+        dyndbg="class D2_CORE,+pf;class D2_KMS,+ps;class D2_ATOMIC +pm"
     verify_control_slice '\[test_dynamic_debug\]'
 
     # 2. Verify state transition and live-printing end-to-end via ddcmd_load!
-    ddcmd_load "class,D2_CORE,+pmf;class,D2_KMS,+pls;class,D2_ATOMIC,+pml" \
+    ddcmd_load "class D2_CORE +pmf;class D2_KMS +pls;class D2_ATOMIC +pml" \
         '\[test_dynamic_debug\]' \
-        "/sys/module/test_dynamic_debug/parameters/do_prints" "1"
+        "/sys/module/test_dynamic_debug/parameters/do_classes" "1"
 
     ifrmmod test_dynamic_debug
 }
 
 function FT_classmap_inheritance {
-    v_echo "${GREEN}# TEST_MOD_SUBMOD ${NC}"
+    v_echo "${GREEN}# TEST_MOD_SUBMOD - Classmap state inheritance between supermod and submod ${NC}"
 
     ifrmmod test_dynamic_debug_submod
     ifrmmod test_dynamic_debug
 
-    # modprobe with plain-old +p & 3 class enablements
-    my_modprobe test_dynamic_debug \
-	"dyndbg=+p;class D2_CORE +pf;class D2_KMS +pt;class D2_ATOMIC +pm"
-    verify_control_slice '\[test_dynamic_debug\]'
-
-    set_param 5 /sys/module/test_dynamic_debug/parameters/p_level_num
-    verify_control_slice '\[test_dynamic_debug\]'
-
-    my_modprobe test_dynamic_debug_submod
-    verify_control_slice 'test_dynamic_debug_submod'
-
-    # fresh start, to clear all above flags (test-fn limits)
-    ifrmmod test_dynamic_debug_submod
-    ifrmmod test_dynamic_debug
-
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
@@ -517,19 +502,17 @@ function FT_classmap_inheritance {
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
@@ -544,16 +527,45 @@ function FT_classmap_inheritance {
     else
         v_echo "${GREEN}: Proven: parameter load-time (modprobe) " \
             "and runtime (sysfs write) are equivalent!${NC}"
-    fi    # --- Live Content Fingerprinting Phase ---
+    fi
+
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
@@ -565,7 +577,9 @@ builtin_tests=(
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
 modular_tests=(
+    FT_test_classes
     FT_classmap_inheritance
+    FT_modprobe_w_param
 )
 
 # ==============================================================================
@@ -582,7 +596,7 @@ modular_tests=(
 # ==============================================================================
 function GOLDEN_RECORDS {
     cat << 'EOF' | {
-#K= f3dbd5afb9aa1750f93275b634499e22 FT_grammar_errs.1
+#K= f3dbd5afb9aa1750f93275b634499e22 FT_grammar_errs.1   
 #K= 200c01632c52a63f6d186da1c6460740 FT_grammar_errs.2
 #K= 7d7141900ce6e32f15c99202309c63a4 FT_grammar_errs.3
 #K= 1bb798a5831d0119789d424ef6cb55c4 FT_grammar_errs.4
@@ -635,14 +649,50 @@ function GOLDEN_RECORDS {
 #K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.2
 #K= 4b902c159d7f08f91377bf0a353e0051 FT_path_module_queries.3
 #K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.4
-#K= fb294f02a4207b28b2a874524ef07afd FT_classmap_inheritance.1
-#K= 7a0b87016fdc237077dfe96bbbb3661b FT_classmap_inheritance.2
-#K= 2784d60f5056fc5cc03b3ceb854293f5 FT_classmap_inheritance.3
-#K= bf66aaf8ff612272c0cda29778ed2131 FT_classmap_inheritance.4
-#K= 49fdd29d91a4c1d16f8b59bb431e741b FT_classmap_inheritance.5
-#K= a8aa244285d048b5ebe33061fa99c424 FT_classmap_inheritance.6
-#K= 3060b86a0f553dd5a826bb7023284925 FT_classmap_inheritance.7
-#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.8
+#K= 5d38e4cca64da64a4d7f433398668836 FT_test_classes.1
+#K= 5516e3d13cba7ea4197a7fb6c033887a FT_test_classes.2
+#K= a3677b84d39c42c24d879f34f879aa07 FT_test_classes.3
+#K= 38e813e9025107ac3e24226b8d487a92 FT_classmap_inheritance.1
+#K= 9b82b12a35ad98ef26183db15071f70e FT_classmap_inheritance.2
+#K= d4937472530af6fdcb0a2440d4a366ea FT_classmap_inheritance.3
+#K= fea6f925b829f75a5b2d4e837738fa12 FT_classmap_inheritance.4
+#K= 7e92245008439ee79fe2460aeaa16a9b FT_classmap_inheritance.5
+#K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.1
+#K= 94610c57ac44bd7011002a654fd78f93 FT_modprobe_w_param.2
+#K= c1309e18dc9bf2f57184fa13164d917d FT_modprobe_w_param.3
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.4
+#K= a1232e658d95fbca8b23a69e9a0db965 FT_modprobe_w_param.5
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.6
+#K= af7b3d532325b1c5ab990e4b32fed577 FT_modprobe_w_param.7
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.8
+#K= 591411c42cf52d7c4c46d76bcc345a5f FT_modprobe_w_param.9
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.10
+#K= b0435304108118e64529469e59332111 FT_modprobe_w_param.11
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.12
+#K= 4d036833ce9f661057a4e13d97295c65 FT_modprobe_w_param.13
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.14
+#K= 5c3c6ecf6a46f9ccebd60c5ca9ebdbb7 FT_modprobe_w_param.15
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.16
+#K= 73a93377a823739e8aae44856a20fa7f FT_modprobe_w_param.17
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.18
+#K= 10464b2c3e3972f05e93c609700f8fb2 FT_modprobe_w_param.19
+#K= 10464b2c3e3972f05e93c609700f8fb2 FT_modprobe_w_param.20
+#K= 07c1f81d5a58675a291dc77acd6938c4 FT_modprobe_w_param.21
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.22
+#K= b070066b0eb13a033446bd05850b15e2 FT_modprobe_w_param.23
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.24
+#K= 32ca47823c27e629e03c21aebfc25095 FT_modprobe_w_param.25
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.26
+#K= 7b91db8e9f160aebb1ee87fab2232404 FT_modprobe_w_param.27
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.28
+#K= e393499e02677de414e478f4e710eeb9 FT_modprobe_w_param.29
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.30
+#K= 375e38613af3b49bb7c7689dfecf4177 FT_modprobe_w_param.31
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.32
+#K= 745a61d20e26a6a22db0b99420fea80a FT_modprobe_w_param.33
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.34
+#K= 3d2538bf868e71bff17c768cf118c352 FT_modprobe_w_param.35
+#K= 030cda0a59aaae95750d5ec55acbcb8c FT_modprobe_w_param.36
 EOF
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do

-- 
2.55.0

