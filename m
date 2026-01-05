From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 04:02:11 +0100
Subject: [PATCH RESEND 4/4] ASoC: wm8962: Don't mark
 WM8962_ADDITIONAL_CONTROL_4 as volatile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-wm8962-l5-fixes-v1-4-f4f4eeacf089@puri.sm>
References: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
In-Reply-To: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: patches@opensource.cirrus.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel@puri.sm, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1278;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=I+p2kXXsP7IpiWWwmySXWCxbRExD53OdyEq1epRLdsQ=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpWym6zyukpSwhSxOW50U57F8rdpbkdLRU6ieA7
 t5PJl61/lKJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVspugAKCRDo8jXPO9vD
 /4f1D/9s0sgg7mxSrEUIf2YvUONHWyv/4N2nG4mp06Pb4qKPsoTpamHNWY2loKYALWJLHaXFNMj
 gsLHwvvDzMZwMULncfIu86Hx1M90aqQBmB/4zGWYMhpJ0/0bkFUCJgz+P0z6tCuaPD9mmuWqsVN
 Om09KP1n8gWT/v01nmGLN3ftcFYd75e6dibSpgAvxMj/3PcKCXlxWnN3p4DHC+9VLTe9wP2Gp5y
 LLDLJmKDfDQcCPYBswjIuWCIFYGZG7h9FGTVcmQww+ecvEhgnwFg/LO+EK72eKnWdh/14h1tZLK
 XFEy3r1kKgaGfC7lTLofF8/NdSu9zeTN7A/OQPb+svb5JaxuDXdJfZ0dBezJvaaP0CwWyVgDoIc
 U8kLMQQD/7CZHWvEHUDYFynLDuA1XG8tGec/hPD9f0ULweI/Bh4MCmb2FT4M8sSCtf66SaeavFd
 6zaTgAbzm1BjYBUpIkGfKixMa6zB5gVDQknPDtiNTGzengWsFta8ZfyLg3jMgIX6BAqe3f27MkQ
 GI7oJ4B2+1jGjNNKFaMkNAQR8YktBogvO2yAZx2hACaC0q5iFwP+bCSJBrUSfMelZ+pdex+i5op
 ye/aWLc1JNCMndHWm+hHHHYjATgYHrCfgeAbNTBFT7aNRFJAnxsImUW1CyYoIv0eUB0Ker76+H9
 KTi4cjlgL3wfdjg==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Only some bits of that register are actually volatile, so to prevent issues
with caching let's simply bypass the cache explicitly when we access these
particular bits.

This fixes mic-cfg value not being reapplied after runtime resume.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 sound/soc/codecs/wm8962.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/sound/soc/codecs/wm8962.c b/sound/soc/codecs/wm8962.c
index dd73b4dc1b97..22101284c095 100644
--- a/sound/soc/codecs/wm8962.c
+++ b/sound/soc/codecs/wm8962.c
@@ -793,7 +793,6 @@ static bool wm8962_volatile_register(struct device *dev, unsigned int reg)
 	case WM8962_CLOCKING1:
 	case WM8962_SOFTWARE_RESET:
 	case WM8962_THERMAL_SHUTDOWN_STATUS:
-	case WM8962_ADDITIONAL_CONTROL_4:
 	case WM8962_DC_SERVO_6:
 	case WM8962_INTERRUPT_STATUS_1:
 	case WM8962_INTERRUPT_STATUS_2:
@@ -3074,7 +3073,9 @@ static void wm8962_mic_work(struct work_struct *work)
 	int irq_pol = 0;
 	int reg;
 
+	regcache_cache_bypass(wm8962->regmap, true);
 	reg = snd_soc_component_read(component, WM8962_ADDITIONAL_CONTROL_4);
+	regcache_cache_bypass(wm8962->regmap, false);
 
 	if (reg & WM8962_MICDET_STS) {
 		status |= SND_JACK_MICROPHONE;

-- 
2.52.0

