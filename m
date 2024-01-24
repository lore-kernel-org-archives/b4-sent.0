From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 16:08:00 +0000
Subject: [PATCH BlueZ v2 4/8] bluetoothd: convert external sixaxis plugin
 to builtin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-rm-ext-plugins-v2-4-5244906f05ff@gmail.com>
References: <20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com>
In-Reply-To: <20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706112482; l=1169;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=rf/DV6bb4eocv72jDKDqDG7KvOMIubc6ZBWpK2UcaNg=;
 b=Py3+JdBHRaqUbOQT2T1Ril4VYqW538IlZ7V5wm902vr4KnNz0UAsfVnImc5t860VfUbGcLQ8o
 8MWuUwsJrUVAko0r9mrSAQlsd1VTLKQxFR5pNhLZGwaiGe1D+CJoT8K
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

Convert the only known external plugin to built-in. It's a tiny 20K
binary that distros ship a separate package for.

Make it a builtin, which allows distros to drop the separate package, it
also enables us to compile out support for external modules - both in
terms of extra code and hide the internal bluetoothd API.

This means that libudev.so is pulled in, which is fine since its ABI has
been stable for over a decade.
---
 Makefile.plugins | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/Makefile.plugins b/Makefile.plugins
index 5880ed0df..7cf66fd59 100644
--- a/Makefile.plugins
+++ b/Makefile.plugins
@@ -110,11 +110,9 @@ builtin_modules += battery
 builtin_sources += profiles/battery/battery.c
 
 if SIXAXIS
-plugin_LTLIBRARIES += plugins/sixaxis.la
-plugins_sixaxis_la_SOURCES = plugins/sixaxis.c
-plugins_sixaxis_la_LDFLAGS = $(AM_LDFLAGS) -module -avoid-version
-plugins_sixaxis_la_LIBADD = $(UDEV_LIBS)
-plugins_sixaxis_la_CFLAGS = $(AM_CFLAGS) -fvisibility=hidden
+builtin_modules += sixaxis
+builtin_sources += plugins/sixaxis.c
+builtin_ldadd += $(UDEV_LIBS)
 endif
 
 if BAP

-- 
2.43.0

