From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Wed, 29 Apr 2026 17:04:50 +0200
Subject: [PATCH v3 2/8] iio: light: si1133: prefer complex macros enclosed
 in parenthesis
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-si1133-checkup-v3-2-469f21d960eb@gmail.com>
References: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
In-Reply-To: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777475147; l=2245;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=C5i/c58hyZEyHBbZkt7Seo1G34DfU10pUdqQTYkoeCA=;
 b=EufXNHGRlax2ZHJHlv8WL4aa4BV5hlrrwB6Enq6d85WsOFkeSk6LZh8l3tszAHGdaWqEtTvlD
 YNKbPCIsB2gCWiwHvK5gPicEmn5jRctgd58d6yL2gZ3Vj2lsYTlI+5e
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enclose complex macros in parenthesis per checkpatch.pl error to
improve code style.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index 73b0ce21e017cd4ab6c6b280229f417763866502..136436c0379aa732a2c93d40b08734ae4fc2a45f 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -50,23 +50,23 @@
 #define SI1133_MAX_CMD_CTR		0xF
 
 #define SI1133_PARAM_REG_CHAN_LIST	0x01
-#define SI1133_PARAM_REG_ADCCONFIG(x)	((x) * 4) + 2
-#define SI1133_PARAM_REG_ADCSENS(x)	((x) * 4) + 3
-#define SI1133_PARAM_REG_ADCPOST(x)	((x) * 4) + 4
+#define SI1133_PARAM_REG_ADCCONFIG(x)	(((x) * 4) + 2)
+#define SI1133_PARAM_REG_ADCSENS(x)	(((x) * 4) + 3)
+#define SI1133_PARAM_REG_ADCPOST(x)	(((x) * 4) + 4)
 
 #define SI1133_ADCMUX_MASK 0x1F
 
-#define SI1133_ADCCONFIG_DECIM_RATE(x)	(x) << 5
+#define SI1133_ADCCONFIG_DECIM_RATE(x)	((x) << 5)
 
 #define SI1133_ADCSENS_SCALE_MASK 0x70
 #define SI1133_ADCSENS_SCALE_SHIFT 4
 #define SI1133_ADCSENS_HSIG_MASK BIT(7)
 #define SI1133_ADCSENS_HSIG_SHIFT 7
 #define SI1133_ADCSENS_HW_GAIN_MASK 0xF
-#define SI1133_ADCSENS_NB_MEAS(x)	fls(x) << SI1133_ADCSENS_SCALE_SHIFT
+#define SI1133_ADCSENS_NB_MEAS(x)	(fls(x) << SI1133_ADCSENS_SCALE_SHIFT)
 
 #define SI1133_ADCPOST_24BIT_EN BIT(6)
-#define SI1133_ADCPOST_POSTSHIFT_BITQTY(x) (x & GENMASK(2, 0)) << 3
+#define SI1133_ADCPOST_POSTSHIFT_BITQTY(x) (((x) & GENMASK(2, 0)) << 3)
 
 #define SI1133_PARAM_ADCMUX_SMALL_IR	0x0
 #define SI1133_PARAM_ADCMUX_MED_IR	0x1
@@ -87,11 +87,11 @@
 #define SI1133_CMD_MINSLEEP_US_HIGH	7500
 #define SI1133_CMD_TIMEOUT_MS		25
 
-#define SI1133_REG_HOSTOUT(x)		(x) + 0x13
+#define SI1133_REG_HOSTOUT(x)		((x) + 0x13)
 
 #define SI1133_X_ORDER_MASK            0x0070
 #define SI1133_Y_ORDER_MASK            0x0007
-#define si1133_get_x_order(m)          ((m) & SI1133_X_ORDER_MASK) >> 4
+#define si1133_get_x_order(m)          (((m) & SI1133_X_ORDER_MASK) >> 4)
 #define si1133_get_y_order(m)          ((m) & SI1133_Y_ORDER_MASK)
 
 #define SI1133_LUX_ADC_MASK		0xE

-- 
2.47.3

