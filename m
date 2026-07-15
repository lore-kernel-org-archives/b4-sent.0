From: Haidar Lee <haidar.lee@adlinktech.com>
Subject: [PATCH 0/2] ASoC: tas2562: fix Digital Volume Control
Date: Wed, 15 Jul 2026 14:04:39 +0800
Message-Id: <20260715-tas2562-dvc-fix-v1-0-072b13901b20@adlinktech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPciV2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0NT3ZLEYiNTMyPdlLJk3bTMCl0zU7M0E9NkExNLIyMloK6ColSgMNj
 E6FgIv7g0KSs1uQRkjFJtLQBWZWaZcwAAAA==
X-Change-ID: 20260715-tas2562-dvc-fix-656f45c44922
To: Shenghao Ding <shenghao-ding@ti.com>, Kevin Lu <kevin-lu@ti.com>, 
 Baojun Xu <baojun.xu@ti.com>, Sen Wang <sen@ti.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Dan Murphy <dmurphy@ti.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Haidar Lee <haidar.lee@adlinktech.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784095481; l=1287;
 i=haidar.lee@adlinktech.com; s=20260715; h=from:subject:message-id;
 bh=Su3y5H+XropravPSwjmbGLXz02SfJzDuKDVzb682+LY=;
 b=8ZNmVGCGjs4EH4nTMnEyEGiWmeRhO/0vN23LgLkWVjqJu3F6zGPyjoWLlBzgml3PMA/6HdQmU
 /May/zpWfATAC9uFoAweyiiWt+CS8Kj2JTHOg+t8J9MJvqWbHIqQfjw
X-Developer-Key: i=haidar.lee@adlinktech.com; a=ed25519;
 pk=p37KzVgRl0a8om8VCM7iEwQvNuZz2fxL4lBCBp5qrno=
X-Endpoint-Received: by B4 Relay for haidar.lee@adlinktech.com/20260715 with auth_id=872
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 'Digital Volume Control' added in v5.7 has never worked correctly:
the driver writes the 32-bit DVC coefficient LSB first, but the device
latches the whole coefficient on the write to the last byte (DVC_CFG4),
so every volume change applies a mix of the previous coefficient's
upper bytes and the new LSB. Depending on the sequence of values this
mutes the output entirely or plays at full volume regardless of the
requested level.

Debugged on a TAS2562 (ADLINK OSM-520 / MT8189): traced the I2C writes
with ftrace to confirm the driver writes the intended bytes, then
reproduced both behaviours by writing the same coefficients manually in
each byte order. Patch 1 fixes the write order; patch 2 fixes two wrong
entries in the volume lookup table found while debugging this.

Signed-off-by: Haidar Lee <haidar.lee@adlinktech.com>
---
Haidar Lee (2):
      ASoC: tas2562: fix DVC coefficient write order
      ASoC: tas2562: fix broken entries in the volume lookup table

 sound/soc/codecs/tas2562.c | 30 +++++++++++++++++++-----------
 1 file changed, 19 insertions(+), 11 deletions(-)
---
base-commit: 58717b2a1365d06c8c64b72aa948541b53fe31eb
change-id: 20260715-tas2562-dvc-fix-656f45c44922

Best regards,
--  
Haidar Lee <haidar.lee@adlinktech.com>

