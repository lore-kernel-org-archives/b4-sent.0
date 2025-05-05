From: George Chan <gchan9527@gmail.com>
Date: Mon, 05 May 2025 17:17:11 +0800
Subject: [PATCH v2 3/5] fdt_support: Add support for extra var for bootargs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-android-boot-v2-3-92dcb5bf59c8@gmail.com>
References: <20250505-android-boot-v2-0-92dcb5bf59c8@gmail.com>
In-Reply-To: <20250505-android-boot-v2-0-92dcb5bf59c8@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746436629; l=2151;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=DmXSjUEMzw7M2QHDPDGOk6gusoHWBs/ShF98ZWSfjjs=;
 b=7+a3a5BpZG7zWMUq7y3SKH31kmjwbt2Rn59DVewbDpXMUkbToHuRX/NaoCGc2BFAwUueQVpHB
 bsf+755lnYtAa+shcBS7NdabkmWHkxsFof1XcH9rDJudtnobp8ZYlWc
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new env var 'legacy_os_boot_param' to hold legacy OS
dependent boot param.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/Kconfig       |  9 +++++++++
 boot/fdt_support.c | 20 +++++++++++++++++++-
 2 files changed, 28 insertions(+), 1 deletion(-)

diff --git a/boot/Kconfig b/boot/Kconfig
index 4bdac384181..80bb2eb7e77 100644
--- a/boot/Kconfig
+++ b/boot/Kconfig
@@ -17,6 +17,15 @@ config ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR
 	help
 	  This ignore kernel/ramdisk load addr specified in androidboot header.
 
+config SUPPORT_LEGACY_OS_BOOTPARAM
+	bool "Extra var to append bootargs"
+	default n
+	help
+	  This introduce env_var 'legacy_os_boot_param' to hold extra OS
+	  dependent kernel boot param, and append to fdt bootargs when bootm
+	  execute. The value is supposed to obtain from env file at compile time.
+	  Board dependent callback will override it completely.
+
 config TIMESTAMP
 	bool "Show image date and time when displaying image information"
 	default y if CMD_DATE
diff --git a/boot/fdt_support.c b/boot/fdt_support.c
index 92f2f534ee0..cc4d808eaf1 100644
--- a/boot/fdt_support.c
+++ b/boot/fdt_support.c
@@ -322,9 +322,27 @@ int fdt_kaslrseed(void *fdt, bool overwrite)
  * board_fdt_chosen_bootargs - boards may override this function to use
  *                             alternative kernel command line arguments
  */
+#define COMMAND_LINE_SIZE 1024
+static char bootargs[COMMAND_LINE_SIZE] = { 0 };
 __weak const char *board_fdt_chosen_bootargs(const struct fdt_property *fdt_ba)
 {
-	return env_get("bootargs");
+	if (IS_ENABLED(CONFIG_SUPPORT_LEGACY_OS_BOOTPARAM)) {
+		int j;
+		snprintf(bootargs, COMMAND_LINE_SIZE - 2, "%s %s",
+			env_get("bootargs"),
+	                env_get("legacy_os_boot_param"));
+
+		/* remove all carriage return */
+		for (j = 0; j < COMMAND_LINE_SIZE; j++) {
+			if (bootargs[j] == '\0')
+				break;
+
+			if ((bootargs[j] == '\n') || (bootargs[j] == '\r'))
+				bootargs[j] = ' ';
+		}
+		return bootargs;
+        } else
+		return env_get("bootargs");
 }
 
 int fdt_chosen(void *fdt)

-- 
2.43.0

