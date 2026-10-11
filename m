From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Sun, 11 Oct 2026 19:56:22 +0100
Subject: [PATCH] staging: iio: addac: adt7316: use dev_err_probe() for ldac
 GPIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-adt7316-dev-err-probe-v1-1-27a4a8ac74f3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTtJpwoar2JcUPoXxwWQKRITw
 t2tsPwW762UYYpM92olw6JZx6FAThV1r3bowRqLyTvfiBPhNs7XszQcsTDMeLIxgG8phRreX8Q
 5Ku1kSPrdv4/n4fwJb3Tzf0bb9gNMbRGeeQAAAA==
X-Change-ID: 20261011-adt7316-dev-err-probe-8ffb5e224100
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791745012; l=1387;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=b9texfP1vjXc9iYJeYxurlQBJ3RyvvggOaFq0fR0kvo=;
 b=Ml2G6laG6UKHKDMNpCXGH/kQ0Vv3RYgblFQ8M7uDN0IAGoxakP9rTZs++Aqz0rWPNXWEOOAug
 xd4kel0/UlBAHfRapKDyCjwHCtIJKlyRtKikPDhaPc5jvAGgKIV/slu
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use dev_err_probe() when requesting the ldac GPIO fails. This
avoids logging an error when the GPIO controller is not ready yet
and the request returns -EPROBE_DEFER, and records the deferral
reason. It also simplifies the error path.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
Compile-tested only.
---
 drivers/staging/iio/addac/adt7316.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/staging/iio/addac/adt7316.c b/drivers/staging/iio/addac/adt7316.c
index 20f6052cc7fb..8ca6def84584 100644
--- a/drivers/staging/iio/addac/adt7316.c
+++ b/drivers/staging/iio/addac/adt7316.c
@@ -2142,11 +2142,9 @@ int adt7316_probe(struct device *dev, struct adt7316_bus *bus,
 
 	chip->ldac_pin = devm_gpiod_get_optional(dev, "adi,ldac",
 						 GPIOD_OUT_LOW);
-	if (IS_ERR(chip->ldac_pin)) {
-		ret = PTR_ERR(chip->ldac_pin);
-		dev_err(dev, "Failed to request ldac GPIO: %d\n", ret);
-		return ret;
-	}
+	if (IS_ERR(chip->ldac_pin))
+		return dev_err_probe(dev, PTR_ERR(chip->ldac_pin),
+				     "Failed to request ldac GPIO\n");
 
 	if (!chip->ldac_pin) {
 		chip->config3 |= ADT7316_DA_EN_VIA_DAC_LDAC;

---
base-commit: a22dc7ebb21a6bd4c8b63bc2c1dd46a24945aae7
change-id: 20261011-adt7316-dev-err-probe-8ffb5e224100

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

