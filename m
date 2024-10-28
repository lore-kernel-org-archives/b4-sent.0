From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 28 Oct 2024 16:43:38 +0100
Subject: [PATCH v2 1/4] ASoC: codecs: adau1373: add some kconfig text
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241028-adau1373-shutdown-v2-1-647f56bbd182@analog.com>
References: <20241028-adau1373-shutdown-v2-0-647f56bbd182@analog.com>
In-Reply-To: <20241028-adau1373-shutdown-v2-0-647f56bbd182@analog.com>
To: linux-sound@vger.kernel.org, devicetree@vger.kernel.org
Cc: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730130219; l=634;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=N9cgwu1zwzbWD0Fw9Jji5tH1Q286lBcXZ7unQPQVoMc=;
 b=bZajh8COAzo3ueYiEtpERuzBybdCOmSlIp7naGoorXVvjZd5C+Z9EVkceVvWEnCoBCxzxY6qN
 gJc9NwNPJasCuRral1nBov4XDCHfkC/b6/3y99gxIDYXKOwezGuTFkG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some text to 'tristate' so that we can actually enable the driver
when using things like menuconfig.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 sound/soc/codecs/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/codecs/Kconfig b/sound/soc/codecs/Kconfig
index 6a6125e94d2d..72643907cef7 100644
--- a/sound/soc/codecs/Kconfig
+++ b/sound/soc/codecs/Kconfig
@@ -464,7 +464,7 @@ config SND_SOC_ADAU1372_SPI
 	select REGMAP_SPI
 
 config SND_SOC_ADAU1373
-	tristate
+	tristate "Analog Devices ADAU1373 CODEC"
 	depends on I2C
 	select SND_SOC_ADAU_UTILS
 

-- 
2.47.0

