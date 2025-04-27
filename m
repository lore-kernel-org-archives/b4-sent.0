From: George Chan <gchan9527@gmail.com>
Date: Sun, 27 Apr 2025 19:25:20 +0800
Subject: [PATCH 1/3] boot/image-android.c: Workaround androidboot
 kernel/ramdisk addr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-android-boot-v1-1-bb6b37c9c9f1@gmail.com>
References: <20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com>
In-Reply-To: <20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745753127; l=1729;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=vW9sx6lG2KtfDbPcC1sbK8kJPmrWjFZnmu7Ce8PyjNo=;
 b=bHByYGkb/7Fv2LHiK+ydFWUOVw3eLCbWGt+x5pHfr+zLxnX+NcGtbHJj0mQ2Wrt9WScDD1rCY
 9w+YMhGt1kgAYznac2O4dAaSWHeEOq9kql1z0oyJi7lbdYWJgwDNsYz
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some vendor bootloader ignored kernel/ramdisk addr and use
their own addr. Even those addr are pointing to out-of-reach
memory block at 0, and available address start at 0x80000000.

So we also need to use our own available addr for loadaddr.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/image-android.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/boot/image-android.c b/boot/image-android.c
index 1746b018900..36822d788b0 100644
--- a/boot/image-android.c
+++ b/boot/image-android.c
@@ -12,6 +12,7 @@
 #include <asm/unaligned.h>
 #include <mapmem.h>
 #include <linux/libfdt.h>
+#include <dm/of.h>
 
 #define ANDROID_IMAGE_DEFAULT_KERNEL_ADDR	0x10008000
 #define ANDROID_IMAGE_DEFAULT_RAMDISK_ADDR	0x11000000
@@ -281,6 +282,13 @@ static ulong android_image_get_kernel_addr(struct andr_image_data *img_data,
 	if (img_data->kernel_addr == 0 && img_data->ramdisk_addr == 0)
 		return env_get_ulong("kernel_addr_r", 16, 0);
 
+	/*
+	 * Some vendor bootloader ignore kernel and ramdisk address also
+	 * default value are out of physical mem base... so we use ours.
+	 */
+	if (img_data->kernel_addr < gd->ram_base)
+		return env_get_ulong("kernel_addr_r", 16, 0);
+
 	return img_data->kernel_addr;
 }
 
@@ -490,6 +498,8 @@ int android_image_get_ramdisk(const void *hdr, const void *vendor_boot_img,
 		if (img_data.ramdisk_addr == 0 ||
 		    img_data.ramdisk_addr == ANDROID_IMAGE_DEFAULT_RAMDISK_ADDR) {
 			*rd_data = img_data.ramdisk_ptr;
+		} else if (img_data.ramdisk_addr < gd->ram_base) {
+                        *rd_data = img_data.ramdisk_ptr;
 		} else {
 			ramdisk_ptr = img_data.ramdisk_addr;
 			*rd_data = ramdisk_ptr;

-- 
2.43.0

