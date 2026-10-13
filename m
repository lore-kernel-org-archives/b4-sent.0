From: Jim Cromie <jim.cromie@gmail.com>
Date: Mon, 12 Oct 2026 20:37:11 -0600
Subject: [PATCH v12 40/40] drm: Mark __drm_debug as __read_mostly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-dd-cmap-part2-clean-v12-40-3c8cc5725def@gmail.com>
References: <20261012-dd-cmap-part2-clean-v12-0-3c8cc5725def@gmail.com>
In-Reply-To: <20261012-dd-cmap-part2-clean-v12-0-3c8cc5725def@gmail.com>
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
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791858995; l=1613;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=t+nRtOhFy0vKw6kQ27p3cuieeS36YDxQ0XXNRXZWkUg=;
 b=QrLzcgGksBoji2Iymzq1cx94bkvtbW5tQICrBKVn2XjVZjGut++5YHK+99bqGVjlRN9IQjC6Q
 nvRvS9pIqwRD72Gc7Kqlzxkw6mukXkX4OltnxJyZ46h53vbTNE86wi1
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Dyndbg classmaps converts ~5,700 DRM debug callsites into static keys,
yielding 0-off-cost NOOPs that never touch memory. However, several
call patterns do not fit the direct drm_dbg() macro model; notably
open-coded drm_debug_enabled() guard blocks, drm_dbg_printer(), and
ratelimited helpers.

In upstream, the linker places __drm_debug in the same 64-byte
cacheline as hot writers: drm_lease_idr_object, drm_global_mutex.
Writes to those locks issue Request-For-Ownership (RFO) invalidations
across cores, leaving those residual bit-tests to suffer 7
false-sharing hazards and continuous cache bouncing during active
rendering (e.g. 12 concurrent vkcube clients). In contrast, writes to
__drm_debug occur almost never, only when userspace updates
"/sys/module/drm/parameters/debug".

So mark __drm_debug with __read_mostly.  This isolates it from the 7
writable symbols it currently shares a cache-line with, eliminating
those invalidations.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/drm_print.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/drm_print.c b/drivers/gpu/drm/drm_print.c
index 794417c62097..1ec139c8f06f 100644
--- a/drivers/gpu/drm/drm_print.c
+++ b/drivers/gpu/drm/drm_print.c
@@ -40,7 +40,7 @@
  * __drm_debug: Enable debug output.
  * Bitmask of DRM_UT_x. See include/drm/drm_print.h for details.
  */
-u32 __drm_debug;
+u32 __drm_debug __read_mostly;
 EXPORT_SYMBOL(__drm_debug);
 
 MODULE_PARM_DESC(debug, "Enable debug output, where each bit enables a debug category.\n"

-- 
2.56.0

