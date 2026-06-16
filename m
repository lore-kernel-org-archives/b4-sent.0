From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 16 Jun 2026 09:21:12 +0100
Subject: [PATCH v3 06/12] iio: dac: ad5686: consume optional reset signal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-ad5686-new-features-v3-6-f829fb7e9262@analog.com>
References: <20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com>
In-Reply-To: <20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781598070; l=1481;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=6lPEN1c2sS+R7KwOHtaMJleq8x339OPoW8meT8vCQvM=;
 b=pErFqIm+hSUjbyvb1YF5pDPDdIpuF9i0tTblK7GsozWn2P2wDrecTKdsWXZWc0D0lwE5m55xf
 +sn4SJZ4SqMCkphlMbf+rheyC3bA3EE2JumZt9VkgZKsjn/fPvk8l1v
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add RESET pin GPIO support through an optional reset control, which is
local to the probe function. A reset pulse is manually generated after
the device is powered up.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index fc3863274b29..a48acedff51c 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -15,6 +15,7 @@
 #include <linux/kstrtox.h>
 #include <linux/module.h>
 #include <linux/regulator/consumer.h>
+#include <linux/reset.h>
 #include <linux/sysfs.h>
 #include <linux/wordpart.h>
 
@@ -472,6 +473,7 @@ int ad5686_probe(struct device *dev,
 		 const struct ad5686_chip_info *chip_info,
 		 const char *name, const struct ad5686_bus_ops *ops)
 {
+	struct reset_control *rstc;
 	struct ad5686_state *st;
 	struct iio_dev *indio_dev;
 	int ret, i;
@@ -508,6 +510,15 @@ int ad5686_probe(struct device *dev,
 
 	fsleep(5); /* power-up time */
 
+	rstc = devm_reset_control_get_optional_exclusive(dev, NULL);
+	if (IS_ERR(rstc))
+		return dev_err_probe(dev, PTR_ERR(rstc),
+				     "Failed to get reset control\n");
+
+	reset_control_assert(rstc);
+	fsleep(1); /* reset pulse: comfortably bigger than the spec */
+	reset_control_deassert(rstc);
+
 	/* Initialize masks to all ones */
 	st->pwr_down_mask = ~0;
 	st->pwr_down_mode = ~0;

-- 
2.43.0

