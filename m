From: George Chan <gchan9527@gmail.com>
Date: Sat, 28 Jun 2025 20:25:23 +0800
Subject: [PATCH v3 5/7] boot: bootmeth_android: Conditionally dependent on
 abootimg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250628-sc7180-android-boot-v3-5-105098a19165@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751113519; l=2044;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=7C9uzM2soKSCqA3JNzElAV8R0IY3qJ5Iyq7YkLB/LPY=;
 b=7lKHZEc4lnUn8l/w4pEbVWr1cd+Iqv/3LT74vtvjgLvYuUFoIOVrZLR4f4jz7o5etqUJHT9sD
 SlCjXWpR0GBDgWFnjO5idUDSLppaIrUYjU9ZkEEUkZmRgDUSA8/VykN
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

Reviewed-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Acked-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/bootmeth_android.c | 2 +-
 include/image.h         | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/boot/bootmeth_android.c b/boot/bootmeth_android.c
index 8c2bde10e17..d7740b86d67 100644
--- a/boot/bootmeth_android.c
+++ b/boot/bootmeth_android.c
@@ -534,7 +534,7 @@ static int boot_android_normal(struct bootflow *bflow)
 	if (ret < 0)
 		return log_msg_ret("read boot", ret);
 
-	if (priv->header_version >= 3) {
+	if (IS_ENABLED(CONFIG_CMD_ABOOTIMG) && priv->header_version >= 3) {
 		ret = read_slotted_partition(desc, "vendor_boot", priv->slot,
 					     priv->vendor_boot_img_size, vloadaddr);
 		if (ret < 0)
diff --git a/include/image.h b/include/image.h
index 11d33ceeb39..82a861ba8bf 100644
--- a/include/image.h
+++ b/include/image.h
@@ -2050,6 +2050,7 @@ ulong get_abootimg_addr(void);
  * Return: no returned results
  */
 void set_abootimg_addr(ulong addr);
+void __weak set_abootimg_addr(ulong addr) {}
 
 /**
  * get_ainit_bootimg_addr() - Get Android init boot image address
@@ -2071,6 +2072,7 @@ ulong get_avendor_bootimg_addr(void);
  * Return: no returned results
  */
 void set_avendor_bootimg_addr(ulong addr);
+void __weak set_avendor_bootimg_addr(ulong addr) {}
 
 /**
  * board_fit_config_name_match() - Check for a matching board name

-- 
2.43.0

