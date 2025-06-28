From: George Chan <gchan9527@gmail.com>
Date: Sat, 28 Jun 2025 20:25:22 +0800
Subject: [PATCH v3 4/7] bootm: Append bootargs value when bootmeth_android
 provide cmdline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250628-sc7180-android-boot-v3-4-105098a19165@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751113519; l=680;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=KXNFVFL5HddagemUBAB7NDgbvaNS8Lbmx2/LdQwZWpw=;
 b=ODo9OSkjxsNgelINwV/bCuq6K6MTIaQKJfTfc25kFWJ5ajGxBmjhCpV2xKsUf06hR04vR/uS3
 8W8gRg3ZGUcC28KkGjLq8Avd3uGtyLySgFrUf0o+cJ7zQERcUjPUpUe
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Old logic wipe bootargs env with cmdline, new logic cater the value
by prepending cmdline value to bootargs.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/bootm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/boot/bootm.c b/boot/bootm.c
index 4bdca22ea8c..d8e0c3527d0 100644
--- a/boot/bootm.c
+++ b/boot/bootm.c
@@ -1165,7 +1165,7 @@ int bootm_boot_start(ulong addr, const char *cmdline)
 
 	snprintf(addr_str, sizeof(addr_str), "%lx", addr);
 
-	ret = env_set("bootargs", cmdline);
+	ret = android_image_modify_bootargs_env(cmdline, NULL);
 	if (ret) {
 		printf("Failed to set cmdline\n");
 		return ret;

-- 
2.43.0

