From: Haidar Lee <haidar.lee@adlinktech.com>
Date: Wed, 15 Jul 2026 14:04:40 +0800
Subject: [PATCH 1/2] ASoC: tas2562: fix DVC coefficient write order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-tas2562-dvc-fix-v1-1-072b13901b20@adlinktech.com>
References: <20260715-tas2562-dvc-fix-v1-0-072b13901b20@adlinktech.com>
In-Reply-To: <20260715-tas2562-dvc-fix-v1-0-072b13901b20@adlinktech.com>
To: Shenghao Ding <shenghao-ding@ti.com>, Kevin Lu <kevin-lu@ti.com>, 
 Baojun Xu <baojun.xu@ti.com>, Sen Wang <sen@ti.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Dan Murphy <dmurphy@ti.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Haidar Lee <haidar.lee@adlinktech.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784095481; l=2928;
 i=haidar.lee@adlinktech.com; s=20260715; h=from:subject:message-id;
 bh=NrDARQuuRTnNObQOb1pPNHaoWGmUellYTb5N5X9Elwo=;
 b=Jojabzbyv2lFEZ+hhb+FNhvvFy6aGlg1FWjgRUKsynbkhjiuLUXTy09CvpQAQFY8xgCKVnmSm
 Q2E7sIt6QfkC/9HXXYyFL1aXKW+yliFQZNA4kFu7bWAhrtCh+aSTr38
X-Developer-Key: i=haidar.lee@adlinktech.com; a=ed25519;
 pk=p37KzVgRl0a8om8VCM7iEwQvNuZz2fxL4lBCBp5qrno=
X-Endpoint-Received: by B4 Relay for haidar.lee@adlinktech.com/20260715 with auth_id=872
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TAS2562 applies the 32-bit digital volume coefficient to the
playback path when the last byte, DVC_CFG4 (book 0 page 2 reg 0x0F), is
written. tas2562_volume_control_put() wrote DVC_CFG4 first and DVC_CFG1
(the MSB) last, so every volume change latched a value made of the
previous coefficient's upper three bytes combined with the new LSB; the
remaining bytes only took effect on the next volume change.

In practice the control was unusable: the first setting after power-on
always played at roughly 0 dB no matter what value was requested (the
chip's default upper bytes were still latched), and most subsequent
changes muted the output entirely or produced a distorted, over-unity
gain.

Verified on a TAS2562 (ADLINK OSM-520 / MT8189 board) by tracing the
I2C writes with ftrace and by writing the same coefficients manually in
both byte orders: written MSB-first the register block behaves exactly
as the driver expects, LSB-first reproduces the broken behaviour.

Write the bytes MSB first with DVC_CFG4 last so the complete new
coefficient is latched atomically.

Fixes: bf726b1c86f2 ("ASoC: tas2562: Add support for digital volume control")
Cc: stable@vger.kernel.org
Signed-off-by: Haidar Lee <haidar.lee@adlinktech.com>
---
 sound/soc/codecs/tas2562.c | 23 +++++++++++++++--------
 1 file changed, 15 insertions(+), 8 deletions(-)

diff --git a/sound/soc/codecs/tas2562.c b/sound/soc/codecs/tas2562.c
index e1d62f30418a..ec32ef0afd7e 100644
--- a/sound/soc/codecs/tas2562.c
+++ b/sound/soc/codecs/tas2562.c
@@ -475,20 +475,27 @@ static int tas2562_volume_control_put(struct snd_kcontrol *kcontrol,
 	u32 reg_val;
 
 	reg_val = float_vol_db_lookup[ucontrol->value.integer.value[0]/2];
-	ret = snd_soc_component_write(component, TAS2562_DVC_CFG4,
-				      (reg_val & 0xff));
-	if (ret)
-		return ret;
-	ret = snd_soc_component_write(component, TAS2562_DVC_CFG3,
-				      ((reg_val >> 8) & 0xff));
+	/*
+	 * The device applies the 32-bit coefficient to the playback path on
+	 * the write to DVC_CFG4 (the LSB, book 0 page 2 reg 0x0F), so the
+	 * bytes must be written MSB first and DVC_CFG4 last. Writing CFG4
+	 * first latches a mix of the previous coefficient's upper bytes and
+	 * the new LSB instead of the requested value.
+	 */
+	ret = snd_soc_component_write(component, TAS2562_DVC_CFG1,
+				      ((reg_val >> 24) & 0xff));
 	if (ret)
 		return ret;
 	ret = snd_soc_component_write(component, TAS2562_DVC_CFG2,
 				      ((reg_val >> 16) & 0xff));
 	if (ret)
 		return ret;
-	ret = snd_soc_component_write(component, TAS2562_DVC_CFG1,
-				      ((reg_val >> 24) & 0xff));
+	ret = snd_soc_component_write(component, TAS2562_DVC_CFG3,
+				      ((reg_val >> 8) & 0xff));
+	if (ret)
+		return ret;
+	ret = snd_soc_component_write(component, TAS2562_DVC_CFG4,
+				      (reg_val & 0xff));
 	if (ret)
 		return ret;
 

-- 
2.34.1

