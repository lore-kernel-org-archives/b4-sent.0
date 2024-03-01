From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 01 Mar 2024 18:14:52 +0100
Subject: [PATCH v3 3/3] iio: temperature: ltc2983: support vdd regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240301-ltc2983-misc-improv-v3-3-c09516ac0efc@analog.com>
References: <20240301-ltc2983-misc-improv-v3-0-c09516ac0efc@analog.com>
In-Reply-To: <20240301-ltc2983-misc-improv-v3-0-c09516ac0efc@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709313291; l=908;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=2oUoUw4KkUIEscan+R7Gf4fDzMGadWsp8HmTiYX2GY8=;
 b=21Pd1s7jXIJSXO9pTvA5u5zM5BJEidLumUPfRe/q/BNROYoy6DMxN3avsGLLoW1izPTcdL3Qw
 +chTKG6yU7oBPc1HpwoteCkAzUr1tGP6nCeLApHIk0DMDZIT2ZM2mlm
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the power supply regulator.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/temperature/ltc2983.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/iio/temperature/ltc2983.c b/drivers/iio/temperature/ltc2983.c
index 592887097117..9fb547417536 100644
--- a/drivers/iio/temperature/ltc2983.c
+++ b/drivers/iio/temperature/ltc2983.c
@@ -18,6 +18,7 @@
 #include <linux/module.h>
 #include <linux/property.h>
 #include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
 #include <linux/spi/spi.h>
 
 #include <asm/byteorder.h>
@@ -1581,6 +1582,10 @@ static int ltc2983_probe(struct spi_device *spi)
 	if (ret)
 		return ret;
 
+	ret = devm_regulator_get_enable(&spi->dev, "vdd");
+	if (ret)
+		return ret;
+
 	gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
 	if (IS_ERR(gpio))
 		return PTR_ERR(gpio);

-- 
2.43.2

