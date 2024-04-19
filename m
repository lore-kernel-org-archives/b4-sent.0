From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 19 Apr 2024 17:36:45 +0200
Subject: [PATCH 2/8] iio: adc: adi-axi-adc: only error out in major version
 mismatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240419-ad9467-new-features-v1-2-3e7628ff6d5e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713541010; l=1320;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=PKeKv+/FjVf4CBXkS3IXNv+HfrXrDFDeJP+4Q7Z6xTk=;
 b=BFlPAe3M5OBgFWkkaWq/O6gsfGa0Vd1GEBUfwRCXcvzaGJ+FegFvmtfP1dTDZkZfHI3pR2ABp
 MTCRXzhpKF3AveS9Ijc58ZBmReShPeIV05HubsvboArxiYkuHx3A0nA
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IP core only has breaking changes when there major version changes.
Hence, only match the major number. This is also in line with the other
core ADI has upstream. The current check for erroring out
'expected_version > current_version"' is then wrong as we could just
increase the core major with breaking changes and that would go
unnoticed.

Fixes: ef04070692a2 ("iio: adc: adi-axi-adc: add support for AXI ADC IP core")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 4156639b3c8bd..a543b91124b07 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -207,9 +207,9 @@ static int adi_axi_adc_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	if (*expected_ver > ver) {
+	if (ADI_AXI_PCORE_VER_MAJOR(ver) != ADI_AXI_PCORE_VER_MAJOR(*expected_ver)) {
 		dev_err(&pdev->dev,
-			"IP core version is too old. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
+			"Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
 			ADI_AXI_PCORE_VER_MAJOR(*expected_ver),
 			ADI_AXI_PCORE_VER_MINOR(*expected_ver),
 			ADI_AXI_PCORE_VER_PATCH(*expected_ver),

-- 
2.44.0

