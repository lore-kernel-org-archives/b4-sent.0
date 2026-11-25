From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Wed, 25 Nov 2026 08:09:30 +0000
Subject: [PATCH v2 1/3] ASoC: codecs: nau8360: set val_bits to the widest
 register size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-regmap-kunit-val-bits-v2-1-81db3b79cd3f@gmail.com>
References: <20261125-regmap-kunit-val-bits-v2-0-81db3b79cd3f@gmail.com>
In-Reply-To: <20261125-regmap-kunit-val-bits-v2-0-81db3b79cd3f@gmail.com>
To: Mark Brown <broonie@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-sound@vger.kernel.org, Neo Chang <YLCHANG2@nuvoton.com>, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795594173; l=1897;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=JtoiIZBSgQWLgUfHX+0oV8XepiuXh0sLdsFtw7Od4h8=;
 b=1pnp4emTHZHWJ/xOuImgjppfJ1X+BZki0slWTa1vwKXToTv/KnEDt60B4D9OEe45m5Bi5Nnam
 Q0GX083bRUaC2Kr63Dj1SlROLEJmAjHGuiqeZ4mDT3Er2pDwyDIZCIf
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The regmap is configured with val_bits = 16, but the two DSP registers
are 32 bits wide: nau8360_reg_write() sends four bytes for them, and the
DSP messages written with snd_soc_component_write() use all 32 bits.

This works because the driver provides its own reg_read() and
reg_write() and regmap passes the value through unmodified. As regmap is
going to mask values to val_bits, set it to 32, the size of the widest
register. The size of each access is still selected in the driver's
reg_read() and reg_write().

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 sound/soc/codecs/nau8360.c | 3 ++-
 sound/soc/codecs/nau8360.h | 3 +--
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/sound/soc/codecs/nau8360.c b/sound/soc/codecs/nau8360.c
index f0942739d7ab..d4cab3c8e29d 100644
--- a/sound/soc/codecs/nau8360.c
+++ b/sound/soc/codecs/nau8360.c
@@ -1918,7 +1918,8 @@ static int nau8360_reg_read(void *context, unsigned int reg, unsigned int *value
 
 static const struct regmap_config nau8360_regmap_config = {
 	.reg_bits = NAU8360_REG_ADDR_LEN,
-	.val_bits = NAU8360_REG_DATA_LEN,
+	/* Codec registers are 16 bits wide, DSP registers are 32 bits wide */
+	.val_bits = 32,
 
 	.max_register = NAU8360_REG_MAX,
 	.readable_reg = nau8360_readable_reg,
diff --git a/sound/soc/codecs/nau8360.h b/sound/soc/codecs/nau8360.h
index 71396747c0fa..3d9711804073 100644
--- a/sound/soc/codecs/nau8360.h
+++ b/sound/soc/codecs/nau8360.h
@@ -123,9 +123,8 @@
 #define NAU8360_RF002_DSP_COMM			0xf002
 #define NAU8360_REG_MAX				NAU8360_RF002_DSP_COMM
 
-/* 16-bit control register address, and 16-bits control register data */
+/* 16-bit control register address */
 #define NAU8360_REG_ADDR_LEN			16
-#define NAU8360_REG_DATA_LEN			16
 
 /* NAU8360_R03_CLK_CTRL0 (0x03) */
 #define NAU8360_MCLK_DIV_SFT			10

-- 
2.56.0

