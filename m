From: George Chan <gchan9527@gmail.com>
Date: Sun, 18 May 2025 19:16:18 +0800
Subject: [PATCH v3 1/3] boot/image-android: Workaround kernel/ramdisk
 invalid addr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250518-android-boot-v3-1-02c8768e131f@gmail.com>
References: <20250518-android-boot-v3-0-02c8768e131f@gmail.com>
In-Reply-To: <20250518-android-boot-v3-0-02c8768e131f@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747567000; l=3325;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=EFFSdG3QJbIwHPF9GXOo9SwvQPg4VgLraDIxs5ZRWlE=;
 b=UKBO2x9gk2LZuNgpL9eo8MbUTXsWlLDdFGm8sEmVonLdMtIGJlTPudRSt+NbgU/SD/rEVRqX4
 g5fIg9uZIORCftJInWAxrmYazSpwOs85vDiuLkTcBW0gEzxBm41Qoyw
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some androidboot image have invalid kernel/ramdisk load addr,
force to ignore those value and use loadaddr instead.

There is a concern on exposing the whole memory to image loading is
dangerous. Also, since it's not always possible to change the load
addr by repacking the boot.img (mainly due to AVB signature mismatch),
we need a way to use kernel_addr_r and ramdisk_addr_r.

Suggested-by: Casey Connolly <casey.connolly@linaro.org>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Tested-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/Kconfig         | 11 +++++++++++
 boot/image-android.c |  9 ++++++---
 2 files changed, 17 insertions(+), 3 deletions(-)

diff --git a/boot/Kconfig b/boot/Kconfig
index 30eb5b328d7..b9bbfe9ce88 100644
--- a/boot/Kconfig
+++ b/boot/Kconfig
@@ -11,6 +11,17 @@ config ANDROID_BOOT_IMAGE
 	  This enables support for booting images which use the Android
 	  image format header.
 
+config ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR
+	bool "Android Boot Image ignore addr"
+	default n
+	help
+	  This ignore kernel/ramdisk load addr specified in androidboot header.
+
+	  There is a concern on exposing the whole memory to image loading is
+	  dangerous. Also, since it's not always possible to change the load
+	  addr by repacking the boot.img (mainly due to AVB signature mismatch),
+	  we need a way to use kernel_addr_r and ramdisk_addr_r.
+
 config TIMESTAMP
 	bool "Show image date and time when displaying image information"
 	default y if CMD_DATE
diff --git a/boot/image-android.c b/boot/image-android.c
index 1746b018900..ab7c08eeb89 100644
--- a/boot/image-android.c
+++ b/boot/image-android.c
@@ -268,7 +268,8 @@ static ulong android_image_get_kernel_addr(struct andr_image_data *img_data,
 	 *
 	 * Otherwise, we will return the actual value set by the user.
 	 */
-	if (img_data->kernel_addr  == ANDROID_IMAGE_DEFAULT_KERNEL_ADDR) {
+	if (img_data->kernel_addr  == ANDROID_IMAGE_DEFAULT_KERNEL_ADDR ||
+	    IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR)) {
 		if (comp == IH_COMP_NONE)
 			return img_data->kernel_ptr;
 		return env_get_ulong("kernel_addr_r", 16, 0);
@@ -464,7 +465,8 @@ int android_image_get_ramdisk(const void *hdr, const void *vendor_boot_img,
 	 */
 	if (img_data.header_version > 2) {
 		/* Ramdisk can't be used in-place, copy it to ramdisk_addr_r */
-		if (img_data.ramdisk_addr == ANDROID_IMAGE_DEFAULT_RAMDISK_ADDR) {
+		if (img_data.ramdisk_addr == ANDROID_IMAGE_DEFAULT_RAMDISK_ADDR ||
+		    IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR)) {
 			ramdisk_ptr = env_get_ulong("ramdisk_addr_r", 16, 0);
 			if (!ramdisk_ptr) {
 				printf("Invalid ramdisk_addr_r to copy ramdisk into\n");
@@ -488,7 +490,8 @@ int android_image_get_ramdisk(const void *hdr, const void *vendor_boot_img,
 	} else {
 		/* Ramdisk can be used in-place, use current ptr */
 		if (img_data.ramdisk_addr == 0 ||
-		    img_data.ramdisk_addr == ANDROID_IMAGE_DEFAULT_RAMDISK_ADDR) {
+		    img_data.ramdisk_addr == ANDROID_IMAGE_DEFAULT_RAMDISK_ADDR ||
+		    IS_ENABLED(CONFIG_ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR)) {
 			*rd_data = img_data.ramdisk_ptr;
 		} else {
 			ramdisk_ptr = img_data.ramdisk_addr;

-- 
2.43.0

