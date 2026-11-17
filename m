From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 17 Nov 2026 19:56:33 +0200
Subject: [PATCH v2 2/3] iio: adc: mt6359-auxadc: mask conversion ready bit
 in mt6358_read_imp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-6768-6358-fixes-v2-2-1ffc3c2f3c80@protonmail.com>
References: <20261117-6768-6358-fixes-v2-0-1ffc3c2f3c80@protonmail.com>
In-Reply-To: <20261117-6768-6358-fixes-v2-0-1ffc3c2f3c80@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 =?utf-8?q?N=C3=ADcolas_F=2E_R=2E_A=2E_Prado?= <nfraprado@collabora.com>
Cc: Chen-Yu Tsai <wenst@chromium.org>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794938202; l=935;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=bZjW/quYiBMjfPjx4Er0DwmCVZ9DiZQDsN1KE4x1ONc=;
 b=OusJTjkZgLVAQdFTHc5MWzls2x8KOggCi76d/hEZKW7sLdQMmQUGtc1+S5huPfcnIAGMHGrZz
 AeXtIKS1cu7DL5N75QIwAQGFGeJmi1NS9rmUiPO/OWlXCPD2UIP9KsM
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In mt6358_read_imp() the raw ADC value is returned directly without
masking out bit 15, resulting in incorrect battery voltage reporting.

Apply the mask to strip the ready bit, matching the behavior in
mt6359_auxadc_read_adc() function.

Fixes: 3587914bf61d ("iio: adc: Add support for MediaTek MT6357/8/9 Auxiliary ADC")
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/iio/adc/mt6359-auxadc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/mt6359-auxadc.c b/drivers/iio/adc/mt6359-auxadc.c
index 951d236f972b..09432d0974cf 100644
--- a/drivers/iio/adc/mt6359-auxadc.c
+++ b/drivers/iio/adc/mt6359-auxadc.c
@@ -502,7 +502,7 @@ static int mt6358_read_imp(struct mt6359_auxadc *adc_dev,
 	mt6358_stop_imp_conv(adc_dev);
 
 	if (vbat)
-		*vbat = val_v;
+		*vbat = val_v & GENMASK(chan->scan_type.realbits - 1, 0);
 	if (ibat)
 		*ibat = 0;
 

-- 
2.56.1

