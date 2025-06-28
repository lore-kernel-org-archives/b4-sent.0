From: George Chan <gchan9527@gmail.com>
Date: Sat, 28 Jun 2025 20:25:19 +0800
Subject: [PATCH v3 1/7] image-android: Prepend/postpend default bootargs
 value with given bootcmd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250628-sc7180-android-boot-v3-1-105098a19165@gmail.com>
References: <20250628-sc7180-android-boot-v3-0-105098a19165@gmail.com>
In-Reply-To: <20250628-sc7180-android-boot-v3-0-105098a19165@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, gchan9527@gmail.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751113519; l=3055;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=OYcDlxA0LbIdCmI6cD9sVVUKdg/SXtfmjMU9BuWIyLU=;
 b=acin2CWd+bmNdv7zOJOCTyALfC8e0WYdZ6izRmDfvubL0RRFHzRhgwkpVZ5v4BrET5qhZcATr
 09GyWzk+rflAVpKWFBaCQRJ0Dzf74DsYwHZtoMowejzbCVZEZqx7hl8
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By default, the boot.img's cmdline are appended to the bootargs
environment.
If we take a cmdline example of:
* androidboot.hardware=warm (in U-Boot environment)
* androidboot.hardware=chilly (in boot.img's cmdline)

The resulting commandline will be:
androidboot.hardware=warm [...] androidboot.hardware=chilly.

Because of this, the U-Boot environment always take priority on the
boot.img.

If we want to have a single U-Boot binary that support multiple
board variants, we can't override androidboot.hardware via the boot.img.

Add a new Kconfig option, ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS that
reverse the logic.

Above detail is suggested from Mattijs Korpershoek <mkorpershoek@kernel.org>

Reviewed-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/Kconfig         |  9 +++++++++
 boot/image-android.c | 10 ++++++++--
 2 files changed, 17 insertions(+), 2 deletions(-)

diff --git a/boot/Kconfig b/boot/Kconfig
index a671d78e570..bcc5f886a01 100644
--- a/boot/Kconfig
+++ b/boot/Kconfig
@@ -22,6 +22,15 @@ config ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR
 	  addr by repacking the boot.img (mainly due to AVB signature mismatch),
 	  we need a way to use kernel_addr_r and ramdisk_addr_r.
 
+config ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS
+	bool "Android Boot Image boot cmd param will prepend to env bootargs"
+	help
+	  This controls how Android boot image embedded cmdline integrates
+	  with U-Boot bootargs environment.
+
+	  By enabling this, the boot.img's cmdline is prepended to the bootargs
+	  environment. By default, when disabled, the cmdline is appended.
+
 config TIMESTAMP
 	bool "Show image date and time when displaying image information"
 	default y if CMD_DATE
diff --git a/boot/image-android.c b/boot/image-android.c
index 14cf611cee5..d78e8a4148a 100644
--- a/boot/image-android.c
+++ b/boot/image-android.c
@@ -348,14 +348,14 @@ int android_image_get_kernel(const void *hdr,
 		len += strlen(img_data.kcmdline_extra) + (len ? 1 : 0); /* +1 for extra space */
 	}
 
-	char *newbootargs = malloc(len + 1); /* +1 for the '\0' */
+	char *newbootargs = malloc(len + 2); /* +2 for 2x '\0' */
 	if (!newbootargs) {
 		puts("Error: malloc in android_image_get_kernel failed!\n");
 		return -ENOMEM;
 	}
 	*newbootargs = '\0'; /* set to Null in case no components below are present */
 
-	if (bootargs)
+	if (bootargs && !IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS))
 		strcpy(newbootargs, bootargs);
 
 	if (img_data.kcmdline && *img_data.kcmdline) {
@@ -370,6 +370,12 @@ int android_image_get_kernel(const void *hdr,
 		strcat(newbootargs, img_data.kcmdline_extra);
 	}
 
+	if (bootargs && IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS)) {
+		if (*newbootargs) /* If there is something in newbootargs, a space is needed */
+			strcat(newbootargs, " ");
+		strcat(newbootargs, bootargs);
+	}
+
 	env_set("bootargs", newbootargs);
 	free(newbootargs);
 

-- 
2.43.0

