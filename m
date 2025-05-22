From: Alejandro Enrique <alejandroe1@geotab.com>
Date: Thu, 22 May 2025 18:51:05 +0200
Subject: [PATCH v2 2/2] gnss: ubx: add support for the safeboot gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250522-ubx-safeboot-v2-2-08c22378b8c9@geotab.com>
References: <20250522-ubx-safeboot-v2-0-08c22378b8c9@geotab.com>
In-Reply-To: <20250522-ubx-safeboot-v2-0-08c22378b8c9@geotab.com>
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747932696; l=1402;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=5q+UP/BRI1cuC24cDBux+9AkjID15/gPXOINM1Yuf4o=;
 b=5l9yKE0744FlWyjZWyv0I/rGEgSlfrWCWO9JaUxMKa/w2pJIuY/I4S9p741rcGvVtBn4q06gW
 IsojkHvqaFkBsAIEzR0fVQPZzqlLwWKqYHLSHWYahxURpkUliwLnj2L
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Blox 8/M8/M9 chip have a pin to start it in safeboot mode, to be
used to recover from situations where the flash content has become
corrupted and needs to be restored. If this pin is asserted at power
up/reset, the receiver starts in safeboot mode and GNSS operation is
disabled.

Deassert the safeboot pin when probing this driver.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
 drivers/gnss/ubx.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/gnss/ubx.c b/drivers/gnss/ubx.c
index 92402f6082c415c7b9051338eef5406b09e09455..1d6acace84f76f8d5d2eacdbbf5ab7a934b33486 100644
--- a/drivers/gnss/ubx.c
+++ b/drivers/gnss/ubx.c
@@ -67,6 +67,7 @@ static int ubx_probe(struct serdev_device *serdev)
 {
 	struct gnss_serial *gserial;
 	struct gpio_desc *reset;
+	struct gpio_desc *safeboot;
 	struct ubx_data *data;
 	int ret;
 
@@ -82,6 +83,13 @@ static int ubx_probe(struct serdev_device *serdev)
 
 	data = gnss_serial_get_drvdata(gserial);
 
+	/* Deassert safeboot */
+	safeboot = devm_gpiod_get_optional(&serdev->dev, "safeboot", GPIOD_OUT_LOW);
+	if (IS_ERR(safeboot)) {
+		ret = PTR_ERR(safeboot);
+		goto err_free_gserial;
+	}
+
 	data->vcc = devm_regulator_get(&serdev->dev, "vcc");
 	if (IS_ERR(data->vcc)) {
 		ret = PTR_ERR(data->vcc);

-- 
2.34.1

