From: Sam Day <me@samcday.com>
Date: Fri, 19 Jun 2026 09:55:00 +1000
Subject: [PATCH v2 1/2] cmd: fastboot: Add keyed abort option
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-fastboot-abort-keyed-v2-1-684e53949a42@samcday.com>
References: <20260619-fastboot-abort-keyed-v2-0-684e53949a42@samcday.com>
In-Reply-To: <20260619-fastboot-abort-keyed-v2-0-684e53949a42@samcday.com>
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
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Simon Glass <sjg@chromium.org>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781826900; l=2325;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=8IdJ+yvCsU8SlDv/MTiMOENAhbiNbUlhwUZ70yGbkAk=;
 b=WY0ZvcIizsWTxkutopFVYxsfOYqLjzEx8xCHPkMIoYmIwWSAYKFpMjmpQvE3MMvB+fIkzCxQJ
 g8zm+kQo4RBDGAoZmTfnbmr/cYm2647UC3IaLAL6AJxMRHblUSL89tm
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Works the same as CONFIG_CMD_UMS_ABORT_KEYED does: any keypress will
abort fastboot mode (rather than only ctrl-c).

Reviewed-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Tested-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Reviewed-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: Sam Day <me@samcday.com>
---
 cmd/Kconfig              | 7 +++++++
 cmd/fastboot.c           | 9 ++++++++-
 doc/android/fastboot.rst | 4 ++++
 3 files changed, 19 insertions(+), 1 deletion(-)

diff --git a/cmd/Kconfig b/cmd/Kconfig
index c71c6824a19..ee932cc25f1 100644
--- a/cmd/Kconfig
+++ b/cmd/Kconfig
@@ -1208,6 +1208,13 @@ config CMD_FASTBOOT
 
 	  See doc/android/fastboot.rst for more information.
 
+config CMD_FASTBOOT_ABORT_KEYED
+	bool "fastboot abort with any key"
+	depends on CMD_FASTBOOT && USB_FUNCTION_FASTBOOT
+	help
+	  Allow interruption of USB fastboot mode by any key presses,
+	  rather than just Ctrl-c.
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
diff --git a/doc/android/fastboot.rst b/doc/android/fastboot.rst
index 818b8815ebd..96c544ae11b 100644
--- a/doc/android/fastboot.rst
+++ b/doc/android/fastboot.rst
@@ -217,6 +217,10 @@ It's possible to interrupt the fastboot command using Ctrl-c::
    => fastboot usb 0
    Operation aborted.
 
+``CONFIG_CMD_FASTBOOT_ABORT_KEYED`` can be enabled so that *any* keypress
+will interrupt the fastboot command, rather than just Ctrl-c. This can be
+quite useful on mobile devices which lack a means to input Ctrl-c.
+
 You can also specify a kernel image to boot. You have to either specify
 the an image in Android format *or* pass a binary kernel and let the
 fastboot client wrap the Android suite around it. On OMAP for instance you

-- 
2.54.0

