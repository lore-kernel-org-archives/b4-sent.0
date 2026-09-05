From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 05 Sep 2026 12:13:48 -0600
Subject: [PATCH v8 34/43] selftests: enable comma-terminator tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-dd-cmap-part2-clean-v8-34-a4cc0674f6fd@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=2242;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=tMqhaZmDF9bTmirtnqYMRbK6dcbxa6wfAKt/4SM022o=;
 b=xgHFA+2oB1q9mAkzx96vqnFYrJ8jxI3njoanBu3jvT68vnXew095K4UcW1gakAgZ1Ruy5mA2P
 f+Wo0qCAyXmAJCl/k5a3K5xB+iwGu9UXJf5R57+49L04Wy4jQOc0ZlF
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index a9389a98de8b..f0b18afa7372 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -462,6 +462,23 @@ function FT_hyphen_underscore {
     ddcmd =_
 }
 
+# test parsing on spaces, commas. testing against builtin [kernel/params]
+function FT_comma_terminators {
+    v_echo "${GREEN}# COMMA_TERMINATOR_TESTS ${NC}"
+    if [ $LACK_DD_BUILTIN -eq 1 ]; then
+	echo "SKIP - test requires params, which is a builtin module"
+	return
+    fi
+    ddcmd "module params =_"
+
+    ddcmd "module,params,=_" 'kernel/params.c'
+    ddcmd "module,params,+mf" 'kernel/params.c'
+    # ignore empty tokens
+    ddcmd ",module ,, ,  params, -p" 'kernel/params.c'
+    ddcmd " , module ,,, ,  params, -m" 'kernel/params.c'
+
+    ddcmd =_
+}
 # testing classmap-based query enablers and class configurations
 function FT_test_classes {
     v_echo "${GREEN}# TEST_CLASSES - classmap-based query enablers and class configs ${NC}"
@@ -573,6 +590,7 @@ builtin_tests=(
     FT_basic_queries
     FT_path_module_queries
     FT_hyphen_underscore
+    FT_comma_terminators
 )
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
@@ -649,6 +667,10 @@ function GOLDEN_RECORDS {
 #K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.2
 #K= 4b902c159d7f08f91377bf0a353e0051 FT_path_module_queries.3
 #K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.4
+#K= 68b329da9893e34099c7d8ad5cb9c940 FT_comma_terminators.1
+#K= 99985cce918eb5108ecb3658249f6bc7 FT_comma_terminators.2
+#K= 68b329da9893e34099c7d8ad5cb9c940 FT_comma_terminators.3
+#K= 85f93d30f4006c99a806639970b92f20 FT_comma_terminators.4
 #K= d4923595eea382923aee64aed15c7c35 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
 #K= 40a294034c886787960f4c751b196da9 FT_test_classes.3

-- 
2.55.0

