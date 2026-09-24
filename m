From: Shuming Fan <shumingf@realtek.com>
Date: Thu, 24 Sep 2026 13:53:04 +0800
Subject: [PATCH v2 3/3] ASoC: rt766: avoid re-initialize the blind write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-rt766-v2-3-e0b63606a5e8@realtek.com>
References: <20260924-rt766-v2-0-e0b63606a5e8@realtek.com>
In-Reply-To: <20260924-rt766-v2-0-e0b63606a5e8@realtek.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: Shuming Fan <shumingf@realtek.com>, derek.fang@realtek.com, 
 lars@metafoo.de, oder_chiou@realtek.com, linux-sound@vger.kernel.org, 
 flove@realtek.com, jack.yu@realtek.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790229204; l=1067;
 i=shumingf@realtek.com; s=20260924; h=from:subject:message-id;
 bh=tQ2FOA/6GWrh2SH94ZVcLZfCLdZZ79jcuuA1pM9To2I=;
 b=5SDniIARGHMY1zbNIImS30tdDLw7oz0KjmXZK6EyjXJNYHIBSXaG/asmDRehqqFalC75KntRN
 GXLLV8/ljfiDkiRIm7tBR514k92PcaH004bniOHFqJURH92meXvhHrp
X-Developer-Key: i=shumingf@realtek.com; a=ed25519;
 pk=ZM8Pg7tEJ0SDXQeBw6SfvcYyqXU9nF88DuTyxzf9utE=
X-Endpoint-Received: by B4 Relay for shumingf@realtek.com/20260924 with auth_id=1053
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We only need to check the function_status to determine
whether the system has undergone a cold or warm reboot.

Signed-off-by: Shuming Fan <shumingf@realtek.com>
---
 sound/soc/codecs/rt766-sdca.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/codecs/rt766-sdca.c b/sound/soc/codecs/rt766-sdca.c
index 5a1c1e10e6d7..28b4118e05c9 100644
--- a/sound/soc/codecs/rt766-sdca.c
+++ b/sound/soc/codecs/rt766-sdca.c
@@ -1297,7 +1297,7 @@ static int rt766_func_initialize(struct rt766_sdca_priv *rt766, struct sdca_func
 	regmap_read(rt766->regmap, func_status_reg, &func_status);
 	dev_dbg(dev, "%s, %s func_status=0x%x\n", __func__, func_data->desc->name, func_status);
 
-	if ((func_status & SDCA_CTL_ENTITY_0_FUNCTION_NEEDS_INITIALIZATION) || (!rt766->first_hw_init)) {
+	if ((func_status & SDCA_CTL_ENTITY_0_FUNCTION_NEEDS_INITIALIZATION)) {
 		ret = sdca_regmap_write_init(dev, rt766->regmap, func_data);
 		if (ret) {
 			dev_err(dev, "%s initialization table update failed\n", func_data->desc->name);

-- 
2.55.0

