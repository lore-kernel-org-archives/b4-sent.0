From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 02 Oct 2026 22:52:57 +0200
Subject: [PATCH] fastboot: scale download progress dots to video console
 width
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-b4-fastboot-dot-width-v1-1-93bb3cb13179@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAyF4asgz7WUpBCpvQrqQIgDZiAoTgsS4
 u4NMLzhG96/g1BiEnhXOyT6sXCcC/Sjgn7s5oGQfTEYZaxWyqCrMXSSXYwZfdnKPo8YGksv/dT
 WNgrKd0kUeLu67ee2fN1EfT5jcBx/nH9OcXkAAAA=
X-Change-ID: 20261002-b4-fastboot-dot-width-f56e91316650
To: u-boot@lists.u-boot-project.org
Cc: Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790974378; l=2407;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=DqDiwDLDrHJFHp1VXxDk67SMOKbkDAfKJjs+UpfW8CU=;
 b=aFjAEP+qoXRyRJj/zpy7ayg5D/jsIbGybeMA5HDOEzHQxcKu1Eo3Irt8NUH5z/y6mWq53je+3
 k0xe8j+FZD/A03HUYnojFnCJBxdvSD102Fgd6hYMe71Nrfp2zoaVeg1
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The download progress indicator wraps to a new line every 74 dots.
On boards with a video console the row is usually a different width,
so query the active video console's column count and use that instead,
falling back to the old default when no video console is probed.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Found while testing fastboot flashing on a device using the on-screen
video console. The fixed 74-column dot-wrap assumed a serial terminal
and looked broken on the panel's actual row width.
---
 drivers/fastboot/fb_command.c | 26 +++++++++++++++++++++++++-
 1 file changed, 25 insertions(+), 1 deletion(-)

diff --git a/drivers/fastboot/fb_command.c b/drivers/fastboot/fb_command.c
index 18d86988f4c..e6a5f9b840c 100644
--- a/drivers/fastboot/fb_command.c
+++ b/drivers/fastboot/fb_command.c
@@ -5,6 +5,7 @@
 
 #include <command.h>
 #include <console.h>
+#include <dm.h>
 #include <env.h>
 #include <fastboot.h>
 #include <fastboot-internal.h>
@@ -14,9 +15,12 @@
 #include <fb_spi_flash.h>
 #include <part.h>
 #include <stdlib.h>
+#include <video_console.h>
 #include <vsprintf.h>
 #include <linux/printk.h>
 
+#define FASTBOOT_DOT_LINE_WIDTH_DEFAULT	74
+
 /**
  * image_size - final fastboot image size
  */
@@ -266,6 +270,26 @@ u32 fastboot_data_remaining(void)
 	return fastboot_bytes_expected - fastboot_bytes_received;
 }
 
+/**
+ * fastboot_dot_line_width() - number of dot columns to print per line
+ *
+ * Return: number of dot columns per line
+ */
+static int fastboot_dot_line_width(void)
+{
+	struct udevice *dev;
+	struct vidconsole_priv *priv;
+
+	if (IS_ENABLED(CONFIG_VIDEO) &&
+	    !uclass_first_device_err(UCLASS_VIDEO_CONSOLE, &dev)) {
+		priv = dev_get_uclass_priv(dev);
+		if (priv->cols > 0)
+			return priv->cols;
+	}
+
+	return FASTBOOT_DOT_LINE_WIDTH_DEFAULT;
+}
+
 /**
  * fastboot_data_download() - Copy image data to fastboot_buf_addr.
  *
@@ -304,7 +328,7 @@ void fastboot_data_download(const void *fastboot_data,
 
 	if (pre_dot_num != now_dot_num) {
 		putc('.');
-		if (!(now_dot_num % 74))
+		if (!(now_dot_num % fastboot_dot_line_width()))
 			putc('\n');
 	}
 	*response = '\0';

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261002-b4-fastboot-dot-width-f56e91316650

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

