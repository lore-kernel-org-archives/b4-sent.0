From: George Chan <gchan9527@gmail.com>
Date: Tue, 20 May 2025 22:25:58 +0800
Subject: [PATCH 3/4] boot: bootmeth_android: Conditionally dependent on
 abootimg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250520-sc7180-android-boot-v1-3-3075a84ea094@gmail.com>
References: <20250520-sc7180-android-boot-v1-0-3075a84ea094@gmail.com>
In-Reply-To: <20250520-sc7180-android-boot-v1-0-3075a84ea094@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747751157; l=1767;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=WjgYwgaVztceTx2DDYS0GrMHIgSKhAFgtLATy38C6+o=;
 b=soghn9/18o6C7GK4RrfKR8lDBsrIn07FLIJLu2LnSYocuuyLyvdAeBG2BHbWi4jl6XPREifXm
 rgMdHA0d1ANDur42p4N8cdxXfWB6Qzzcy4MR5/ttjBQ2aW2N8WEGduM
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If target u-boot img do not support androidboot v3 or greater,
abootimg might not be necessary.

aarch64-linux-gnu-ld.bfd: boot/bootmeth_android.o: in function `boot_android_normal':
/home/user/sources/u-boot-next/boot/bootmeth_android.c:541:(.text.boot_android_normal+0xd0): undefined reference to `set_avendor_bootimg_addr'
aarch64-linux-gnu-ld.bfd: /home/user/sources/u-boot-next/boot/bootmeth_android.c:543:(.text.boot_android_normal+0xd8): undefined reference to `set_abootimg_addr'
Segmentation fault (core dumped)

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/bootmeth_android.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/boot/bootmeth_android.c b/boot/bootmeth_android.c
index 654ebfdf1fc..29a9a4afe7a 100644
--- a/boot/bootmeth_android.c
+++ b/boot/bootmeth_android.c
@@ -517,7 +517,7 @@ static int boot_android_normal(struct bootflow *bflow)
 	struct android_priv *priv = bflow->bootmeth_priv;
 	int ret;
 	ulong loadaddr = env_get_hex("loadaddr", 0);
-	ulong vloadaddr = env_get_hex("vendor_boot_comp_addr_r", 0);
+	ulong __maybe_unused vloadaddr = env_get_hex("vendor_boot_comp_addr_r", 0);
 
 	ret = run_avb_verification(bflow);
 	if (ret < 0)
@@ -533,6 +533,7 @@ static int boot_android_normal(struct bootflow *bflow)
 	if (ret < 0)
 		return log_msg_ret("read boot", ret);
 
+#ifdef CONFIG_CMD_ABOOTIMG
 	if (priv->header_version >= 3) {
 		ret = read_slotted_partition(desc, "vendor_boot", priv->slot,
 					     priv->vendor_boot_img_size, vloadaddr);
@@ -541,6 +542,7 @@ static int boot_android_normal(struct bootflow *bflow)
 		set_avendor_bootimg_addr(vloadaddr);
 	}
 	set_abootimg_addr(loadaddr);
+#endif
 
 	if (priv->slot)
 		free(priv->slot);

-- 
2.43.0

