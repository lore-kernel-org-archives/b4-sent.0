From: George Chan <gchan9527@gmail.com>
Date: Sat, 28 Jun 2025 20:25:21 +0800
Subject: [PATCH v3 3/7] image-android.c: Add null check to bootargs and
 cmdline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250628-sc7180-android-boot-v3-3-105098a19165@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751113519; l=2557;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=j5YCixUsDKdzdfkhZDGwCtyoe5eH8Vhi1xe40CBHgcc=;
 b=F2G/zbr48b1CKRuvoj0OmHbexF71U4MUdLPG2j72s1B4dQPB9F48jHNbEwMVd+4dUKSP3p9cH
 j+GbdWW9oinBHbZvVd8yFDxLxG16KgIkhFKOeAMAsIE4Na2iJ549K9g
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With some manual testing, when bootargs and/or cmdline from android boot
image is absent there will be some unhandled behavior happened.

So add null check to all these const char values.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/image-android.c | 27 +++++++++++++++++----------
 1 file changed, 17 insertions(+), 10 deletions(-)

diff --git a/boot/image-android.c b/boot/image-android.c
index 26e2fc21929..422f254c78d 100644
--- a/boot/image-android.c
+++ b/boot/image-android.c
@@ -299,15 +299,20 @@ int android_image_modify_bootargs_env(const char *cmd, const char *cmd_extra) {
 	char *newbootargs;
 	int len = 0;
 
-	if (bootargs)
-		len += strlen(bootargs);
-
-	if (cmd && *cmd)
+	if (cmd != NULL && cmd && *cmd)
 		len += strlen(cmd) + (len ? 1 : 0); /* +1 for extra space */
 
-	if (cmd_extra && *cmd_extra)
+	if (cmd_extra != NULL && cmd_extra && *cmd_extra)
 		len += strlen(cmd_extra) + (len ? 1 : 0); /* +1 for extra space */
 
+	if (len <=2) {
+		puts("Error: neither bootargs, ccmdline or cmdline_extra found!\n");
+		return 0;
+	}
+
+	if (bootargs != NULL && bootargs && *bootargs)
+		len += strlen(bootargs);
+
 	newbootargs = malloc(len + 2); /* +2 for 2x '\0' */
 
 	if (!newbootargs) {
@@ -317,22 +322,24 @@ int android_image_modify_bootargs_env(const char *cmd, const char *cmd_extra) {
 
 	*newbootargs = '\0'; /* set to Null in case no components below are present */
 
-	if (bootargs && !IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS))
-		strcpy(newbootargs, bootargs);
+	if (bootargs != NULL && bootargs && *bootargs
+	    && !IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS))
+		strcat(newbootargs, bootargs);
 
-	if (cmd && *cmd) {
+	if (cmd != NULL && cmd && *cmd) {
 		if (*newbootargs) /* If there is something in newbootargs, a space is needed */
 				strcat(newbootargs, " ");
 		strcat(newbootargs, cmd);
 	}
 
-	if (cmd_extra && *cmd_extra) {
+	if (cmd_extra != NULL && cmd_extra && *cmd_extra) {
 		if (*newbootargs) /* If there is something in newbootargs, a space is needed */
 				strcat(newbootargs, " ");
 		strcat(newbootargs, cmd_extra);
 	}
 
-	if (bootargs && IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS)) {
+	if (bootargs != NULL && bootargs && *bootargs
+	    && IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_PREPEND_ENV_BOOTARGS)) {
 		if (*newbootargs) /* If there is something in newbootargs, a space is needed */
 				strcat(newbootargs, " ");
 		strcat(newbootargs, bootargs);

-- 
2.43.0

