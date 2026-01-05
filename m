From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 04:02:09 +0100
Subject: [PATCH RESEND 2/4] ASoC: wm8962: Don't disable SYSCLK if it's
 enabled via DAPM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-wm8962-l5-fixes-v1-2-f4f4eeacf089@puri.sm>
References: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
In-Reply-To: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: patches@opensource.cirrus.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel@puri.sm, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1081;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=zi9x3EPPEK4Yh40bqI+3+mLaNvPm7zKYWzZHed95l70=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpWym6PnwEVZ9Qtq8KimokKQk+8unH/eXMqoTqA
 B15OHY4o6+JAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVspugAKCRDo8jXPO9vD
 /0dYEACIX5JzcG+olaDmbJpsvi2Ub2/q3G3+k5Iu7PrAJjK+nSAVYCAti7yyyb0Zx9UwFB2t+k3
 ZMAMQmdz2jW02WDxzN6vySrjtD42PAVAim6VWOgREVggF22sJNrzWQL4FqGyrfmNuGE82krvzgX
 5OldYSUVQAuvN9sKj4++X0MSNGxywGpaUArGWYS15rBG2piecnj5V2r1QWUqm3p97DeSnkWRC7T
 qJugYYeKj+aTi3QZDFw2lHvLJY4MQBbQj0ut4Vo9dOXLF0ZVzagk4IOq+Zw9JZ4HubgNbhR0pZv
 6JR5x8I/pI9wXysFlQc9Gdc+udCLaGIQcojrlwrf9WJ/3JsLafPv9u+CcnEp5px3h7u6axOk6yp
 MR3GmLAIcbnsARKPU8jp4JbgrwiqF6rWKnvqzlFNUqnsaJoPhhGDte5z2/7AicdLBmEUYzSTpfP
 Sr0ufgO7x3kjJcLYC3pymCusxlO24M8/0K02C3CZbi2HEMEXipEKEDgeciMsFF331UlbCcMt4WZ
 xpHq5ILUYF/UomB95ioSAEhJg2bJAsrhzGTYZMdIGQEiReQyu+fz1HU6PJ294OIgy7WcSiUvcpe
 IUZOEgNp6lyERBs7OXfE115HL3ix5NUameDMPjRIM3pvMFyDIsrXaYQX1qIh/5SZYo/p6FENOY/
 7H6hCghmIPetgdw==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If SYSCLK pin is enabled via DAPM, wm8962_configure_bclk may turn it off
behind DAPM's back, making it assume that the clock is still enabled even
if it actually isn't, which can end up with it not being enabled for
playback or capture when it's needed.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 sound/soc/codecs/wm8962.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/sound/soc/codecs/wm8962.c b/sound/soc/codecs/wm8962.c
index 1040740fc80f..843b8c6b40a4 100644
--- a/sound/soc/codecs/wm8962.c
+++ b/sound/soc/codecs/wm8962.c
@@ -2520,7 +2520,8 @@ static void wm8962_configure_bclk(struct snd_soc_component *component)
 	usleep_range(500, 1000);
 	dspclk = snd_soc_component_read(component, WM8962_CLOCKING1);
 
-	if (snd_soc_dapm_get_bias_level(dapm) != SND_SOC_BIAS_ON)
+	if (snd_soc_dapm_get_bias_level(dapm) != SND_SOC_BIAS_ON
+	    && !snd_soc_dapm_get_pin_status(dapm, "SYSCLK"))
 		snd_soc_component_update_bits(component, WM8962_CLOCKING2,
 				WM8962_SYSCLK_ENA_MASK, 0);
 

-- 
2.52.0

