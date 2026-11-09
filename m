From: Ivan Verbovoy <ivanverbovoy@gmail.com>
Date: Tue, 10 Nov 2026 00:33:18 +0200
Subject: [PATCH] ASoC: codecs: wcd934x: drop the MCLK on every disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-wcd934x-mclk-v1-1-c62956792a3f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNL3fLkFEtjkwrd3OScbF0jQyPDtEQDE3Njw0QloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loAfQOIoHAAAAA=
X-Change-ID: 20261109-wcd934x-mclk-2121fa04731a
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ivan Verbovoy <ivanverbovoy@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794263597; l=2005;
 i=ivanverbovoy@gmail.com; s=20261103; h=from:subject:message-id;
 bh=+8TND5x7ORkQtuZzYM2DXIkWaXwiQXUX8dcdq40ah4g=;
 b=V/UsTHBZK8oO3woRtBITahsylO2KUvicFIWJMfYn5kV/n4IV0n56VyK40mVg/z7b3hwiZ28Zx
 K4UZcPd8YKCCsPfvgfqYObjxUt6SPl1t2VHew7/ftVgIE6t+sYIi+iI
X-Developer-Key: i=ivanverbovoy@gmail.com; a=ed25519;
 pk=0AchqTH1hJFToIUeFfQRlVzzuaWQDs4e75SxT2y3s8c=
X-Endpoint-Received: by B4 Relay for ivanverbovoy@gmail.com/20261103 with auth_id=1396
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__wcd934x_cdc_mclk_enable() takes a reference on every enable: it
prepares and enables the external clock and counts a user of the
analog bias and system clock (sysclk_users). On disable it returns
early while the SoundWire controller's clock is enabled, so neither is
dropped. Each DAPM MCLK power-down or MBHC micbias release during
SoundWire activity therefore leaks one reference, and the MCLK stays on
for good.

The early return is not needed: wcd934x_swrm_clock() takes its own
reference before it enables the SoundWire clock and clears that clock
before it drops the reference, and sysclk_users keeps the bias and the
system clock on while any user remains. Drop the check.

On a Surface Duo (SM8150, WCD9340) the codec's external clock,
ln_bb_clk2 (an RPMh XO buffer vote), was found prepared five times at
suspend, which kept the SoC's XO on. With the check dropped, its enable
and prepare counts are back to zero once playback stops.

Fixes: a61f3b4f476e ("ASoC: wcd934x: add support to wcd9340/wcd9341 codec")
Signed-off-by: Ivan Verbovoy <ivanverbovoy@gmail.com>
---
 sound/soc/codecs/wcd934x.c | 9 ---------
 1 file changed, 9 deletions(-)

diff --git a/sound/soc/codecs/wcd934x.c b/sound/soc/codecs/wcd934x.c
index 5cd30a5ed69c..043061558225 100644
--- a/sound/soc/codecs/wcd934x.c
+++ b/sound/soc/codecs/wcd934x.c
@@ -1355,15 +1355,6 @@ static int __wcd934x_cdc_mclk_enable(struct wcd934x_codec *wcd, bool enable)
 		}
 		ret = wcd934x_enable_ana_bias_and_sysclk(wcd);
 	} else {
-		int val;
-
-		regmap_read(wcd->regmap, WCD934X_CDC_CLK_RST_CTRL_SWR_CONTROL,
-			    &val);
-
-		/* Don't disable clock if soundwire using it.*/
-		if (val & WCD934X_CDC_SWR_CLK_EN_MASK)
-			return 0;
-
 		wcd934x_disable_ana_bias_and_syclk(wcd);
 		clk_disable_unprepare(wcd->extclk);
 	}

---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261109-wcd934x-mclk-2121fa04731a

Best regards,
--  
Ivan Verbovoy <ivanverbovoy@gmail.com>

