From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 27 Oct 2026 14:22:34 -0600
Subject: [PATCH v13 34/39] dyndbg: fix attempt to modify an RO string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-dd-cmap-part2-clean-v13-34-9267923be612@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793132527; l=1338;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=ixTGO+9E4e6ny5HSFD6LFvYUhfjCd8aiyHGBDPZdcJU=;
 b=Gzv6kwnWWAGy2/gJiCLZJaE1VmrRcDtxSRjdmhkJYU6m+NltR1sVTraWZnaT3iVxIjuSNUwFW
 lldZIcBpXjNBGfJfssoWxkmm2UNFR42Tg0kyYYIXGVioHTmr0N0V82b
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ddebug_dyndbg_param_cb() passes an RO flags string "+p" to
ddebug_exec_queries() when no explicit param value is given, but
callee may attempt to modify it.  Fix by adding a local mutable var,
init'd with that value, and passing it instead.

Fixes: b48420c1d301 ("dynamic_debug: make dynamic-debug work for module initialization")
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 lib/dynamic_debug.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/lib/dynamic_debug.c b/lib/dynamic_debug.c
index 5c87e92bbcdb..efc7a741008e 100644
--- a/lib/dynamic_debug.c
+++ b/lib/dynamic_debug.c
@@ -1637,8 +1637,9 @@ static int ddebug_add_module(struct _ddebug_info *di)
 
 /* helper for ddebug_dyndbg_(boot|module)_param_cb */
 static int ddebug_dyndbg_param_cb(char *param, char *val,
-				const char *modname, int on_err)
+				  const char *modname, int on_err)
 {
+	char dflt_flags[] = "+p";
 	char *sep;
 
 	sep = strchr(param, '.');
@@ -1651,7 +1652,7 @@ static int ddebug_dyndbg_param_cb(char *param, char *val,
 	if (strcmp(param, "dyndbg"))
 		return on_err; /* determined by caller */
 
-	ddebug_exec_queries((val ? val : "+p"), modname);
+	ddebug_exec_queries((val ? val : dflt_flags), modname);
 
 	return 0; /* query failure shouldn't stop module load */
 }

-- 
2.56.0

