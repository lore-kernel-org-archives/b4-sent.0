From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 16 Jul 2026 13:14:18 +0100
Subject: [PATCH v8 2/8] iio: dac: ad5686: missing NULL check on match data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-ad5686-new-features-v8-2-ebb0051af5e5@analog.com>
References: <20260716-ad5686-new-features-v8-0-ebb0051af5e5@analog.com>
In-Reply-To: <20260716-ad5686-new-features-v8-0-ebb0051af5e5@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784204073; l=947;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=B6fpsbUowwq2wwnC44rBjvb0k/SqZw7YPYPD6UUOXs0=;
 b=5ahXKuzPoIFDO9l54rv9iIqAN0epUdRXTrmvtahiMVJ/CWOWJGdeK6lTWQJLFrIjGrx8lBITM
 ZYZkTXl+tXQDNfaQOHm6YjFaJMXZhr+aFpjrBvyoGxGH1919grMWu+x
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Verify that chip_info pointer is not NULL. If a user binds the driver
using driver_override via sysfs with a device name not present in the
id_table or of_match_table, match data will be NULL.

Fixes: 0eb1728461a1 ("iio: dac: ad5686: drop enum id")
Reported-by: sashiko-bot@kernel.org
Closes: https://lore.kernel.org/all/20260710113149.53EC51F000E9@smtp.kernel.org/
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 713fe71ad1e7..d34250647aa4 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -479,6 +479,9 @@ int ad5686_probe(struct device *dev,
 	struct iio_dev *indio_dev;
 	int ret, i;
 
+	if (!chip_info)
+		return -ENODEV;
+
 	indio_dev = devm_iio_device_alloc(dev, sizeof(*st));
 	if (indio_dev == NULL)
 		return  -ENOMEM;

-- 
2.43.0

