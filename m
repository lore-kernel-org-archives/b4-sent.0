From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:51:55 +0000
Subject: [PATCH BlueZ 01/10] build: remove unused AM_CONDITIONAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-1-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=571;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=hH4p4F+DSfBor5eMwxN/Bc+wtZkc5eQ4tXjcGVPVcjs=;
 b=E5JrIt6fd61wpw7r69bcAqOtkrQCPq7kOdXJNP6pFSTJT0vUGQskOTDUYX7SOkqIiUFSSEWyS
 1yqT6gixO4VBx5Y0iBeqBKCzz5yJlcpPRuAxzAGxMgBmV+HDwq70Chl
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 configure.ac | 1 -
 1 file changed, 1 deletion(-)

diff --git a/configure.ac b/configure.ac
index 3e10ec970..307a2f30c 100644
--- a/configure.ac
+++ b/configure.ac
@@ -238,7 +238,6 @@ if (test "${enable_tools}" != "no" && test "${enable_udev}" != "no"); then
 		AC_DEFINE(HAVE_UDEV_HWDB_NEW, 1,
 			[Define to 1 if you have the udev_hwdb_new() function.]))
 fi
-AM_CONDITIONAL(UDEV, test "${enable_udev}" != "no")
 
 AC_ARG_WITH([udevdir], AS_HELP_STRING([--with-udevdir=DIR],
 			[path to udev directory]), [path_udevdir=${withval}])

-- 
2.43.0

