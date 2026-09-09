From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 08 Sep 2026 18:55:28 -0600
Subject: [PATCH v9 32/39] dyndbg: split multi-query strings with @
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-dd-cmap-part2-clean-v9-32-3a3f621f4a10@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788915300; l=5944;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=Fvxr8IZ62taccCweR/yvtqCtI2HD/eMIq8/D9S4E7O0=;
 b=l5aQXGtyUAv1zYe86bbfa81BpDb2qyi3d46W9RapJl0uDMHx5juDh17miRfyBJxPBPvYjj6Q1
 GWaSuR2+2j1DXC/aM768RIBxnGKxrDHVeEaESyqc/5BkXtmV8WurxrN
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
v9:
. update FT_multi_query command in dyndbg_selftest.sh to actively test @ delimiter.
v5: avoid +t flag in content tests - pid is not predictable.
    remove Reviewed-by: <louis.chauvet@bootlin.com> - too many changes

v2:

replace '%' with '@' as multi-query splitter, as it is:
 - not a sshell special cahr
 - allows matching on format strings with format specifiers
---
 Documentation/admin-guide/dynamic-debug-howto.rst  |  8 +++++---
 lib/dynamic_debug.c                                |  2 +-
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 23 +++++++++++++++++-----
 3 files changed, 24 insertions(+), 9 deletions(-)

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
index d28858acdc8f..e6f5a524d63b 100644
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
index 70da3662a201..f10ef7522426 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -324,9 +324,20 @@ function FT_basic_queries {
     ddcmd "file $f +l"  "$f"
     ddcmd "file $f -m"  "$f"
     ddcmd "file $f =_"  "$f"
+}
+
+function FT_multi_query {
+    v_echo "${GREEN}# MULTI_QUERY_TESTS ${NC}"
+    if [ $LACK_DD_BUILTIN -eq 1 ]; then
+	echo "SKIP - test requires dynamic_debug built into kernel"
+	return
+    fi
+    local f='kernel/params.c'
+    ddcmd =_ # zero everything
 
-    # multi-query commands split on ; on a single line
+    # multi-query commands on a single line, split on ;/@ respectively
     ddcmd "file $f +mf ; file $f func parse_args +sl" "$f"
+    ddcmd "file $f -f @ file $f func parse_args -l"   "$f"
 
     # verify multi-cmd input, newline separated, with embedded comments
     ddcmd =_ # reset before multiline query to capture full transition
@@ -503,7 +514,7 @@ function FT_test_classes {
     verify_control_slice '\[test_dynamic_debug\]'
 
     # 2. Verify state transition and live-printing end-to-end via ddcmd_load!
-    ddcmd_load "class D2_CORE +pmf;class D2_KMS +pls;class D2_ATOMIC +pml" \
+    ddcmd_load "class,D2_CORE,+pmf;class,D2_KMS,+pls;class,D2_ATOMIC,+pml" \
         '\[test_dynamic_debug\]' \
         "/sys/module/test_dynamic_debug/parameters/do_classes" "1"
 
@@ -601,6 +612,7 @@ builtin_tests=(
     FT_path_module_queries
     FT_hyphen_underscore
     FT_comma_terminators
+    FT_multi_query
 )
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
@@ -670,14 +682,15 @@ function GOLDEN_RECORDS {
 #K= d8eb8f226860aa558fb8a98097f05be9 FT_basic_queries.2
 #K= 6a86bb9209a3a0492bc6c2d29f4d5e52 FT_basic_queries.3
 #K= 90804574a5336971465f92d6cc3aa7fb FT_basic_queries.4
-#K= f2b4f24fece9c55f5a5d28323c2019f8 FT_basic_queries.5
-#K= 8c2dd1164fbcefb721345ce62a864a37 FT_basic_queries.6
-#K= 4542e1e5e7eadcbe8f90a9c934635618 FT_basic_queries.7
 #K= 78ad5b168d9db27931dfe7dac93143bf FT_comma_terminators.1
 #K= 4a8d6e0468d14659030ef523c6e5a184 FT_comma_terminators.2
 #K= 3c445fb23d701041e920a2a6d2b022c7 FT_comma_terminators.3
 #K= 68b329da9893e34099c7d8ad5cb9c940 FT_comma_terminators.4
 #K= c745b8f58c0557edca58d5a224a09190 FT_comma_terminators.5
+#K= f2b4f24fece9c55f5a5d28323c2019f8 FT_multi_query.1
+#K= cce9c41c3ac297e910c3ee3b10852cb3 FT_multi_query.2
+#K= 8c2dd1164fbcefb721345ce62a864a37 FT_multi_query.3
+#K= 4542e1e5e7eadcbe8f90a9c934635618 FT_multi_query.4
 #K= 8146f6f983c3a76783c89b78b892ed48 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
 #K= 20d4545f9753e677e72e3adf52527fd3 FT_test_classes.3

-- 
2.55.0

