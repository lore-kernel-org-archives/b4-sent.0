From: Sven Peter <sven@kernel.org>
Date: Thu, 12 Jun 2025 21:11:32 +0000
Subject: [PATCH 08/11] Input: apple_z2: Drop default ARCH_APPLE in Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250612-apple-kconfig-defconfig-v1-8-0e6f9cb512c1@kernel.org>
References: <20250612-apple-kconfig-defconfig-v1-0-0e6f9cb512c1@kernel.org>
In-Reply-To: <20250612-apple-kconfig-defconfig-v1-0-0e6f9cb512c1@kernel.org>
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Ulf Hansson <ulf.hansson@linaro.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Vinod Koul <vkoul@kernel.org>, 
 =?utf-8?q?Martin_Povi=C5=A1er?= <povik+lin@cutebit.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-i2c@vger.kernel.org, iommu@lists.linux.dev, 
 linux-input@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-sound@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=977; i=sven@kernel.org;
 h=from:subject:message-id; bh=YLmWDKsoMcAj1FZaEwVkOxK9EAmBzZd5KoPvpjLJcOY=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4a308x5ms0KdxX5tjYJ+Vj+5Z5Y0a+jEJPxyPLHDGfmt
 WoFV1d0lLIwiHEwyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACayJYDhn5p5R+rBA11SHwMi
 Nsu6Gr/++XbFTaMtTNlxm/kPzgiKFWT4719YvrYm885Mtqi0lv7rPbL+R2V+MDMtXcYevXvGWll
 LFgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the first driver for Apple Silicon was upstreamed we accidentally
included `default ARCH_APPLE` in its Kconfig which then spread to almost
every subsequent driver. As soon as ARCH_APPLE is set to y this will
pull in many drivers as built-ins which is not what we want.
Thus, drop `default ARCH_APPLE` from Kconfig.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/input/touchscreen/Kconfig | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/input/touchscreen/Kconfig b/drivers/input/touchscreen/Kconfig
index 91a2b584dab1469a3c907c0f1accfa10c4c4a3ca..196905162945d59e775c3e0bff6540a82842229a 100644
--- a/drivers/input/touchscreen/Kconfig
+++ b/drivers/input/touchscreen/Kconfig
@@ -105,7 +105,6 @@ config TOUCHSCREEN_ADC
 
 config TOUCHSCREEN_APPLE_Z2
 	tristate "Apple Z2 touchscreens"
-	default ARCH_APPLE
 	depends on SPI && (ARCH_APPLE || COMPILE_TEST)
 	help
 	  Say Y here if you have an ARM Apple device with

-- 
2.34.1

