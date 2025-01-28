From: Federico Fuga <fuga@studiofuga.com>
Date: Tue, 28 Jan 2025 12:18:37 +0100
Subject: [PATCH] Fix fastboot handling of partitions when no slots are
 supported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250128-fastboot_slot_fix-v1-1-1a4688936662@studiofuga.com>
X-B4-Tracking: v=1; b=H4sIAAy9mGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQyML3bTE4pKk/PyS+OIcIJGWWaFrZmlkamhqbpZimZSkBNRXUJQKFAa
 bGR1bWwsAkAvxoGMAAAA=
X-Change-ID: 20250128-fastboot_slot_fix-69251576d9bb
To: Mattijs Korpershoek <mkorpershoek@baylibre.com>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, Federico Fuga <fuga@studiofuga.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3127; i=fuga@studiofuga.com;
 h=from:subject:message-id; bh=TKOjlYcOT6aH74HSyiAsmNFDbwha6KERQuHNXYuuMWg=;
 b=owGbwMvMwCWWHKr8a5mpjg3jabUkhvQZe4WOzZW80y9XezsuOSdl1urHn2zYErJedK8zNdvdM
 8/IZlFiRykLgxgXg6yYIsucl8/OZH3LPvtRd70WzBxWJpAhDFycAjCRN5cZ/gemTPScIO3qNf2n
 45nDu4wvJhaeWTh3eljedM5TvYYb52xl+MNRfJbZW8IkedsZieUyTprOhWWnHpYa65nUNm7ov2O
 8ixkA
X-Developer-Key: i=fuga@studiofuga.com; a=openpgp;
 fpr=9CE9E6CC6AF66BCDF12DAF2A635523FAA6352C3C
X-Endpoint-Received: by B4 Relay for fuga@studiofuga.com/default with auth_id=333
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fastboot module has a bug that prevents some command to work
properly on devices that haven't an Android-like partition scheme, that
is, just one spl and one kernel partition, instead of the redundant
scheme with _a and _b slots.

This is the schema of our NAND storage (board is based on an AllWinner
A33 sunxi chip):

=> mtdparts

device nand0 <1c03000.nand>, # parts = 4
 #: name         size            net size        offset          mask_flags
 0: spl          0x00020000      0x00020000      0x00000000      0
 1: uboot        0x00100000      0x00100000      0x00020000      0
 2: kernel_a     0x00400000      0x00400000      0x00120000      0
 3: ubi          0x07ae0000      0x079e0000 (!)  0x00520000      0

active partition: nand0,0 - (spl) 0x00020000 @ 0x00000000

This happens when we try to erase the spl partition using fastboot:

$ fastboot erase spl
Erasing 'spl_a'               FAILED (remote: 'invalid NAND device')
fastboot: error: Command failed

The error occurs because getvars fails to handle the error returned by
nand layer when a partition cannot be found.

Indeed, getvar_get_part_info returns what is returned by
fastboot_nand_get_part_info (0 on success, 1 on failure) but it should
return -ENODEV or -EINVAL instead. Since the cause of failure is not
returned by the nand function, I decided to return -EINVAL to make it
simple.

Signed-off-by: Federico Fuga <fuga@studiofuga.com>
---
 drivers/fastboot/fb_getvar.c | 5 ++++-
 drivers/fastboot/fb_nand.c   | 2 +-
 2 files changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/fastboot/fb_getvar.c b/drivers/fastboot/fb_getvar.c
index 9c2ce65a4e5bce0da6b18aa1b2818f7db556c528..816ed8a6213b5c1f0948a813c6f6a865a4b47ba8 100644
--- a/drivers/fastboot/fb_getvar.c
+++ b/drivers/fastboot/fb_getvar.c
@@ -121,8 +121,11 @@ static int getvar_get_part_info(const char *part_name, char *response,
 			*size = disk_part.size * disk_part.blksz;
 	} else if (IS_ENABLED(CONFIG_FASTBOOT_FLASH_NAND)) {
 		r = fastboot_nand_get_part_info(part_name, &part_info, response);
-		if (r >= 0 && size)
+		if (r == 0 && size) {
 			*size = part_info->size;
+		} else {
+			r = -EINVAL;
+		}
 	} else {
 		fastboot_fail("this storage is not supported in bootloader", response);
 		r = -ENODEV;
diff --git a/drivers/fastboot/fb_nand.c b/drivers/fastboot/fb_nand.c
index afc64fd5280717ae4041ed70268ccc01cfbb0496..9e2f7c01895785a4409eb67ea48abd02a6a6da26 100644
--- a/drivers/fastboot/fb_nand.c
+++ b/drivers/fastboot/fb_nand.c
@@ -151,7 +151,7 @@ static lbaint_t fb_nand_sparse_reserve(struct sparse_storage *info,
  *
  * @part_name: Named device to lookup
  * @part_info: Pointer to returned part_info pointer
- * @response: Pointer to fastboot response buffer
+ * @response: 0 on success, 1 otherwise
  */
 int fastboot_nand_get_part_info(const char *part_name,
 				struct part_info **part_info, char *response)

---
base-commit: a517796cfa5d8f4ca2f0c11c78c24a08a102c047
change-id: 20250128-fastboot_slot_fix-69251576d9bb

Best regards,
-- 
Federico Fuga <fuga@studiofuga.com>

