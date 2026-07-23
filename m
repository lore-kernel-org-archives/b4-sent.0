From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:57 +0200
Subject: [PATCH 19/19] drivers: integrate USB/AHCI changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-rn102-rn104-series-v1-19-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=699;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=QRd+hAbkI8LHuSICgMI0gxZ78VkZmA1gngAn6p04eys=;
 b=7Tx6ZXXurvBGJSddVsxNc7cVWHyr0UF/ipxVxBUUY7jHjjrPV6eGLtHIElezOar5mSOutpYmW
 Zq9bWBgziJYD1LLvCIQ7sMQCOb22SpK0jUkQArWXgy6gWFnT4pBWKdI
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 drivers/Kconfig  | 1 +
 drivers/Makefile | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/Kconfig b/drivers/Kconfig
index 32910addcd..b1ba73887a 100644
--- a/drivers/Kconfig
+++ b/drivers/Kconfig
@@ -50,5 +50,6 @@ source "drivers/power/Kconfig"
 source "drivers/virtio/Kconfig"
 source "drivers/mailbox/Kconfig"
 source "drivers/tee/Kconfig"
+source "drivers/fan/Kconfig"
 
 endmenu
diff --git a/drivers/Makefile b/drivers/Makefile
index db491dad83..4d6071fdc7 100644
--- a/drivers/Makefile
+++ b/drivers/Makefile
@@ -51,3 +51,4 @@ obj-$(CONFIG_SOUND) += sound/
 obj-y	+= virtio/
 obj-y	+= mailbox/
 obj-y	+= tee/
+obj-$(CONFIG_FAN) += fan/

-- 
2.47.3

