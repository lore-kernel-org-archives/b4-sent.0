From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 28 Apr 2026 18:02:16 +0100
Subject: [PATCH v3 01/11] iio: dac: ad5686: fix ref bit initialization for
 single-channel parts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-ad5686-fixes-v3-1-9cff7bd67a15@analog.com>
References: <20260428-ad5686-fixes-v3-0-9cff7bd67a15@analog.com>
In-Reply-To: <20260428-ad5686-fixes-v3-0-9cff7bd67a15@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stefan Popa <stefan.popa@analog.com>, Jonathan Cameron <jic23@cam.ac.uk>, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 Michael Auchter <michael.auchter@ni.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777395737; l=1785;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Nconrz7dK97kTaVAe2gd8GJ1K9ckwdIVrWzVZiHhK/A=;
 b=MVAnyZdg6ffA2JMYIaahewQ/h8qr1iLw1tkGlLl88y14KGgLexsjSRojXFdLbpylDaFfUrcIK
 QtMYX1WIbc8BYdrgxpJWqMxmmogrFcSk5r/vjrQJv8oFEeftPe7kl1J
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reference bit position was ignored when writing the register at the
probe() function (!!val was used). When such bit is 1, internal voltage
reference is disabled so that an external one can be used. For
multi-channel devices, bit 0 of the Internal Reference Setup command
behaves the same way, so AD5686_REF_BIT_MSK is created. The issue exists
since support for single-channel devices were first introduced.

Fixes: be1b24d24541 ("iio:dac:ad5686: Add AD5691R/AD5692R/AD5693/AD5693R support")
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 6 +++---
 drivers/iio/dac/ad5686.h | 1 +
 2 files changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 9a384c50929b..1fc54c38b629 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -511,7 +511,7 @@ int ad5686_probe(struct device *dev,
 		break;
 	case AD5686_REGMAP:
 		cmd = AD5686_CMD_INTERNAL_REFER_SETUP;
-		ref_bit_msk = 0;
+		ref_bit_msk = AD5686_REF_BIT_MSK;
 		break;
 	case AD5693_REGMAP:
 		cmd = AD5686_CMD_CONTROL_REG;
@@ -522,9 +522,9 @@ int ad5686_probe(struct device *dev,
 		return -EINVAL;
 	}
 
-	val = (has_external_vref | ref_bit_msk);
+	val = has_external_vref ? ref_bit_msk : 0;
 
-	ret = st->write(st, cmd, 0, !!val);
+	ret = st->write(st, cmd, 0, val);
 	if (ret)
 		return ret;
 
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index e7d36bae3e59..36e16c5c4581 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -46,6 +46,7 @@
 
 #define AD5310_REF_BIT_MSK			BIT(8)
 #define AD5683_REF_BIT_MSK			BIT(12)
+#define AD5686_REF_BIT_MSK			BIT(0)
 #define AD5693_REF_BIT_MSK			BIT(12)
 
 /**

-- 
2.43.0

