From: George Chan <gchan9527@gmail.com>
Date: Sat, 07 Jun 2025 13:24:56 +0800
Subject: [PATCH v2 1/5] image-android: Prepend/postpend default bootargs
 value with given bootcmd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250607-sc7180-android-boot-v2-1-2df5d7f61124@gmail.com>
References: <20250607-sc7180-android-boot-v2-0-2df5d7f61124@gmail.com>
In-Reply-To: <20250607-sc7180-android-boot-v2-0-2df5d7f61124@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, gchan9527@gmail.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749273923; l=2238;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=0MyFt94/oKWd2BvVUCEfX1gGvkDWRar9NEK3NeltmRw=;
 b=1IXUPPhTK++Ub18Scj4PcBr0ELAAyG4qU66THn5U6T8PVtjRBrt4bs0wP4A3APyXx5tkP8Iql
 SA9QKiVNUkPCndvL1E2D3pxm5HcYOw61vliI3ozAdyJ0V4cn0Zzp8/I
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Control how default bootargs is prepended or postpended to boot param found
from androidboot img.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/Kconfig         |  7 +++++++
 boot/image-android.c | 10 ++++++++--
 2 files changed, 15 insertions(+), 2 deletions(-)

diff --git a/boot/Kconfig b/boot/Kconfig
index 30eb5b328d7..7b71a340620 100644
--- a/boot/Kconfig
+++ b/boot/Kconfig
@@ -11,6 +11,13 @@ config ANDROID_BOOT_IMAGE
 	  This enables support for booting images which use the Android
 	  image format header.
 
+config ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS
+	bool "Android Boot Image boot cmd param will prepend to env bootargs"
+	help
+	  This control how androidboot img with bootcmd param integrate with u-boot
+	  env bootargs. By enable this, androidboot boot param will prepend to
+	  head of bootargs env.
+
 config TIMESTAMP
 	bool "Show image date and time when displaying image information"
 	default y if CMD_DATE
diff --git a/boot/image-android.c b/boot/image-android.c
index 1746b018900..fbcd2682a5e 100644
--- a/boot/image-android.c
+++ b/boot/image-android.c
@@ -347,14 +347,14 @@ int android_image_get_kernel(const void *hdr,
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
@@ -369,6 +369,12 @@ int android_image_get_kernel(const void *hdr,
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

