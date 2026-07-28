From: Luca Lauro <famlauro93l@gmail.com>
Date: Tue, 28 Jul 2026 19:43:19 +0200
Subject: [PATCH v2 07/10] commands: integrate fan command into Kconfig and
 Makefile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-rn102-rn104-series-v2-7-ae31f55b7bc8@gmail.com>
References: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
In-Reply-To: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785260594; l=1033;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=GyBCPKHMAyyNfO60SgS3yJy1KUzJgl7i8GWidDCXKR4=;
 b=mNeRQ+E1v8Hk+PDCF28Obqe42ijR4MyeJu8fXU3yw/KKHprU4MCB1txsYNKalA5w2juPHigtw
 4GMy6Or2glBAVQVS38CMb3S5g4A6w5x2nHnSph7pFUwqCWIb71b3xrv
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 commands/Kconfig  | 7 +++++++
 commands/Makefile | 2 ++
 2 files changed, 9 insertions(+)

diff --git a/commands/Kconfig b/commands/Kconfig
index 297c89b4b5..d661f0eaab 100644
--- a/commands/Kconfig
+++ b/commands/Kconfig
@@ -2337,6 +2337,13 @@ config CMD_RKSECURE
 	  The rksecure command allows to retrieve information about and enable
 	  secure boot for Rockchip rk3588 SoCs.
 
+config CMD_FAN
+	bool
+	depends on FAN
+	prompt "fan command"
+	help
+	  Control and monitor target fans.
+
 # end Hardware manipulation commands
 endmenu
 
diff --git a/commands/Makefile b/commands/Makefile
index 2563efb12f..227c40b3f5 100644
--- a/commands/Makefile
+++ b/commands/Makefile
@@ -173,4 +173,6 @@ obj-$(CONFIG_CMD_DMSETUP)	+= dmsetup.o
 obj-$(CONFIG_CMD_VERITYSETUP)	+= veritysetup.o
 obj-$(CONFIG_CMD_SCONFIG)	+= sconfig.o
 obj-$(CONFIG_CMD_RKSECURE)	+= rksecure.o
+obj-$(CONFIG_CMD_FAN)		+= fan.o
+
 UBSAN_SANITIZE_ubsan.o := y

-- 
2.47.3

