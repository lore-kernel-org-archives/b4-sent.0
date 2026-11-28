From: Igor Velkov <iav@iav.lv>
Date: Sat, 28 Nov 2026 03:06:46 +0200
Subject: [PATCH] ASoC: rk817: Do not free the regmap of the parent PMIC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-rk817-keep-parent-regmap-v1-1-de515c2899ed@iav.lv>
X-B4-Tracking: v=1; b=H4sIACUpCmsC/x3MQQqDMBBG4avIrB1oorXRq4iLaH/tIMYwKUUQ7
 27o8lu8d1KCChJ1xUmKnyTZQ4YpC5o+PixgeWeTfdjGGOtYV2devAKRo1eELyuWzUeunrV3YzO
 1s2sp51Exy/Ff98N13VMNwg9qAAAA
To: Mark Brown <broonie@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>
Cc: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Chris Morgan <macromorgan@hotmail.com>, Lee Jones <lee@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 linux-sound@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1879; i=iav@iav.lv;
 h=from:subject:message-id; bh=VRMDAVdATty+o32CLZkZxbTwRbwASeEGt2T/3vL6z4Y=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNlcmmq6V7Y55yq95pH6bOB2/VrVltPnfaJua2g0RRyyE
 D6121Gho5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAEwkIp2R4dIPw4sGhl26lcrR
 32RUZiZcjEratrHA33P2tYfBf8Q4VjEyPPl6Us76z0XbCZVexY9jhAs/tPUek+ezWvE6qvmp05+
 jDAA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The codec uses the regmap of its RK817/RK809 PMIC parent, which the
PMIC core, RTC and regulator drivers use too. rk817_remove() calls
snd_soc_component_exit_regmap(), so removing the component, on a card
unbind or a failed bind, runs regmap_exit() on that shared regmap. The
other users are left with a freed regmap, and devm runs regmap_exit()
on it again when the PMIC goes away.

Clear the pointer instead, as commit 6d66c5ccf5cb ("ASoC: mediatek:
mt6359: Fix unexpected error in bind/unbind flow") does for mt6359.

On an ODROID-M1 (RK3568, RK809) the PMIC regmap (3-0020) disappears
from debugfs after unbinding the card, and a later hybrid sleep oopsed
in regmap_update_bits_base() called from rk808_rtc_readtime(). With
this change the regmap stays, the RTC reads and binding the card again
works.

Fixes: 0d6a04da9b25 ("ASoC: Add Rockchip rk817 audio CODEC support")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
mt6660 has a similar issue: mt6660_component_remove() calls
snd_soc_component_exit_regmap() on a regmap created with
devm_regmap_init(). Not tested, I have no such hardware.
---
 sound/soc/codecs/rk817_codec.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/codecs/rk817_codec.c b/sound/soc/codecs/rk817_codec.c
index 2c0fe1dfd842..c7804b2b559c 100644
--- a/sound/soc/codecs/rk817_codec.c
+++ b/sound/soc/codecs/rk817_codec.c
@@ -434,7 +434,7 @@ static int rk817_probe(struct snd_soc_component *component)
 
 static void rk817_remove(struct snd_soc_component *component)
 {
-	snd_soc_component_exit_regmap(component);
+	component->regmap = NULL;
 }
 
 static const struct snd_soc_component_driver soc_codec_dev_rk817 = {

---
base-commit: a6c7e545d8abac8ad0b48da4c8b4ca5ef8ea8eda
change-id: 20261128-rk817-keep-parent-regmap-354a8b6c9f89

Best regards,
-- 
Igor Velkov <iav@iav.lv>

