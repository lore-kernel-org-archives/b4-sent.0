From: Sven Peter <sven@kernel.org>
Date: Thu, 12 Jun 2025 21:11:27 +0000
Subject: [PATCH 03/11] clk: apple-nco: Drop default ARCH_APPLE in Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250612-apple-kconfig-defconfig-v1-3-0e6f9cb512c1@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=986; i=sven@kernel.org;
 h=from:subject:message-id; bh=/FOvHL4JoMW59flXeN8dYOocFIaMHLLAYyfKjZ5n94I=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4a306Q4L2fzPrPu0KMm66q9vrjfcTsSv2dnxWFfleKmF
 tnzpXYdpSwMYhwMsmKKLNv325s+efhGcOmmS+9h5rAygQxh4OIUgIkoajEyrL1kd7lz5asWXk4N
 rwfitxTVZobZLD506GTIw/mSsuH9Exj+5z094fuhjFeg8LaiolDTXumOMpO4NYcmL5+62iNA47M
 NEwA=
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
 drivers/clk/Kconfig | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 19c1ed280fd7f6958a4144975337abe1728e1e85..561fbc9eef2d82133cab0f165c6c55c5e6ab7fdd 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -61,7 +61,6 @@ config LMK04832
 config COMMON_CLK_APPLE_NCO
 	tristate "Clock driver for Apple SoC NCOs"
 	depends on ARCH_APPLE || COMPILE_TEST
-	default ARCH_APPLE
 	help
 	  This driver supports NCO (Numerically Controlled Oscillator) blocks
 	  found on Apple SoCs such as t8103 (M1). The blocks are typically

-- 
2.34.1

