From: Mohamed Yassine Jebabli <med.jebabli@gmail.com>
Date: Thu, 01 Oct 2026 12:24:42 +0200
Subject: [PATCH] ALSA: hda/tas2781: Accept V1 calibration data without CRC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-tas2781-v1-nocrc-v1-1-ff0c1032ce76@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQqAMAxA0atIZgNNoFq8ijhojJqlSisiiHe3O
 L7h/weyJtMMXfVA0suy7bGA6gpkG+OqaHMxsOOGnCM8x8xtILwI4y5JUJuJxc/sJQQo2ZF0sft
 f9sP7fhBIAW1iAAAA
X-Change-ID: 20261001-tas2781-v1-nocrc-e6b2c5d25c88
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Shenghao Ding <shenghao-ding@ti.com>
Cc: Takashi Iwai <tiwai@suse.de>, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Mohamed Yassine Jebabli <med.jebabli@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790850283; l=2533;
 i=med.jebabli@gmail.com; s=20261001; h=from:subject:message-id;
 bh=CENQtlJ1LypGiyn5qauAiaLgNcBd83EMwaUm18pDmiQ=;
 b=JhDI0NDil2dH/dtMHaKh1TRVF7lJpLA0hTz5AI9YQ5xLACAmNcB5dvoecqoxf83jO6oQsg0oP
 AaMv3Rb3b9OBC8dWRYdxcbG+nOFLphpLvjLK5RlVjFnX59as93p0+5A
X-Developer-Key: i=med.jebabli@gmail.com; a=ed25519;
 pk=DrcY8DXRRRL44W1NDZ4mXZmW9PRCASf9qYo1sm0KFYE=
X-Endpoint-Received: by B4 Relay for med.jebabli@gmail.com/20261001 with auth_id=1095
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some Lenovo BIOSes (e.g. Legion Pro 7 16IRX9H, SSID 17aa:38cd) store
valid V1 calibration data in the CALI_DATA EFI variable but leave the
TimeStamp and CRC fields zeroed. The driver rejects such data, so the
amplifiers always run with default parameters on these machines.

The rejection was silent until
commit 4fe238513407 ("ALSA: hda/tas2781: Move and unified the
calibrated-data getting function for SPI and I2C into the tas2781_hda lib")
turned it into "V1 CRC error".

The stored values are consistent (R0 = 3.82/3.83 ohm, 1/R0 matching
within 1e-4), so accept V1 data when both TimeStamp and CRC are zero
and the first device entry is non-zero, and emit a warning.

Fixes: 5be27f1e3ec9 ("ALSA: hda/tas2781: Add tas2781 HDA driver")
Cc: stable@vger.kernel.org
Signed-off-by: Mohamed Yassine Jebabli <med.jebabli@gmail.com>
---
Tested on a Lenovo Legion Pro 7 16IRX9H (BIOS N2CN32WW) with Ubuntu
7.0.0-34: the calibration data is now applied instead of being
rejected.

CALI_DATA payload (128 bytes, 2 devices populated):
  00: 5d02871e 312d8b21 6258f817 85bca500 0000e02e
  14: 263dad1e c45f6121 f85c1618 912aa500 0000e02e
  28..7f: all zero (incl. TimeStamp at 0x50 and CRC at 0x54)
---
 sound/hda/codecs/side-codecs/tas2781_hda.c | 18 +++++++++++++++---
 1 file changed, 15 insertions(+), 3 deletions(-)

diff --git a/sound/hda/codecs/side-codecs/tas2781_hda.c b/sound/hda/codecs/side-codecs/tas2781_hda.c
index b22f93424c62..e0da299df780 100644
--- a/sound/hda/codecs/side-codecs/tas2781_hda.c
+++ b/sound/hda/codecs/side-codecs/tas2781_hda.c
@@ -139,9 +139,21 @@ static void tas2781_apply_calib(struct tasdevice_priv *p)
 		 */
 		crc = crc32(~0, data, 84) ^ ~0;
 		if (crc != tmp_val[21]) {
-			cali_data->total_sz = 0;
-			dev_err(p->dev, "%s: V1 CRC error\n", __func__);
-			return;
+			/*
+			 * Some Lenovo BIOSes (e.g. Legion Pro 7 16IRX9H,
+			 * SSID 17aa:38cd) store valid V1 calibration data
+			 * but leave TimeStamp and CRC zeroed.
+			 */
+			if (!tmp_val[20] && !tmp_val[21] &&
+			    tmp_val[0] && tmp_val[1]) {
+				dev_warn(p->dev,
+					 "%s: V1 data without CRC, accepting\n",
+					 __func__);
+			} else {
+				cali_data->total_sz = 0;
+				dev_err(p->dev, "%s: V1 CRC error\n", __func__);
+				return;
+			}
 		}
 
 		for (j = p->ndev - 1; j >= 0; j--) {

---
base-commit: 1f2f457b771554777e3a3bee9b0cbb646ca2278f
change-id: 20261001-tas2781-v1-nocrc-e6b2c5d25c88

Best regards,
-- 
Mohamed Yassine Jebabli <med.jebabli@gmail.com>

