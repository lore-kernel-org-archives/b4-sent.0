From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 16 Sep 2026 09:33:16 -0600
Subject: [PATCH v10 24/38] selftests/dyndbg: Enable FT_classmap_inheritance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-dd-cmap-part2-clean-v10-24-af4cf4767707@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=5931;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=6OJ9UW17PHmqcN0g3YruYiGL+oiRmIXie0aYgidVUu0=;
 b=++kI8qArwuxEzMKHq4StXWqdWptUzDszSvpOM/3L/YkwYo86t5hk2xEofy93NPwpHpVKRXFdf
 X2f9LpeYqQ9DBFrgIBH9nWtjL96clDN6XT1DKf0Sis6HdYVx9uOW20e
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Exercise classmap state inheritance between supermod and submod,
verifying that class settings and controlling parameter states propagate
from parent classmap definitions to dependent class users upon module
load and during runtime reconfiguration.

Add FT_classmap_inheritance to exercise classmap parameter propagation
across test_dynamic_debug and test_dynamic_debug_submod. Enable it under
modular_tests and register its 8 golden record checksums.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 84 +++++++++++++++++++++-
 1 file changed, 83 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index 09a8dbf239dc..51338ebc74bf 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -64,6 +64,7 @@ function ifrmmod {
 }
 
 # Clean up any leftover loaded test modules at initialization
+ifrmmod test_dynamic_debug_submod
 ifrmmod test_dynamic_debug
 
 # ===========================================================================
@@ -196,7 +197,7 @@ function FT_grammar_ok {
 
     # use 4 keywords (max 9 words inc flags)
     ddcmd "module foo file bar.c func buz class D2_CORE +_"	# 4 keywords
-    #ddcmd "module foo file bar.c func buz class D2 line 100 +_" # 5 keywords
+    ddcmd "module foo file bar.c func buz class D2 line 100 +_" # 5 keywords
 
     # 3. Dedicated lineno range grammar assertions (side-effect-free proofs)
     ddcmd "line 42 +_"		# test exact line syntax
@@ -298,6 +299,78 @@ function FT_basic_queries {
     ddcmd "file $f =_" "$f"
 }
 
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
+    set_param 5 /sys/module/test_dynamic_debug/parameters/p_level_num
+    verify_control_slice '\[test_dynamic_debug\]'
+
+    my_modprobe test_dynamic_debug_submod
+    verify_control_slice 'test_dynamic_debug_submod'
+
+    # fresh start, to clear all above flags (test-fn limits)
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+
+    # load submod, which loads supermod
+    my_modprobe test_dynamic_debug_submod \
+	"dyndbg=+p;class D2_CORE +pfs;class D2_KMS +pts;class D2_ATOMIC +pmf"
+    verify_control_slice 'test_dynamic_debug'
+
+    # runtime changes to both
+    set_param 0x57 /sys/module/test_dynamic_debug/parameters/p_disjoint_bits
+    set_param 4 /sys/module/test_dynamic_debug/parameters/p_level_num
+    verify_control_slice 'test_dynamic_debug'
+
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
+    # --- Live Content Fingerprinting Phase ---
+    log_start
+    echo 1 > /sys/module/test_dynamic_debug/parameters/do_prints
+    echo 1 > /sys/module/test_dynamic_debug_submod/parameters/do_prints
+    log_stop
+
+    ifrmmod test_dynamic_debug_submod
+    ifrmmod test_dynamic_debug
+}
+
 # Built-in Feature Tests (Can run on any CONFIG_DYNAMIC_DEBUG kernel, modular or monolithic)
 builtin_tests=(
     FT_grammar_ok
@@ -307,6 +380,7 @@ builtin_tests=(
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
 modular_tests=(
+    FT_classmap_inheritance
 )
 
 # ==============================================================================
@@ -390,6 +464,14 @@ function GOLDEN_RECORDS {
 #K= 02e4fd94602e108cb89bfc70d47a5dad FT_basic_queries.5
 #K= f03a7ca7316e8db4c0e16523dc41e75d FT_basic_queries.6
 #K= c518a50ba30ba8099d0dc874a27ecf16 FT_basic_queries.7
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

