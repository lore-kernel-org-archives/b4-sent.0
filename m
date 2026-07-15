From: Haidar Lee <haidar.lee@adlinktech.com>
Date: Wed, 15 Jul 2026 14:04:41 +0800
Subject: [PATCH 2/2] ASoC: tas2562: fix broken entries in the volume lookup
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-tas2562-dvc-fix-v1-2-072b13901b20@adlinktech.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784095481; l=2082;
 i=haidar.lee@adlinktech.com; s=20260715; h=from:subject:message-id;
 bh=/UoYM9/AkmbMBBJjFQcKRx8doPtiLNXUryHarALR2+U=;
 b=G9R4a9/biCE5j2qrRqzkcOOvZyDxPTIRNr79T2t0ducKc9Tt4HqtswlAC3QpdvBmk2z43C/nu
 eJYxLW4aKKpBcsCiUIBGOFhOytQrPsgYAilMEImq3LJMl9tY0+rLA2/
X-Developer-Key: i=haidar.lee@adlinktech.com; a=ed25519;
 pk=p37KzVgRl0a8om8VCM7iEwQvNuZz2fxL4lBCBp5qrno=
X-Endpoint-Received: by B4 Relay for haidar.lee@adlinktech.com/20260715 with auth_id=872
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The float_vol_db_lookup table is supposed to hold
round(10^(dB/20) * 2^30) for every 2 dB step from -110 dB to 0 dB,
which is 56 entries, but it only has 55: the -90 dB entry duplicates
the -92 dB value (0x0000695b) and the -20 dB entry (0x06666666) is
missing altogether. As a result every step between -90 dB and -22 dB
is off by 2 dB, and the control's maximum raw value of 110 indexes one
element past the end of the array.

Replace the duplicated -90 dB entry with the correct value 0x000084a3
and add the missing -20 dB entry, bringing the table to the full 56
entries so index 55 (raw value 110, 0 dB) is in range again.

Fixes: bf726b1c86f2 ("ASoC: tas2562: Add support for digital volume control")
Cc: stable@vger.kernel.org
Signed-off-by: Haidar Lee <haidar.lee@adlinktech.com>
---
 sound/soc/codecs/tas2562.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/sound/soc/codecs/tas2562.c b/sound/soc/codecs/tas2562.c
index ec32ef0afd7e..cdd695c3807e 100644
--- a/sound/soc/codecs/tas2562.c
+++ b/sound/soc/codecs/tas2562.c
@@ -32,15 +32,16 @@
 static const unsigned int float_vol_db_lookup[] = {
 0x00000d43, 0x000010b2, 0x00001505, 0x00001a67, 0x00002151,
 0x000029f1, 0x000034cd, 0x00004279, 0x000053af, 0x0000695b,
-0x0000695b, 0x0000a6fa, 0x0000d236, 0x000108a4, 0x00014d2a,
+0x000084a3, 0x0000a6fa, 0x0000d236, 0x000108a4, 0x00014d2a,
 0x0001a36e, 0x00021008, 0x000298c0, 0x000344df, 0x00041d8f,
 0x00052e5a, 0x000685c8, 0x00083621, 0x000a566d, 0x000d03a7,
 0x0010624d, 0x0014a050, 0x0019f786, 0x0020b0bc, 0x0029279d,
 0x0033cf8d, 0x004139d3, 0x00521d50, 0x00676044, 0x0082248a,
 0x00a3d70a, 0x00ce4328, 0x0103ab3d, 0x0146e75d, 0x019b8c27,
 0x02061b89, 0x028c423f, 0x03352529, 0x0409c2b0, 0x05156d68,
-0x080e9f96, 0x0a24b062, 0x0cc509ab, 0x10137987, 0x143d1362,
-0x197a967f, 0x2013739e, 0x28619ae9, 0x32d64617, 0x40000000
+0x06666666, 0x080e9f96, 0x0a24b062, 0x0cc509ab, 0x10137987,
+0x143d1362, 0x197a967f, 0x2013739e, 0x28619ae9, 0x32d64617,
+0x40000000
 };
 
 struct tas2562_data {

-- 
2.34.1

