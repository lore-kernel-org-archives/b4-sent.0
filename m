From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 03 Nov 2026 18:32:09 +0200
Subject: [PATCH 3/3] iio: adc: mt6359-auxadc: fix scale calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-6768-6358-fixes-v1-3-2a868a33152b@protonmail.com>
References: <20261103-6768-6358-fixes-v1-0-2a868a33152b@protonmail.com>
In-Reply-To: <20261103-6768-6358-fixes-v1-0-2a868a33152b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793723743; l=1136;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=R/Vgi/Hmv+iUny8kYvdB+lQ+e0rpx+YnD5NeeGn0NQU=;
 b=Ezy6TSOcsGzfCu0rU7JGw9B0yFsyUBQrW5l7OFzfA2ilmV3BjvHHzojotw8pFI/KqAKTiz55m
 i9/lIENPNMJDO6inOzG1kNoU/VraL7W4N9bCNfNqMKxXsgfsqzYDIDU
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IIO_CHAN_INFO_SCALE currently returns value without dividing by
2^realbits, overflowing the integer to an invalid value.

Fix this by using IIO_VAL_FRACTIONAL and setting val2 to the ADC
resolution.

Fixes: 3587914bf61d ("iio: adc: Add support for MediaTek MT6357/8/9 Auxiliary ADC")
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/iio/adc/mt6359-auxadc.c | 8 ++------
 1 file changed, 2 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/adc/mt6359-auxadc.c b/drivers/iio/adc/mt6359-auxadc.c
index 09432d0974cf..3a969c30f633 100644
--- a/drivers/iio/adc/mt6359-auxadc.c
+++ b/drivers/iio/adc/mt6359-auxadc.c
@@ -770,13 +770,9 @@ static int mt6359_auxadc_read_raw(struct iio_dev *indio_dev,
 
 	if (mask == IIO_CHAN_INFO_SCALE) {
 		*val = desc->r_ratio.numerator * cinfo->vref_mV;
+		*val2 = desc->r_ratio.denominator << chan->scan_type.realbits;
 
-		if (desc->r_ratio.denominator > 1) {
-			*val2 = desc->r_ratio.denominator;
-			return IIO_VAL_FRACTIONAL;
-		}
-
-		return IIO_VAL_INT;
+		return IIO_VAL_FRACTIONAL;
 	}
 
 	scoped_guard(mutex, &adc_dev->lock) {

-- 
2.56.0

