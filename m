From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 27 Oct 2026 14:22:30 -0600
Subject: [PATCH v13 30/39] dyndbg: split multi-query strings with @
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-dd-cmap-part2-clean-v13-30-9267923be612@gmail.com>
References: <20261027-dd-cmap-part2-clean-v13-0-9267923be612@gmail.com>
In-Reply-To: <20261027-dd-cmap-part2-clean-v13-0-9267923be612@gmail.com>
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
 Len Brown <lenb@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Petr Mladek <pmladek@suse.com>, Steven Rostedt <rostedt@goodmis.org>, 
 John Ogness <john.ogness@linutronix.de>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jason Baron <jbaron@redhat.com>, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793132527; l=9157;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=4wvJCpg9VIj0BIjxtSPpyZutQkl9vZtDY4fLBgdQYWY=;
 b=/6Buugx4Cwrjo9Qf1b/jCM4nt8rJy8Ax2wBC/lz3d75buayjwS1oQTSkKVjhw3MUKSnwI2UUP
 3Cvk/IUXfmDDsQoSoPjbLZ3LfE+63NJSnWLBA0G79Y3sLUf5/4DTkHm
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
v10:
. replace strpbrk() with quote-aware ddebug_find_delimiter() to ignore '@' inside quotes.

v9:
. update FT_multi_query command in dyndbg_selftest.sh to actively test @ delimiter.
v5: avoid +t flag in content tests - pid is not predictable.
    remove Reviewed-by: <louis.chauvet@bootlin.com> - too many changes

v2:

replace '%' with '@' as multi-query splitter, as it is:
 - not a sshell special cahr
 - allows matching on format strings with format specifiers
---
 Documentation/admin-guide/dynamic-debug-howto.rst  |  8 +++--
 lib/dynamic_debug.c                                | 26 ++++++++++++++++-
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 34 +++++++++++++++-------
 3 files changed, 53 insertions(+), 15 deletions(-)

diff --git a/Documentation/admin-guide/dynamic-debug-howto.rst b/Documentation/admin-guide/dynamic-debug-howto.rst
index b9fbb2a12955..a8962ab22aaf 100644
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
index 5d99c3aef5a1..11f7350f3590 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -622,6 +622,30 @@ static int ddebug_exec_query(char *query_string, const char *modname)
 	return nfound;
 }
 
