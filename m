From: George Chan <gchan9527@gmail.com>
Date: Mon, 30 Jun 2025 15:56:52 +0800
Subject: [PATCH v4 3/6] bootm: Append bootargs value when bootmeth_android
 provide cmdline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-sc7180-android-boot-v4-3-24cdb50e860f@gmail.com>
References: <20250630-sc7180-android-boot-v4-0-24cdb50e860f@gmail.com>
In-Reply-To: <20250630-sc7180-android-boot-v4-0-24cdb50e860f@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, gchan9527@gmail.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751270223; l=680;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=KXNFVFL5HddagemUBAB7NDgbvaNS8Lbmx2/LdQwZWpw=;
 b=yIhghEwDWeoG+x6l1/V/EOXrrWRBqgrfdvy0wBGQDnnYx/ldfrrOXjdnZEJiXKSSY5LaTmhxi
 Q2kUMQq1lGMA6OFdCIWr7qNFo6rfJ7Kyalh9hNYRXWDjeI9SuZgNPwL
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

