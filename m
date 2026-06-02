From: Sam Day <me@samcday.com>
Date: Tue, 02 Jun 2026 18:45:46 +1000
Subject: [PATCH 1/2] cmd: fastboot: Add keyed abort option
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-fastboot-abort-keyed-v1-1-414aac5a06b8@samcday.com>
References: <20260602-fastboot-abort-keyed-v1-0-414aac5a06b8@samcday.com>
In-Reply-To: <20260602-fastboot-abort-keyed-v1-0-414aac5a06b8@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 "Kory Maincent (TI.com)" <kory.maincent@bootlin.com>, 
 Mikhail Kshevetskiy <mikhail.kshevetskiy@iopsys.eu>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, Heiko Schocher <hs@nabladev.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780389946; l=1315;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=nn6vYNeRe+W+GBTC2Gi1LZ4P9G9q9e0DhQ0LMyuLZOo=;
 b=CLBCsPkQJ6dwkd3ubzniPqrNffa5zYvtzrtnsS+ZynF4CRbA6F3LzEaN5w8fggupmx70GYmDR
 QlcCYHld08PCasvNslU89Eglw1McG/OFor0dcXuw4vOHTsmPoq0cFAk
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Works the same as CONFIG_CMD_UMS_ABORT_KEYED does: any keypress will
abort fastboot mode (rather than only ctrl-c).

Signed-off-by: Sam Day <me@samcday.com>
---
 cmd/Kconfig    | 6 ++++++
 cmd/fastboot.c | 9 ++++++++-
 2 files changed, 14 insertions(+), 1 deletion(-)

diff --git a/cmd/Kconfig b/cmd/Kconfig
index c71c6824a19..439409d6f2c 100644
--- a/cmd/Kconfig
+++ b/cmd/Kconfig
@@ -1208,6 +1208,12 @@ config CMD_FASTBOOT
 
 	  See doc/android/fastboot.rst for more information.
 
+config CMD_FASTBOOT_ABORT_KEYED
+	bool "fastboot abort with any key"
+	depends on CMD_FASTBOOT && USB_FUNCTION_FASTBOOT
+	help
+	  Allow interruption of USB fastboot mode with any key pressed.
+
 config CMD_FLASH
 	bool "flinfo, erase, protect"
 	default y
diff --git a/cmd/fastboot.c b/cmd/fastboot.c
index e71f873527b..f3929f88dfa 100644
--- a/cmd/fastboot.c
+++ b/cmd/fastboot.c
@@ -103,8 +103,15 @@ static int do_fastboot_usb(int argc, char *const argv[],
 	while (1) {
 		if (g_dnl_detach())
 			break;
-		if (ctrlc())
+		if (IS_ENABLED(CONFIG_CMD_FASTBOOT_ABORT_KEYED)) {
+			if (tstc()) {
+				getchar();
+				puts("\rOperation aborted.\n");
+				break;
+			}
+		} else if (ctrlc()) {
 			break;
+		}
 		schedule();
 		dm_usb_gadget_handle_interrupts(udc);
 	}

-- 
2.54.0

