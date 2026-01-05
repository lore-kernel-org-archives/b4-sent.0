From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 04:02:08 +0100
Subject: [PATCH RESEND 1/4] ASoC: wm8962: Add WM8962_ADC_MONOMIX to "3D
 Coefficients" mask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-wm8962-l5-fixes-v1-1-f4f4eeacf089@puri.sm>
References: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
In-Reply-To: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: patches@opensource.cirrus.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel@puri.sm, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=835;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=MPPG80PySyuGNcKziBA/WqMsI63UkAvo4Yv3+TQYRJQ=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpWym6qDr2a/Q6H8GzN8+Uc8NrpWwL4yoQRAago
 asY65vMBmaJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVspugAKCRDo8jXPO9vD
 /48wD/4xoxLlmRzApRATU9ZO7YK+dFvbF7q7ENopAv7x3zwYkpwBZ4T0r9fCSqABHZqbIS2iiFf
 u/3eGWM7pGjYa27Uj0sL5fSynl90jxo2fT9kJsF2Lf1X7ZFA3Zc1Xcp/AkxooFJDbJQjCskn7g4
 2XDufdGPaLVN/dlGqnyfh1GLt/NsAGfoiCJANh9AXaNvPrpeV0alBg4YRi9wb169X1PdomfETeh
 VINk0gEAKxX7Pmoww4wxn/4K3XfyF3k+de8cTg2o517BNJxuFg9YBj1j521XeoxTtHp9YT3KjwF
 BRfOxo2zJNunGjHjcz8r6dv1Qy+nE48tnvpsDplC7HFr616cMZm/HBSrIEvO/dQfsioOOy0EfCx
 mxyFhSd132XYRHqPpqM5aZziQvrXS6utBwBeEBr8N+zpzZ9Qt+Y+NTQol8kxPYLqgFXuWyIilU+
 SnIjtqeX3wTQPlitulG04dSkw1NfZklp4jgojC2LHJ+QvhSGl9zjy3G80wyP1973Z3E4tihcqzm
 XjagFjkCbuv/1Dsr3GxU74InZwiybU5mCDPiLlgB+483t2IwwzmzIQ6kXBhWPLaGuL3UfNbnZ1I
 ZjEWa2xffOqQNmnln7++rwiypRPcM3sGVYAND13Mr9jXw6rtX1zeSJNfp/jDOrDfEcx2x2ljbbA
 PUROk8ZU+rskTlQ==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This bit is handled by a separate control.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 sound/soc/codecs/wm8962.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/codecs/wm8962.c b/sound/soc/codecs/wm8962.c
index e9e317ce6898..1040740fc80f 100644
--- a/sound/soc/codecs/wm8962.c
+++ b/sound/soc/codecs/wm8962.c
@@ -1760,7 +1760,7 @@ SND_SOC_BYTES("EQR Coefficients", WM8962_EQ24, 18),
 
 
 SOC_SINGLE("3D Switch", WM8962_THREED1, 0, 1, 0),
-SND_SOC_BYTES_MASK("3D Coefficients", WM8962_THREED1, 4, WM8962_THREED_ENA),
+SND_SOC_BYTES_MASK("3D Coefficients", WM8962_THREED1, 4, WM8962_THREED_ENA | WM8962_ADC_MONOMIX),
 
 SOC_SINGLE("DF1 Switch", WM8962_DF1, 0, 1, 0),
 SND_SOC_BYTES_MASK("DF1 Coefficients", WM8962_DF1, 7, WM8962_DF1_ENA),

-- 
2.52.0

