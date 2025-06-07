From: George Chan <gchan9527@gmail.com>
Date: Sat, 07 Jun 2025 13:24:57 +0800
Subject: [PATCH v2 2/5] bootm: Append bootargs value when bootmeth_android
 provide cmdline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250607-sc7180-android-boot-v2-2-2df5d7f61124@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749273923; l=1531;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=QzAXV3TUQetJKh/4eaQeq6FcGlY9YPKgygVu64gQGpI=;
 b=6ZvEpk2UuUnhKluGqJBf8KOch/v8uzE/QQO7dJmDhv97U6CZDmjP8pjq9IlL1ZH8qM9vMYYv3
 UlqPnk5vWa2BtOU8BYFD0OTrHNBex545DECprBAsh2kntL8kYiCIEl3
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Old logic wipe bootargs env with cmdline, new logic maintain the
value by prepending cmdline value to bootargs.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/bootm.c | 29 ++++++++++++++++++++++++++++-
 1 file changed, 28 insertions(+), 1 deletion(-)

diff --git a/boot/bootm.c b/boot/bootm.c
index f6aa32746b7..888684a91f5 100644
--- a/boot/bootm.c
+++ b/boot/bootm.c
@@ -1152,11 +1152,38 @@ int bootm_boot_start(ulong addr, const char *cmdline)
 
 	snprintf(addr_str, sizeof(addr_str), "%lx", addr);
 
-	ret = env_set("bootargs", cmdline);
+	if (IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS)) {
+		char *bootargs;
+		char *newbootargs;
+		bootargs = env_get("bootargs");
+		ret = strlen(bootargs) + strlen(cmdline) + 2;
+
+		newbootargs = malloc(ret);
+
+		*newbootargs = '\0';
+
+		if (*newbootargs) /* If there is something in newbootargs, a space is needed */
+			strcat(newbootargs, " ");
+		strcat(newbootargs, cmdline);
+
+		if (*newbootargs) /* If there is something in newbootargs, a space is needed */
+			strcat(newbootargs, " ");
+		strcat(newbootargs, bootargs);
+
+		/* force to terminate the string */
+		memset(newbootargs + MAX_CMDLINE_SIZE - 2, '\0', 1);
+
+		ret = env_set("bootargs", newbootargs);
+
+		free(newbootargs);
+	} else
+		ret = env_set("bootargs", cmdline);
+
 	if (ret) {
 		printf("Failed to set cmdline\n");
 		return ret;
 	}
+
 	bootm_init(&bmi);
 	bmi.addr_img = addr_str;
 	bmi.cmd_name = "bootm";

-- 
2.43.0

