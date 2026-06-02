From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 02 Jun 2026 17:33:58 +0100
Subject: [PATCH 11/12] iio: dac: ad5686: write_raw: use guard(mutex)()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-ad5686-new-features-v1-11-691e01883d27@analog.com>
References: <20260602-ad5686-new-features-v1-0-691e01883d27@analog.com>
In-Reply-To: <20260602-ad5686-new-features-v1-0-691e01883d27@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780418030; l=1337;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Dsy9fOpmU3g/1YFf/mAz4rjj8yKEcDVwiot3KZLm8lo=;
 b=Z++v0ifycOhzyxjvxvLeFAeSaxTfoRkG8LMACbMzeuYcqTqw65mZ+E2ow4UJgaT+YzxnNwsSX
 LVlg0xlP/VuCspodmAggEavmNlboJdT6mbyfbOdkv1eOU7/q9/x30D7
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use guarded mutex lock to facilitate code review when adding new
attributes. This will allow for early returns, avoiding error-prone
locking and unlocking in error paths. Gain-control support will add
the scale attribute.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 14 +++++---------
 1 file changed, 5 insertions(+), 9 deletions(-)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 5052df44ab1c..54b953018cfa 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -205,23 +205,19 @@ static int ad5686_write_raw(struct iio_dev *indio_dev,
 			    long mask)
 {
 	struct ad5686_state *st = iio_priv(indio_dev);
-	int ret;
+
+	guard(mutex)(&st->lock);
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
 		if (val >= (1 << chan->scan_type.realbits) || val < 0)
 			return -EINVAL;
 
-		mutex_lock(&st->lock);
-		ret = ad5686_write(st, AD5686_CMD_WRITE_INPUT_N_UPDATE_N,
-				   chan->address, val << chan->scan_type.shift);
-		mutex_unlock(&st->lock);
-		break;
+		return ad5686_write(st, AD5686_CMD_WRITE_INPUT_N_UPDATE_N,
+				    chan->address, val << chan->scan_type.shift);
 	default:
-		ret = -EINVAL;
+		return -EINVAL;
 	}
-
-	return ret;
 }
 
 static const struct iio_info ad5686_info = {

-- 
2.43.0

