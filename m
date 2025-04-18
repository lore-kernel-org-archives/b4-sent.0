From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Fri, 18 Apr 2025 22:22:04 +0200
Subject: [PATCH] ASoC: wm8998: Add Kconfig prompt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250418-wm8998-v1-1-21c4bead9cd8@apitzsch.eu>
X-B4-Tracking: v=1; b=H4sIAGu0AmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0ML3fJcC0tLC92U1LTEVHPjJGNjIwMloOKCotS0zAqwQdGxtbUA6EN
 tIlgAAAA=
X-Change-ID: 20250418-wm8998-defae73b3320
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745008121; l=825;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=XALZ1vwO3j84k8/8tKGcIPipHuf/haqg80zA+h6cAEU=;
 b=m8KI2nZB1kokmZ/pFqGBnA6F17BLosVjzj+zt8/Fxvr5ikwtcS6hhTZ9VNWofL/DBsr+Z9pn9
 AKqhs4dg9EUB/RRqdR4kFtSE1UMbEZ61MK8g3lgZcSkBX0Mu5cw9Dnh
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add tristate prompt to allow codec selection.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 sound/soc/codecs/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/codecs/Kconfig b/sound/soc/codecs/Kconfig
index 40bb7a1d44bcfa4c386f2eba0f475efeeedf1bdb..9ecc4bb7f75ff9fce87970d2e46ace72444e55b4 100644
--- a/sound/soc/codecs/Kconfig
+++ b/sound/soc/codecs/Kconfig
@@ -2479,7 +2479,7 @@ config SND_SOC_WM8997
 	depends on MFD_WM8997 && MFD_ARIZONA
 
 config SND_SOC_WM8998
-	tristate
+	tristate "Wolfson Microelectronics WM8998 codec driver"
 	depends on MFD_WM8998 && MFD_ARIZONA
 
 config SND_SOC_WM9081

---
base-commit: 7e74f756f5f643148ca5537bf2fee6767e4b0ed9
change-id: 20250418-wm8998-defae73b3320

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

