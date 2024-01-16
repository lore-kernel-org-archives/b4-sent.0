From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:51:57 +0000
Subject: [PATCH BlueZ 03/10] build: require libudev 196, circa 2012
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-3-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=1719;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=nLN3WkSkihgDvnnZcl9Nn8E9C8mCNtO7PTdfVC6NKvk=;
 b=YhnaU6pHuWBl7qCgjNDL+pYfKSio1h1hEIve69poO8V3sYNxhxfgxRQ3HX6WzopevuWXHjhyJ
 4X7OmlNRc1+AackBXGIVs/XYXPAK3YNz4b07JGFjBeN+dpJzbPQ6uLh
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

libudev 196 (systemd really) was released back in 2012, which introduces
the hwdb API. Bump the requirement, since even long retired
distributions like Debian oldold stable (aka Buster) include newer
versions.
---
 configure.ac   | 6 ++----
 monitor/hwdb.c | 2 +-
 src/oui.c      | 2 +-
 3 files changed, 4 insertions(+), 6 deletions(-)

diff --git a/configure.ac b/configure.ac
index 7cbfa8846..cab5da581 100644
--- a/configure.ac
+++ b/configure.ac
@@ -223,10 +223,8 @@ AM_CONDITIONAL(MONITOR, test "${enable_monitor}" != "no")
 AC_ARG_ENABLE(udev, AS_HELP_STRING([--disable-udev],
 		[disable udev device support]), [enable_udev=${enableval}])
 if (test "${enable_tools}" != "no" && test "${enable_udev}" != "no"); then
-	PKG_CHECK_MODULES(UDEV, libudev >= 172)
-	AC_CHECK_LIB(udev, udev_hwdb_new,
-		AC_DEFINE(HAVE_UDEV_HWDB_NEW, 1,
-			[Define to 1 if you have the udev_hwdb_new() function.]))
+	PKG_CHECK_MODULES(UDEV, libudev >= 196)
+	AC_DEFINE(HAVE_UDEV, 1, [Define to 1 if udev is required])
 fi
 
 AC_ARG_WITH([udevdir], AS_HELP_STRING([--with-udevdir=DIR],
diff --git a/monitor/hwdb.c b/monitor/hwdb.c
index 22de9edfb..6c0d052bb 100644
--- a/monitor/hwdb.c
+++ b/monitor/hwdb.c
@@ -19,7 +19,7 @@
 
 #include "hwdb.h"
 
-#ifdef HAVE_UDEV_HWDB_NEW
+#ifdef HAVE_UDEV
 #include <libudev.h>
 
 bool hwdb_get_vendor_model(const char *modalias, char **vendor, char **model)
diff --git a/src/oui.c b/src/oui.c
index c434f416f..7b3040fb0 100644
--- a/src/oui.c
+++ b/src/oui.c
@@ -16,7 +16,7 @@
 #include "lib/bluetooth.h"
 #include "oui.h"
 
-#ifdef HAVE_UDEV_HWDB_NEW
+#ifdef HAVE_UDEV
 #include <libudev.h>
 
 char *batocomp(const bdaddr_t *ba)

-- 
2.43.0

