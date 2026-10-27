From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 27 Oct 2026 14:22:38 -0600
Subject: [PATCH v13 38/39] printk.h: fix overzealous pr_fmt in
 pr_debug_ratelimited
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-dd-cmap-part2-clean-v13-38-9267923be612@gmail.com>
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
 Jason Baron <jbaron@redhat.com>, Jim Cromie <jim.cromie@gmail.com>, 
 Philipp Hahn <phahn-oss@avm.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793132527; l=7602;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=L1ZQsCml84TMv32tD7Co0b90YBd4ZKq5Kk8fMEuL190=;
 b=7MqGWkleUEPFEncJRaFlgtjDnOC+vla19bdvsXx31RA7UxFf42FNui/Y4iMY9mhftVavcxnio
 GnoGlPNeSafCnCM5Jz//ZrfCULLfJKvUTDSdE+u/kb+I7jyE5H7CpvF
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Historically, the CONFIG_DYNAMIC_DEBUG implementation of
pr_debug_ratelimited() passed raw fmt to both metadata and runtime:

  DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, fmt);
  if (unlikely(...) && __ratelimit(&_rs))
     __dynamic_pr_debug(&descriptor, fmt, ##__VA_ARGS__);

While descriptor metadata was clean, emitted dmesg records lacked the
pr_fmt prefix present in the !CONFIG_DYNAMIC_DEBUG fallbacks.

In 2015, commit 515a9adce0f0 ("include/linux/printk.h: include pr_fmt
in pr_debug_ratelimited") fixed the missing prefix by wrapping the fmt
arg in __dynamic_pr_debug() with pr_fmt().  However, it also wrapped
the fmt arg in the METADATA macro:

  DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, pr_fmt(fmt));

This would break if the following were true:

  0. CONFIG_DYNAMIC_DEBUG=y
  1. #define pr_fmt(fmt) KBUILD_MODNAME ".%s " fmt, __func__
  2. a pr_debug_ratelimited() call.

Philipp Hahn recently encountered this, reported the build failure,
added a test case to test_dynamic_debug.c, and proposed adding
variadic arguments (", ...") to DEFINE_DYNAMIC_DEBUG_METADATA_CLS to
slurp the trailing arguments.  This approach had 2 flaws:

  1. the __func__ is not a preprocessor macro
  2. adding the prefix to the .format would break anchored queries:
     echo format "^foo" > /proc/dynamic_debug/control

So modify the DEFINE_DYNAMIC_DEBUG_METADATA() call in
pr_debug_ratelimited, dropping the pr_fmt() wrapper on the fmt arg.
This restores consistency with all the other dyndbg callers:
dynamic_pr_debug, dev_dbg_ratelimited, net_dbg_ratelimited.

Reported-by: Philipp Hahn <phahn-oss@avm.de>
Fixes: 515a9adce0f0 ("include/linux/printk.h: include pr_fmt in pr_debug_ratelimited")
cc: Jason A. Donenfeld <Jason@zx2c4.com>
cc: Petr Mladek <pmladek@suse.com>
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
v13:
. pass raw fmt to DEFINE_DYNAMIC_DEBUG_METADATA in pr_debug_ratelimited(),
  restoring pre-515a9adce0f0 behavior.

. drop vestigial '...' from DEFINE_DYNAMIC_DEBUG_METADATA_CLS as noted by
  Petr Mladek, leaving include/linux/dynamic_debug.h untouched.

. rewrite commit description chronologically and attribute Philipp Hahn
  with Reported-by.

v11:
. update golden record hashes for FT_modprobe_w_param tests after
  comma-token and native classmap attachment fixes.

v10:
. pass raw fmt to DEFINE_DYNAMIC_DEBUG_METADATA in pr_debug_ratelimited().
---
 include/linux/printk.h                             |  2 +-
 lib/test_dynamic_debug.c                           |  4 ++--
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 26 +++++++++++-----------
 3 files changed, 16 insertions(+), 16 deletions(-)

diff --git a/include/linux/printk.h b/include/linux/printk.h
index f594c1266bfd..5d701952e739 100644
--- a/include/linux/printk.h
+++ b/include/linux/printk.h
@@ -742,7 +742,7 @@ do {									\
 	static DEFINE_RATELIMIT_STATE(_rs,				\
 				      DEFAULT_RATELIMIT_INTERVAL,	\
 				      DEFAULT_RATELIMIT_BURST);		\
-	DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, pr_fmt(fmt));		\
+	DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, fmt);		\
 	if (DYNAMIC_DEBUG_BRANCH(descriptor) &&				\
 	    __ratelimit(&_rs))						\
 		__dynamic_pr_debug(&descriptor, pr_fmt(fmt), ##__VA_ARGS__);	\
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 2f19ecb1f295..965f3a6919c0 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -23,7 +23,7 @@
  * the usage clearer.
  */
 #if defined(TEST_DYNAMIC_DEBUG_SUBMOD)
-  #define pr_fmt(fmt) "test_dd_submod: " fmt
+  #define pr_fmt(fmt) "test_dd_submod: %s " fmt, __func__
 #else
   #define pr_fmt(fmt) "test_dd: " fmt
 #endif
@@ -326,7 +326,7 @@ static int __init test_dynamic_debug_init(void)
 
 static void __exit test_dynamic_debug_exit(void)
 {
-	pr_debug("exited\n");
+	pr_debug_ratelimited("exited\n");
 }
 
 module_init(test_dynamic_debug_init);
diff --git a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
index fd9a3dff4099..2bdfdb3876ee 100755
--- a/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
+++ b/tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
@@ -724,40 +724,40 @@ function GOLDEN_RECORDS {
 #K= e11c22649735cedb6c30321378100e11 FT_classmap_inheritance.2
 #K= 5d0f3701517aa3a461c8887c332bdb42 FT_classmap_inheritance.3
 #K= d39188ded831453d90d77390546b314d FT_classmap_inheritance.4
-#K= f43e0aff8a4b38435b73d90ed8100d1b FT_classmap_inheritance.5
+#K= 62b6803edf43519186d6185bebf34352 FT_classmap_inheritance.5
 #K= d2e8b8c5a5b4e7b9bbe1a29460a3c07d FT_modprobe_w_param.1
 #K= d2e8b8c5a5b4e7b9bbe1a29460a3c07d FT_modprobe_w_param.2
-#K= 11032ef17569bd151c3806527a2428be FT_modprobe_w_param.3
+#K= 20d8a1fac0330f1b5cc582ce93792d58 FT_modprobe_w_param.3
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.4
-#K= 942e62ca24809cad666c5725aeb14376 FT_modprobe_w_param.5
+#K= 3c19dd83b330a9d59901281aaa3bacf8 FT_modprobe_w_param.5
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.6
-#K= fe1aadca4b2b4165d8d5c98e973f9e4b FT_modprobe_w_param.7
+#K= 86b7a18d7a692187aa0b7cc0b6886e77 FT_modprobe_w_param.7
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.8
 #K= 535ab526b24a7214de41d92e94bbd52c FT_modprobe_w_param.9
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.10
-#K= 7c02282dcfb73eb5ffb9629ce63360e5 FT_modprobe_w_param.11
+#K= 64f91218760ca86d28a4b9b2d23849fb FT_modprobe_w_param.11
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.12
-#K= b0942decc84dae237019bc2877ff02e7 FT_modprobe_w_param.13
+#K= 03bad8f76b3587c2e8bdb9df43110a5e FT_modprobe_w_param.13
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.14
-#K= efe8e3b8080c3310708b7505d60f7703 FT_modprobe_w_param.15
+#K= 04b59fe2db45bc6bb314e9102b92dd64 FT_modprobe_w_param.15
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.16
 #K= d682c98ced7d31f1555ab474a9ebe253 FT_modprobe_w_param.17
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.18
 #K= c468e49e8ce1f1aa25a3c6684f221fe5 FT_modprobe_w_param.19
 #K= c468e49e8ce1f1aa25a3c6684f221fe5 FT_modprobe_w_param.20
-#K= ef2408a036206c895d95061521f67906 FT_modprobe_w_param.21
+#K= 2b31c44bc2eb5b5d666dc1887c38b8dd FT_modprobe_w_param.21
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.22
-#K= 92c0174d5de412de82e3d5837b0690d0 FT_modprobe_w_param.23
+#K= 3bba1f526e669807407d9be380117564 FT_modprobe_w_param.23
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.24
-#K= a563a79aeffbf3d8cf2e37ab93898ae9 FT_modprobe_w_param.25
+#K= 1dc9fbf8e7ce91929308a441e3707915 FT_modprobe_w_param.25
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.26
 #K= 8d2f4db3b7885064a56594e1d81deb26 FT_modprobe_w_param.27
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.28
-#K= 05e8884875609af295ec71a7acf33c60 FT_modprobe_w_param.29
+#K= 0658c273db527fb4fcaadbb142bf0565 FT_modprobe_w_param.29
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.30
-#K= c70f769b4c9cc905d23d6b3e5ac432c8 FT_modprobe_w_param.31
+#K= 20cac1fd02b4615b337e84aa87892afc FT_modprobe_w_param.31
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.32
-#K= 72bf5368385d19e7843cf268d1bac7f9 FT_modprobe_w_param.33
+#K= 8eb7924c66978d844e97bee9f91b981e FT_modprobe_w_param.33
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.34
 #K= 28ace93a95da7aaea5b9b54a8656a2cf FT_modprobe_w_param.35
 #K= 0239d8c0808eef396782362613f675b0 FT_modprobe_w_param.36

-- 
2.56.0

