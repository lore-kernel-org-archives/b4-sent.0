From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Nov 2026 16:39:54 +0000
Subject: [PATCH v4 02/12] iio: frequency: ad9910: round up FM gain scale
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-ad9910-backend-support-v4-2-fcf1ad364ed5@analog.com>
References: <20261116-ad9910-backend-support-v4-0-fcf1ad364ed5@analog.com>
In-Reply-To: <20261116-ad9910-backend-support-v4-0-fcf1ad364ed5@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794847197; l=1744;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=G3vGlTj0BTKaDzZ4Lm3Cx3xNScaDzjERpmIMz76p3fM=;
 b=GSaqdVOSuAVl7j4TvPugi/LuIchKI1Dl5DPs2/303nhlWA1MJL5JtxmLCAqK8n92XLHkfvbMH
 VLafIbN1bMaAqsOBepY3wRZ2UV2O3cbLi1KItETCO/wG/Fu//V7CthN
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The parallel port frequency scale is set through the CFR2 FM gain field,
which selects a power of two multiplier. The requested scale is converted
into a ratio against the frequency tuning word LSB and then rounded up to
a power of two, so that the resulting scale is the smallest one that is
not below the requested value.

However, the ratio itself was computed with closest rounding, so when its
fractional part is below one half, it gets rounded down before
roundup_pow_of_two() is applied. For instance, a ratio of 1.3 becomes 1,
selecting a gain of 0 instead of 1, and the applied scale ends up smaller
than the requested one.

Use mul_u64_u64_div_u64_roundup() so that the ratio is rounded up as well.

Fixes: 3647f9fe3488 ("iio: frequency: ad9910: add basic parallel port support")
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 8bc24d0b7442..680415b37b0d 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -1626,8 +1626,8 @@ static int ad9910_write_raw(struct iio_dev *indio_dev,
 			if (val < 0 || val2 < 0)
 				return -EINVAL;
 
-			tmp64 = ad9910_rational_scale((u64)val * NANO + val2, BIT_ULL(32),
-						      (u64)st->data.sysclk_freq_hz * NANO);
+			tmp64 = mul_u64_u64_div_u64_roundup((u64)val * NANO + val2, BIT_ULL(32),
+							    (u64)st->data.sysclk_freq_hz * NANO);
 			tmp64 = roundup_pow_of_two(clamp(tmp64, 1ULL, BIT_ULL(15)));
 			tmp32 = FIELD_PREP(AD9910_CFR2_FM_GAIN_MSK, ilog2(tmp64));
 			return ad9910_reg32_update(st, AD9910_REG_CFR2,

-- 
2.43.0