+/*
+ * Split multi-query string on delimiters (@, ;, \n), ignoring delimiters
+ * that appear inside single or double quoted strings.
+ */
+static char *ddebug_find_delimiter(char *str, const char *delims)
+{
+	bool in_quote = false;
+	char quote_char = 0;
+
+	for (; *str; str++) {
+		if (*str == '"' || *str == '\'') {
+			if (!in_quote) {
+				in_quote = true;
+				quote_char = *str;
+			} else if (*str == quote_char) {
+				in_quote = false;
+			}
+		} else if (!in_quote && strchr(delims, *str)) {
+			return str;
+		}
+	}
+	return NULL;
+}
+
 /* handle multiple queries in query string, continue on error, return
    last error or number of matching callsites.  Module name is either
    in the modname arg (for boot args) or perhaps in query string.
@@ -632,7 +656,7 @@ static int ddebug_exec_queries(char *query, const char *modname)
 	int i, errs = 0, exitcode = 0, rc, nfound = 0;
 
 	for (i = 0; query; query = split) {
-		split = strpbrk(query, ";\n");
+		split = ddebug_find_delimiter(query, "@;\n");
 		if (split)
 			*split++ = '\0';
 
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index f4078ad112f0..1811a9982f6a 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -131,7 +131,6 @@ function ddcmd_load () {
     local val="$4"
 
     # 1. Setup the control filters (using positional ddcmd range-check)
-    echo  "$query" "$range"
     ddcmd "$query" "$range"
 
     # 2. Execute the workload and capture syslog prints
@@ -325,9 +324,20 @@ function FT_basic_queries {
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
@@ -373,7 +383,7 @@ function FT_test_classes {
     verify_control_slice '\[test_dynamic_debug\]'
 
     # 2. Verify state transition and live-printing end-to-end via ddcmd_load!
-    ddcmd_load "class D2_CORE +pmf;class D2_KMS +pls;class D2_ATOMIC +pml" \
+    ddcmd_load "class,D2_CORE,+pmf;class,D2_KMS,+pls;class,D2_ATOMIC,+pml" \
         '\[test_dynamic_debug\]' \
         "/sys/module/test_dynamic_debug/parameters/do_classes" "1"
 
@@ -467,6 +477,7 @@ builtin_tests=(
     FT_grammar_errs
     FT_basic_queries
     FT_comma_terminators
+    FT_multi_query
 )
 
 # Modular Feature Tests (Require CONFIG_MODULES=y and test_dynamic_debug*.ko available)
@@ -489,8 +500,8 @@ modular_tests=(
 #
 # ==============================================================================
 function GOLDEN_RECORDS {
-    cat << 'EOF' | {
-#K= 26fd1565f209b383d9f2fbf0b54cd5fc FT_grammar_errs.1
+    cat << 'EO_DYNDBG_GOLDEN_REFS' | {
+#K= 95b249c7ec2cbd5a436f96060b2bee37 FT_grammar_errs.1
 #K= 200c01632c52a63f6d186da1c6460740 FT_grammar_errs.2
 #K= 7d7141900ce6e32f15c99202309c63a4 FT_grammar_errs.3
 #K= 1bb798a5831d0119789d424ef6cb55c4 FT_grammar_errs.4
@@ -510,7 +521,7 @@ function GOLDEN_RECORDS {
 #K= cb8288d607b0c5282125852f3ab05107 FT_grammar_errs.18
 #K= b371c6ba52503d037dbc43da788af8be FT_grammar_errs.19
 #K= 98e2bd3e4f3da58536496a38ec3e6238 FT_grammar_errs.20
-#K= 02b210b2646aceb68f3d6d2876a3d57a FT_grammar_errs.21
+#K= c4e8b7261811e9fdf0c80fa9e374a29e FT_grammar_errs.21
 #K= 51030cd01ed601a68dd48356902954b1 FT_grammar_errs.22
 #K= af8818de076407d4e7f4e384ba110ac5 FT_grammar_errs.23
 #K= 023ba04ffced833b4776fb4fcaae7755 FT_grammar_errs.24
@@ -530,7 +541,7 @@ function GOLDEN_RECORDS {
 #K= 130bf64b92a5e34d1c4cce98899084e1 FT_grammar_errs.38
 #K= 9681a05658f1a50e3434aa991b5ce992 FT_grammar_errs.39
 #K= 38506317363a188fbb7a417ff50457a9 FT_grammar_errs.40
-#K= 02b210b2646aceb68f3d6d2876a3d57a FT_grammar_errs.41
+#K= c4e8b7261811e9fdf0c80fa9e374a29e FT_grammar_errs.41
 #K= 8c08a8b5cacbf885d022360ed856e7a1 FT_grammar_errs.42
 #K= f0f4d894a49bd2c1856cf4f013f83e54 FT_grammar_errs.43
 #K= 25b92d52cb299fa8d84c5584e490bd97 FT_grammar_errs.44
@@ -554,14 +565,15 @@ function GOLDEN_RECORDS {
 #K= db17180b59444e5e34a8fc20c40e4530 FT_basic_queries.2
 #K= f7bd56bd407ff255ef2e3b5fb093ae6a FT_basic_queries.3
 #K= 4ce44468b3b5f80ae42ade1f261b952f FT_basic_queries.4
-#K= 02e4fd94602e108cb89bfc70d47a5dad FT_basic_queries.5
-#K= f03a7ca7316e8db4c0e16523dc41e75d FT_basic_queries.6
-#K= c518a50ba30ba8099d0dc874a27ecf16 FT_basic_queries.7
 #K= c8bbbac639f244ed9088208ebb7d83a6 FT_comma_terminators.1
 #K= bed6350f058f600910837dae83a12f56 FT_comma_terminators.2
 #K= 6e8599556a312200fb6d484565b6c52f FT_comma_terminators.3
 #K= 68b329da9893e34099c7d8ad5cb9c940 FT_comma_terminators.4
 #K= adc1ef04304c861c87fe294a8ba4e402 FT_comma_terminators.5
+#K= 02e4fd94602e108cb89bfc70d47a5dad FT_multi_query.1
+#K= c0fc482bbf18b9d5ffd6743b18bc34f7 FT_multi_query.2
+#K= f03a7ca7316e8db4c0e16523dc41e75d FT_multi_query.3
+#K= c518a50ba30ba8099d0dc874a27ecf16 FT_multi_query.4
 #K= 91838b4012c50a1dc1d9e210ba8d68f8 FT_test_classes.1
 #K= a15ec4843acd721fbdfddc0b512c8032 FT_test_classes.2
 #K= 2cee6842c9cdee5cb3bf50b2e3914813 FT_test_classes.3
@@ -606,7 +618,7 @@ function GOLDEN_RECORDS {
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.34
 #K= 4819f715ba485c493afb455542f7ab8c FT_modprobe_w_param.35
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.36
-EOF
+EO_DYNDBG_GOLDEN_REFS
         # Read the K-recs and skip those for tests that can't run
         while read -r line; do
             # Filter built-in if needed

-- 
2.56.0

