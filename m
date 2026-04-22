From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:47 +0100
Subject: [PATCH 13/22] iio: dac: ad5686: fix input raw value check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-13-ed7dca001d1b@analog.com>
References: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
In-Reply-To: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
To: Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Auchter <michael.auchter@ni.com>, linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=852;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=f6PzyqSsWxOZZP4d7ht2aA8eC0y4w+JduFiMQSa6zy8=;
 b=2zDSyBy3PiTZVEfheySnluorFvGYtbMC503N7GbMqpmFI4Jm1nUdvB3I0thMUFSWM83HzqcPR
 NgfzkzxSvc8Bm+dugDpgBA2e98CPjy2VtBOwH6QPUNsVoKE+kSQZMgm
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use in_range() to fix range check for input raw value, which is off by
one, i.e., for a 10-bit DAC the max valid value is 1023, but 1 << 10
equals 1024, which passes the previous check, allowing an out-of-range
write.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 19d791c655b7..07a944311f0e 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -185,7 +185,7 @@ static int ad5686_write_raw(struct iio_dev *indio_dev,
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
-		if (val > (1 << chan->scan_type.realbits) || val < 0)
+		if (!in_range(val, 0, 1 << chan->scan_type.realbits))
 			return -EINVAL;
 
 		mutex_lock(&st->lock);

-- 
2.43.0

