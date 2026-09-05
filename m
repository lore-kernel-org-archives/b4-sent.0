From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 05 Sep 2026 12:13:49 -0600
Subject: [PATCH v8 35/43] dyndbg: split multi-query strings with @
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-dd-cmap-part2-clean-v8-35-a4cc0674f6fd@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=6505;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=z2Xf/mk9z8sNrbYhXGijk7HKJ6AHG4/NBKYqQ79X+aQ=;
 b=5CVLLP5tSNbmi0HMBnceJZ4BXAt6FMVv6xmDSUVqmN6T5rCh2WiOfB4J/1lQOWYojtVHDlnPf
 jJlNDUm/GkRB16iaXMSrSWwpH0Zb9O6SQ61tTSRhpXd2KFaiu7bLGQ5
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since
commit 85f7f6c0edb8 ("dynamic_debug: process multiple debug-queries on a line")

Multi-query commands have been allowed:

  modprobe drm dyndbg="class DRM_UT_CORE +p; class DRM_UT_KMS +p"
  modprobe drm dyndbg=<<EOX
     class DRM_UT_CORE +p
     class DRM_UT_KMS +p
  EOX

More recently, the need for quoting was avoided by treating a comma
like a space/token-terminator:

  modprobe drm dyndbg=class,DRM_UT_CORE,+p\;class,DRM_UT_KMS,+p

That works, but it needs the escaped semicolon, which is a shell
special-char (one of the bash control operators), so it is brittle
when passed in/down/around scripts.

So this patch adds '@' to the existing ';' and '\n' multi-command
separators, which is more shell-friendly, so you can more fully avoid
quoting and escaping hassles.

Update selftests script, adding a multi-query split on @

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v5: avoid +t flag in content tests - pid is not predictable.
    remove Reviewed-by: <louis.chauvet@bootlin.com> - too many changes

v2:

replace '%' with '@' as multi-query splitter, as it is:
 - not a sshell special cahr
 - allows matching on format strings with format specifiers
---
 Documentation/admin-guide/dynamic-debug-howto.rst  |  8 +++++---
 lib/dynamic_debug.c                                |  2 +-
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 24 ++++++++++++++++------
 3 files changed, 24 insertions(+), 10 deletions(-)

diff --git a/Documentation/admin-guide/dynamic-debug-howto.rst b/Documentation/admin-guide/dynamic-debug-howto.rst
index fe86a9997ab5..6b934fab695b 100644
--- a/Documentation/admin-guide/dynamic-debug-howto.rst
+++ b/Documentation/admin-guide/dynamic-debug-howto.rst
@@ -85,10 +85,12 @@ by spaces, tabs, or commas.  So these are all equivalent::
   :#> ddcmd '  file   svcsock.c     line  1603 +p  '
   :#> ddcmd file,svcsock.c,line,1603,+p
 
-Command submissions are bounded by a write() system call.
-Multiple commands can be written together, separated by ``;`` or ``\n``::
+Command submissions are bounded by a write() system call.  Multiple
+commands can be written together, separated by ``@``, ``;`` or ``\n``::
 
-  :#> ddcmd "func pnpacpi_get_resources +p; func pnp_assign_mem +p"
+  :#> ddcmd func foo +p @ func bar +p
+  :#> ddcmd func foo +p \; func bar +p
+  :#> ddcmd "func foo +p ; func bar +p"
   :#> ddcmd <<"EOC"
   func pnpacpi_get_resources +p
   func pnp_assign_mem +p
diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 6f700de9738c..93a5a481c8b8 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -631,7 +631,7 @@ static int ddebug_exec_queries(char *query, const char *modname)
 	int i, errs = 0, exitcode = 0, rc, nfound = 0;
 
 	for (i = 0; query; query = split) {
-		split = strpbrk(query, ";\n");
+		split = strpbrk(query, "@;\n");
 		if (split)
 			*split++ = '\0';
 
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index f0b18afa7372..0bb3c3e11df7 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -325,9 +325,19 @@ function FT_basic_queries {
     ddcmd "module params +l"  'kernel/params.c'
     ddcmd "module params -m"  'kernel/params.c'
     ddcmd "module params =_"  'kernel/params.c'
+}
+
+function FT_multi_query {
+    v_echo "${GREEN}# MULTI_QUERY_TESTS ${NC}"
+    if [ $LACK_DD_BUILTIN -eq 1 ]; then
+	echo "SKIP - test requires params, which is a builtin module"
+	return
+    fi
+    ddcmd =_ # zero everything
 
-    # multi-query commands split on ; on a single line
+    # multi-query commands on a single line, split on ;/@ respectively
     ddcmd "module params +mf ; module params func parse_args +sl"  'kernel/params.c'
+    ddcmd "module params -f ; module params func parse_args -l"  'kernel/params.c'
 
     # verify multi-cmd input, newline separated, with embedded comments
     ddcmd =_ # reset before multiline query to capture full transition
@@ -493,7 +503,7 @@ function FT_test_classes {
     verify_control_slice '\[test_dynamic_debug\]'
 
     # 2. Verify state transition and live-printing end-to-end via ddcmd_load!
-    ddcmd_load "class D2_CORE +pmf;class D2_KMS +pls;class D2_ATOMIC +pml" \
+    ddcmd_load "class,D2_CORE,+pmf;class,D2_KMS,+pls;class,D2_ATOMIC,+pml" \
         '\[test_dynamic_debug\]' \
         "/sys/module/test_dynamic_debug/parameters/do_classes" "1"
 
@@ -591,6 +601,7 @@ builtin_tests=(
     FT_path_module_queries
     FT_hyphen_underscore
     FT_comma_terminators
+    FT_multi_query
 )
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
@@ -614,7 +625,7 @@ modular_tests=(
 # ==============================================================================
 function GOLDEN_RECORDS {
     cat << 'EOF' | {
-#K= f3dbd5afb9aa1750f93275b634499e22 FT_grammar_errs.1   
+#K= f3dbd5afb9aa1750f93275b634499e22 FT_grammar_errs.1
 #K= 200c01632c52a63f6d186da1c6460740 FT_grammar_errs.2
 #K= 7d7141900ce6e32f15c99202309c63a4 FT_grammar_errs.3
 #K= 1bb798a5831d0119789d424ef6cb55c4 FT_grammar_errs.4
@@ -660,9 +671,6 @@ function GOLDEN_RECORDS {
 #K= eb3bd35439cc289ef59ee967aad4d540 FT_basic_queries.2
 #K= 00359a9a05d439ec3a850a55e437fcbd FT_basic_queries.3
 #K= b24b1a8081d7514fa593cc28f6fb645b FT_basic_queries.4
-#K= de950a3e60669fdd58d0a8c2867a056d FT_basic_queries.5
-#K= 2ff49f0c4d18ec99bcb1c30840fe8afc FT_basic_queries.6
-#K= 9a1b13c32a15363dcf93913308edeea5 FT_basic_queries.7
 #K= 4b902c159d7f08f91377bf0a353e0051 FT_path_module_queries.1
 #K= bede904b02278e5648bb7a8243be8d98 FT_path_module_queries.2
 #K= 4b902c159d7f08f91377bf0a353e0051 FT_path_module_queries.3
@@ -671,6 +679,10 @@ function GOLDEN_RECORDS {
 #K= 99985cce918eb5108ecb3658249f6bc7 FT_comma_terminators.2
 #K= 68b329da9893e34099c7d8ad5cb9c940 FT_comma_terminators.3
 #K= 85f93d30f4006c99a806639970b92f20 FT_comma_terminators.4
+#K= de950a3e60669fdd58d0a8c2867a056d FT_multi_query.1
+#K= f49de2063a545721cf5e959efc160836 FT_multi_query.2
+#K= 2ff49f0c4d18ec99bcb1c30840fe8afc FT_multi_query.3
+#K= 9a1b13c32a15363dcf93913308edeea5 FT_multi_query.4
 #K= d4923595eea382923aee64aed15c7c35 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
 #K= 40a294034c886787960f4c751b196da9 FT_test_classes.3

-- 
2.55.0

