From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Apr 2024 17:42:14 +0200
Subject: [PATCH v2 5/7] iio: adc: adi-axi-adc: remove regmap max register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240426-ad9467-new-features-v2-5-6361fc3ba1cc@analog.com>
References: <20240426-ad9467-new-features-v2-0-6361fc3ba1cc@analog.com>
In-Reply-To: <20240426-ad9467-new-features-v2-0-6361fc3ba1cc@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714146147; l=813;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=xe0te39dghx3xVo9c0/ZGbv9/Txz1Y4hTt1+Fm8A5ns=;
 b=o5c0uXvGTGdhYwqp3weFdoAh7f9XAy9ZmUqGbq55yd79pfk2fzAhzvHRPkGwXUMDE3D9be53L
 CBRg8gZkR2TDGM3i+nD1zs5TfaTe9YN874soCidkODy6JyGtff3ONNt
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In one of the following patches, we'll have some new functionality that
requires reads/writes on registers bigger than 0x8000. Hence, as this is
an highly flexible core, don't bother in setting 'max_register' and
remove it from regmap_config.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index e3b215882941..b312369b7366 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -156,7 +156,6 @@ static const struct regmap_config axi_adc_regmap_config = {
 	.val_bits = 32,
 	.reg_bits = 32,
 	.reg_stride = 4,
-	.max_register = 0x0800,
 };
 
 static const struct iio_backend_ops adi_axi_adc_generic = {

-- 
2.44.0

