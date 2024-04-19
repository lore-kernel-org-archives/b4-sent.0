From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 19 Apr 2024 17:36:48 +0200
Subject: [PATCH 5/8] iio: adc: adi-axi-adc: remove regmap max register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240419-ad9467-new-features-v1-5-3e7628ff6d5e@analog.com>
References: <20240419-ad9467-new-features-v1-0-3e7628ff6d5e@analog.com>
In-Reply-To: <20240419-ad9467-new-features-v1-0-3e7628ff6d5e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713541010; l=815;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=yuttbukX0NN4jOLmY+xhQCCzS7vMjNuAM9G3y7vBkBQ=;
 b=y0o0eeLrYzGr245OURF3dJWvUh47qOXbJariJnO8XLiBAsBFls5dys91Zk9aFUSrNH4bMvYft
 EDhQDnfe4qvB602a01WCf7iWDyVf4jisiLbtAXr/wkjitG91qMSe48X
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
index e3b2158829416..b312369b73661 100644
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

