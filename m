From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 17:22:04 +0100
Subject: [PATCH v4 4/6] iio: temperature: ltc2983: support vdd regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-ltc2983-misc-improv-v4-4-0cc428c07cd5@analog.com>
References: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
In-Reply-To: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jyoti Bhayana <jbhayana@google.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711642925; l=908;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=vIAh0fbwcufBzWFPmQO/O8++O6EavSlE5C9AW8NDQh4=;
 b=fJtWRp8ioO/nf8wpJHWMQlpYTKwmEBGsC1Ob4PlDmd6sQbfq2yl/Aiw9upFN2CijYB9w5t0kt
 d6YW/P2DbUzDkwaZn15hxItqaE3EKqM9nYqAlo2t6COxS0qqm0axl2i
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
index b4a8ca36458a..ff7f0829b575 100644
--- a/drivers/iio/temperature/ltc2983.c
+++ b/drivers/iio/temperature/ltc2983.c
@@ -18,6 +18,7 @@
 #include <linux/module.h>
 #include <linux/property.h>
 #include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
 #include <linux/spi/spi.h>
 
 #include <asm/byteorder.h>
@@ -1574,6 +1575,10 @@ static int ltc2983_probe(struct spi_device *spi)
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
2.44.0

