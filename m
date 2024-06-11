From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:09 +0100
Subject: [PATCH kmod 09/20] man: couple of grammar/language fixes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-9-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=1047;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=i/S1VKUvrWzewIKxOnrx/yc1sFJXe+b7jnwP8i5BgJg=;
 b=hYjAjjydFSVKF9alkxRx4+pYhTYi7Wg9rj7wT3CgEh6ygQQoUTRfH406ViqcSDzdKuAQBzyNv
 avLOCPtY/a2ANeTqO0wV3ZuBse/XK9258dxdv5/m+4X29o3tTmdLetr
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/modprobe.8.scd | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/man/modprobe.8.scd b/man/modprobe.8.scd
index 9594798..b47908b 100644
--- a/man/modprobe.8.scd
+++ b/man/modprobe.8.scd
@@ -101,7 +101,7 @@ database.
 	Naturally, this check is there for your protection, so using this option
 	is dangerous unless you know what you're doing.
 
-	This applies any modules inserted: both the module (or alias) on the
+	This applies to any modules inserted: both the module (or alias) on the
 	command line and any modules on which it depends.
 
 *-f*, *--force*
@@ -112,7 +112,7 @@ database.
 	know what you are doing.
 
 	This applies to any modules inserted: both the module (or alias) on the
-	command line and any modules it on which it depends.
+	command line and any modules on which it depends.
 
 *-i*, *--ignore-install*, *--ignore-remove*
 	This option causes *modprobe* to ignore *install* and *remove* commands

-- 
2.45.0

