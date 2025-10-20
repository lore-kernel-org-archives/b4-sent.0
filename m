From: George Chan <gchan9527@gmail.com>
Date: Tue, 21 Oct 2025 00:36:33 +0800
Subject: [PATCH] boot: bootmeth_android: Conditionally dependent on
 abootimg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-abootimg-minor-v1-1-88a12f53d8de@gmail.com>
X-B4-Tracking: v=1; b=H4sIABBl9mgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDAyND3cSk/PySzNx03dzMvPwiXUNzc1NTC0uTRGNzMyWgpoKi1LTMCrC
 B0bG1tQAftXR3YAAAAA==
To: u-boot@lists.denx.de
Cc: George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760978200; l=2098;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=4uMc+7Ut7q3MkWXCPAn8CwIr0ccGA2b3VMox67PjwlM=;
 b=DrNyxFWGuHqkyZOTnC8Whvk+bwzSYrCetTX4l7KgHMQjo0rUyUyFHWTc5fgnhgVE32PXdM/R8
 6JmtS4vCh3uDhE7EdrqAgoWU4GBe58jdVRk2AAPyocSArOZKs392yXp
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
Cc: 
---
 boot/bootmeth_android.c | 2 +-
 include/image.h         | 3 ++-
 2 files changed, 3 insertions(+), 2 deletions(-)

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
index fc2f2487095..55a6af69b31 100644
--- a/include/image.h
+++ b/include/image.h
@@ -2039,7 +2039,7 @@ ulong get_abootimg_addr(void);
  * Return: no returned results
  */
 void set_abootimg_addr(ulong addr);
-
+void __weak set_abootimg_addr(ulong addr) {}
 /**
  * get_ainit_bootimg_addr() - Get Android init boot image address
  *
@@ -2060,6 +2060,7 @@ ulong get_avendor_bootimg_addr(void);
  * Return: no returned results
  */
 void set_avendor_bootimg_addr(ulong addr);
+void __weak set_avendor_bootimg_addr(ulong addr) {}
 
 /**
  * board_fit_config_name_match() - Check for a matching board name

---
base-commit: 4e4a9de31de2a5f395ee25c59e4026422fbcb27e
change-id: 20251021-abootimg-minor-17755894a376

Best regards,
-- 
George Chan <gchan9527@gmail.com>

