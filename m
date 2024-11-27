From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Wed, 27 Nov 2024 23:18:29 +0100
Subject: [PATCH] spi: apple: Set use_gpio_descriptors to true
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241127-gpio-descs-v1-1-c586b518a7d5@gmail.com>
X-B4-Tracking: v=1; b=H4sIALSaR2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQyNz3fSCzHzdlNTi5GJdU4u05DTLRAOTZJNkJaCGgqLUtMwKsGHRsbW
 1AJl8XwxcAAAA
X-Change-ID: 20241127-gpio-descs-58fcf9a04c4c
To: Mark Brown <broonie@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Sven Peter <sven@svenpeter.dev>, Alyssa Rosenzweig <alyssa@rosenzweig.io>
Cc: linux-spi@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732745939; l=929;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=I6RiQB/DHHaeohSxMjebLzpsTxP8yPVRu7SXWDHE5HI=;
 b=/c8gIuS+kh48ubs1Hq95yjV5JOPYIofMQzBlghiIjcZ++7rwW+QsSWZFb/XN5GWexuYZSF5OA
 sWKRxaSe7FrA7BQwIUEQI917LkvvL0yiRlsr6455o2So3QzqAhT9nIK
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is at least one peripheral that is attached to this
controller and can not use native CS. Make it possible to use
a GPIO instead.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/spi/spi-apple.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/spi/spi-apple.c b/drivers/spi/spi-apple.c
index d4b126c8701a67083e7247d1c82fb56f1725d9cb..6273352a2b2861c9da0976a46ec2adbc4c71d3d2 100644
--- a/drivers/spi/spi-apple.c
+++ b/drivers/spi/spi-apple.c
@@ -493,6 +493,7 @@ static int apple_spi_probe(struct platform_device *pdev)
 	ctlr->prepare_message = apple_spi_prepare_message;
 	ctlr->set_cs = apple_spi_set_cs;
 	ctlr->transfer_one = apple_spi_transfer_one;
+	ctlr->use_gpio_descriptors = true;
 	ctlr->auto_runtime_pm = true;
 
 	pm_runtime_set_active(&pdev->dev);

---
base-commit: 9f16d5e6f220661f73b36a4be1b21575651d8833
change-id: 20241127-gpio-descs-58fcf9a04c4c

