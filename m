From: Gaurav Suman <gauravsuman007@gmail.com>
Date: Mon, 09 Nov 2026 22:33:47 +0000
Subject: [PATCH RFC] ASoC: codecs: wcd934x: keep MCLK enabled so init
 writes reach the codec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-wcd934x-mclk-v1-1-ab86342e7ead@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEpK8moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNL3fLkFEtjkwrd3OScbN2UVFPLVEMzEzMLA3MloJaCotS0zAqwcdF
 KQW7OSrG1tQDvN9SUYwAAAA==
X-Change-ID: 20261109-wcd934x-mclk-de59e1646807
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Gaurav Suman <gauravsuman007@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794263638; l=2522;
 i=gauravsuman007@gmail.com; s=default; h=from:subject:message-id;
 bh=8u46K9MtmpC/yZH7MaaIGPTHQMOfd8OqvroqTAoIDKw=;
 b=w+dOp4lUMyGty2jZoxIvNtUcRjLUY05x9zhThT6au4LkhC/wFP6g5GWXIChw8BlQKGNbG0/pF
 Er7ssv0G9cDDRWxrnPbWM27XRwHOTpM9thMIDASkQgg2xY3u+SAXMii
X-Developer-Key: i=gauravsuman007@gmail.com; a=ed25519;
 pk=lnUC0mQfc0KyA0LE73pQ4+QWYVRaCD8Sd3XWxLZO+JY=
X-Endpoint-Received: by B4 Relay for gauravsuman007@gmail.com/default with auth_id=1467
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On an LG G8x (SM8150, WCD9340 over SLIMbus) the microphones record
digital silence on roughly half of all boots. Register dumps look
correct because they are served from the regmap cache, but the
writes never reached the hardware: the WCD934x digital core ignores
register writes while its MCLK/sysclk is off.

wcd934x_comp_init() runs with MCLK off unless the SoundWire master
happened to probe first and enabled the clock through
wcd934x_swrm_clock(); __wcd934x_cdc_mclk_enable(false) then leaves it
running because the SWR clock bit is set. Probe ordering is not
deterministic, which matches the random good and bad boots.

Enable MCLK before wcd934x_comp_init() and leave it enabled, which is
what the good boots already do. With this change 8 of 8 boots had a
working microphone (before: about 3 in 5 silent).

Enabling MCLK only around wcd934x_comp_init() (and disabling it
again afterwards, as wcd934x_enable_efuse_sensing() does) was not
enough: 2 of 4 boots were silent again, so later writes made while
the clock is off are lost as well. An alternative would be to mark
the cache dirty and resync whenever MCLK goes from off to on; this
patch takes the simpler route at the cost of keeping MCLK running.

The fault was found, the change written and the boot tests run with the
help of an AI coding assistant (Claude Opus 5.5, Anthropic); I reviewed
the change and the test results.

Signed-off-by: Gaurav Suman <gauravsuman007@gmail.com>
---
Tested on LG G8x ThinQ (SM8150).
---
 sound/soc/codecs/wcd934x.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/sound/soc/codecs/wcd934x.c b/sound/soc/codecs/wcd934x.c
index 0ed24cca088f839263f015778e8281027392e51f..6b6ce5ba5d30da194db1b1570a58f0324956f96f 100644
--- a/sound/soc/codecs/wcd934x.c
+++ b/sound/soc/codecs/wcd934x.c
@@ -2995,6 +2995,12 @@ static int wcd934x_comp_probe(struct snd_soc_component *component)
 	/* Default HPH Mode to Class-H Low HiFi */
 	wcd->hph_mode = CLS_H_LOHIFI;
 
+	/*
+	 * The digital core drops register writes while MCLK is off, but the
+	 * regmap cache still records them. Keep MCLK running so the init
+	 * sequence below and later mixer/DAPM writes actually reach the codec.
+	 */
+	__wcd934x_cdc_mclk_enable(wcd, true);
 	wcd934x_comp_init(component);
 
 	for (i = 0; i < NUM_CODEC_DAIS; i++)

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261109-wcd934x-mclk-de59e1646807

Best regards,
-- 
Gaurav Suman <gauravsuman007@gmail.com>

