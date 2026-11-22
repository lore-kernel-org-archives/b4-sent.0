From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 22 Nov 2026 19:15:44 +0200
Subject: [PATCH v3 3/7] iio: light: stk3310: add vdd regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-6768-stk3337-v3-3-b0d0a924e843@protonmail.com>
References: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
In-Reply-To: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Joshua Crofts <crofts@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795367795; l=1033;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=P2zA60tDPyLHQndDHj+u94a4HO2dDtQIC2bKKHaTIpQ=;
 b=HZt8ub02NUAGUWBYyUOpHp1WDPqBqQXlQQt92xAhDa1+VGNNIS1Jchm3RtHXO60F9lhbU+xoJ
 LeAw67oYJJHAnIm/uZ0IVxum05xemR5iuLlm57hmFJJzNwEIejHda15
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some boards, the sensor is powered by shared power rail. If the rail
is powered down, the chip can't function.

Add vdd regulator support to ensure the power supply is enabled for the
chip.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/iio/light/stk3310.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/iio/light/stk3310.c b/drivers/iio/light/stk3310.c
index 708ac0503be0..828c3404215e 100644
--- a/drivers/iio/light/stk3310.c
+++ b/drivers/iio/light/stk3310.c
@@ -19,6 +19,7 @@
 #include <linux/pm.h>
 #include <linux/property.h>
 #include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
 #include <linux/sysfs.h>
 #include <linux/types.h>
 
@@ -759,6 +760,10 @@ static int stk3310_probe(struct i2c_client *client)
 	if (ret)
 		return ret;
 
+	ret = devm_regulator_get_enable(dev, "vdd");
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to get vdd supply\n");
+
 	ret = stk3310_regmap_init(data);
 	if (ret < 0)
 		return ret;

-- 
2.56.1

