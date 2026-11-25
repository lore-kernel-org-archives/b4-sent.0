From: Jim Cromie <jim.cromie@gmail.com>
Date: Wed, 25 Nov 2026 11:12:53 -0700
Subject: [PATCH] printk.h: fix overzealous pr_fmt in pr_debug_ratelimited
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-pr-fmt-v1-1-3ff6832f5a50@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQqAIBAF0KsMf52gglFeJVpYjTWLLDQikO4e9
 A7wKgpn4QJPFZlvKXIkeDINYd5CWlnJAk+w2rbGWKfOrOJ+KRMm3XcuxhAYDeHMHOX5o2F83w+
 DeFh9WAAAAA==
X-Change-ID: 20261125-pr-fmt-1ab0985ffaae
To: Petr Mladek <pmladek@suse.com>, John Ogness <john.ogness@linutronix.de>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Jason Baron <jbaron@akamai.com>, Andrew Morton <akpm@linux-foundation.org>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>
Cc: printk@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Philipp Hahn <phahn-oss@avm.de>, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795630377; l=3384;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=uOvWjbH4KvP4BQLaAj5dHyvqdupRAiJBag5rGoYC/rU=;
 b=YR0qTxKl9oZCoqySBkW/7EM5j+ArZb3giU7KjThUd6isgDvVbW20zFhOZRXDD+7HE4sSEjDi0
 dFwdOthk8+sC7F2h0pAhZjmm9WGHdnf+NUdCa/muL/xrs7414BkplXI
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
in pr_debug_ratelimited") fixed the missing prefix by wrapping fmt in
__dynamic_pr_debug() with pr_fmt().  However, it also wrapped fmt in
the metadata macro:

  DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, pr_fmt(fmt));

This causes two problems:

  1. Build failure when pr_fmt() expands to multiple arguments, e.g.:
       #define pr_fmt(fmt) KBUILD_MODNAME ".%s " fmt, __func__
     Passing pr_fmt(fmt) into DEFINE_DYNAMIC_DEBUG_METADATA() expands
     across the comma in DEFINE_DYNAMIC_DEBUG_METADATA_CLS(), supplying
     4 arguments where it takes 3.

  2. Metadata pollution even for single-argument pr_fmt(): baking the
     prefix into .format breaks anchored queries such as:
       echo format "^foo" > /proc/dynamic_debug/control

Drop the pr_fmt() wrapper from DEFINE_DYNAMIC_DEBUG_METADATA() in
pr_debug_ratelimited(), restoring consistency with dynamic_pr_debug,
dev_dbg_ratelimited, and net_dbg_ratelimited.  Update
lib/test_dynamic_debug.c to exercise pr_fmt() with __func__ in
pr_debug_ratelimited().

Reported-by: Philipp Hahn <phahn-oss@avm.de>
Link: https://lore.kernel.org/lkml/a5e3c89fe5f4126873d58dd3472e66c56550ff91.1773779753.git.phahn-oss@avm.de/
Fixes: 515a9adce0f0 ("include/linux/printk.h: include pr_fmt in pr_debug_ratelimited")
Cc: Jason A. Donenfeld <Jason@zx2c4.com>
Cc: Petr Mladek <pmladek@suse.com>
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 include/linux/printk.h   | 2 +-
 lib/test_dynamic_debug.c | 4 ++--
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/include/linux/printk.h b/include/linux/printk.h
index f594c1266bfd..cd29fb467b05 100644
--- a/include/linux/printk.h
+++ b/include/linux/printk.h
@@ -742,7 +742,7 @@ do {									\
 	static DEFINE_RATELIMIT_STATE(_rs,				\
 				      DEFAULT_RATELIMIT_INTERVAL,	\
 				      DEFAULT_RATELIMIT_BURST);		\
-	DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, pr_fmt(fmt));		\
+	DEFINE_DYNAMIC_DEBUG_METADATA(descriptor, fmt);			\
 	if (DYNAMIC_DEBUG_BRANCH(descriptor) &&				\
 	    __ratelimit(&_rs))						\
 		__dynamic_pr_debug(&descriptor, pr_fmt(fmt), ##__VA_ARGS__);	\
diff --git a/lib/test_dynamic_debug.c b/lib/test_dynamic_debug.c
index 77c2a669b6af..cf1e3b5f6f0f 100644
--- a/lib/test_dynamic_debug.c
+++ b/lib/test_dynamic_debug.c
@@ -6,7 +6,7 @@
  *      Jim Cromie	<jim.cromie@gmail.com>
  */
 
-#define pr_fmt(fmt) "test_dd: " fmt
+#define pr_fmt(fmt) "test_dd: %s " fmt, __func__
 
 #include <linux/module.h>
 
@@ -155,7 +155,7 @@ static int __init test_dynamic_debug_init(void)
 
 static void __exit test_dynamic_debug_exit(void)
 {
-	pr_debug("exited\n");
+	pr_debug_ratelimited("exited\n");
 }
 
 module_init(test_dynamic_debug_init);

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261125-pr-fmt-1ab0985ffaae

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

