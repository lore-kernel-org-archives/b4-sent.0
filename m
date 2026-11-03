From: Mohamed Yassine Jebabli <med.jebabli@gmail.com>
Date: Tue, 03 Nov 2026 10:27:12 +0100
Subject: [PATCH] ALSA: hda/tas2781: Only accept CRC-less V1 data if all
 entries are valid
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-tas2781-v1-nocrc-fix-v1-1-a769c27f21ce@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAMAzAviI9W7Ab6PAr4mF2VXuZsokIsr87P
 CaQvJAlqWQYmxeS3Jr1iBWobYB3HzdBDZXBdKYn6ixePpvBEd6E8eDEuOqDLLxYG0S8W6GmZ5K
 q/+00l/IB3FbO/2YAAAA=
X-Change-ID: 20261103-tas2781-v1-nocrc-fix-cecb33deea8f
To: regressions@lists.linux.dev
Cc: Cristian Castellano <cristian.castellano@icloud.com>, 
 stable@vger.kernel.org, Mohamed Yassine Jebabli <med.jebabli@gmail.com>, 
 Takashi Iwai <tiwai@suse.com>, Jaroslav Kysela <perex@perex.cz>, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thorsten Leemhuis <regressions@leemhuis.info>, 
 Shenghao Ding <shenghao-ding@ti.com>, Kevin Lu <kevin-lu@ti.com>, 
 Baojun Xu <baojun.xu@ti.com>, Sen Wang <sen@ti.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793698033; l=3393;
 i=med.jebabli@gmail.com; s=20261001; h=from:subject:message-id;
 bh=hTyxP5z+2ryyUf7OXKh4MV/62ueN7NmrvIPpkkLjUsk=;
 b=iqDefFOg+eZPbjNKMezCK9hU3xHZ+lZ5tA03/M4+zN2zOYt9hQ4xHeg563in2/UVpA/9/cm9a
 0pN7usuwo9uCnar8LD+9UrnBw3lGPrWP1yA5S3hirRbu0GzxMHMPhQZ
X-Developer-Key: i=med.jebabli@gmail.com; a=ed25519;
 pk=DrcY8DXRRRL44W1NDZ4mXZmW9PRCASf9qYo1sm0KFYE=
X-Endpoint-Received: by B4 Relay for med.jebabli@gmail.com/20261001 with auth_id=1095
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 408249089c48 ("ALSA: hda/tas2781: Accept V1 calibration data
without CRC") only checked the first device entry. On machines where
the BIOS populates fewer entries than p->ndev, the remaining all-zero
entries are applied and tas2781_cali_preproc() divides by zero on
playback open.

Accept CRC-less V1 data only if every expected entry is non-zero and
self-consistent (R0 * 1/R0 close to 1.0), otherwise reject it as
before.

Fixes: 408249089c48 ("ALSA: hda/tas2781: Accept V1 calibration data without CRC")
Reported-by: Cristian Castellano <cristian.castellano@icloud.com>
Closes: https://lore.kernel.org/all/4e500063-d985-46b6-a0a1-3feaa77c4b2f@leemhuis.info/
Cc: stable@vger.kernel.org
Signed-off-by: Mohamed Yassine Jebabli <med.jebabli@gmail.com>
---
Cristian, could you test this on the Yoga Pro 9 16IRP8? With the fix,
the driver should log "V1 CRC error" again and fall back to default
parameters, as it did before 408249089c48. If it still logs
"accepting", p->ndev is 2 on your machine and the root cause is
elsewhere, so please send the full "dmesg | grep -i tas2781".

Takashi's re_cal check in tas2781_cali_preproc() is complementary
and still worth applying as a safeguard.

To: Takashi Iwai <tiwai@suse.com>
To: Jaroslav Kysela <perex@perex.cz>
Cc: regressions@lists.linux.dev
Cc: linux-sound@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Cristian Castellano <cristian.castellano@icloud.com>
Cc: Thorsten Leemhuis <regressions@leemhuis.info>
Cc: Shenghao Ding <shenghao-ding@ti.com>
Cc: Kevin Lu <kevin-lu@ti.com>
Cc: Baojun Xu <baojun.xu@ti.com>
Cc: Sen Wang <sen@ti.com> 
---
 sound/hda/codecs/side-codecs/tas2781_hda.c | 27 ++++++++++++++++++++++++++-
 1 file changed, 26 insertions(+), 1 deletion(-)

diff --git a/sound/hda/codecs/side-codecs/tas2781_hda.c b/sound/hda/codecs/side-codecs/tas2781_hda.c
index e0da299df780..9162173ccb10 100644
--- a/sound/hda/codecs/side-codecs/tas2781_hda.c
+++ b/sound/hda/codecs/side-codecs/tas2781_hda.c
@@ -50,6 +50,31 @@ static void cali_cnv(unsigned char *data, unsigned int base, int offset)
 		(u32 *)&reg_data, TASDEV_CALIB_N);
 }
 
+/*
+ * V1 data without CRC is only trusted if every expected device has a
+ * populated, self-consistent entry: R0 (Q27) * 1/R0 (Q31) must be
+ * close to 1.0 in Q58.
+ */
+static bool tas2781_v1_nocrc_valid(const unsigned int *v, int ndev)
+{
+	const u64 one = 1ULL << 58;
+	int i;
+
+	if (ndev <= 0 || ndev > 4)
+		return false;
+
+	for (i = 0; i < ndev; i++) {
+		const unsigned int *e = &v[i * 5];
+		u64 prod = (u64)e[0] * e[1];
+
+		if (!e[0] || !e[1] ||
+		    prod < one - one / 10 || prod > one + one / 10)
+			return false;
+	}
+
+	return true;
+}
+
 static void tas2781_apply_calib(struct tasdevice_priv *p)
 {
 	struct calidata *cali_data = &p->cali_data;
@@ -145,7 +170,7 @@ static void tas2781_apply_calib(struct tasdevice_priv *p)
 			 * but leave TimeStamp and CRC zeroed.
 			 */
 			if (!tmp_val[20] && !tmp_val[21] &&
-			    tmp_val[0] && tmp_val[1]) {
+			    tas2781_v1_nocrc_valid(tmp_val, p->ndev)) {
 				dev_warn(p->dev,
 					 "%s: V1 data without CRC, accepting\n",
 					 __func__);

---
base-commit: d73cab4a427f924efd5b5d8769c80e0ca5bdcadf
change-id: 20261103-tas2781-v1-nocrc-fix-cecb33deea8f

Best regards,
-- 
Mohamed Yassine Jebabli <med.jebabli@gmail.com>

