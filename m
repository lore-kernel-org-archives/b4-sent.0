From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 04 Dec 2025 15:24:18 +0000
Subject: [PATCH 2/3] iio: adc: adi-axi-adc: Turn dev_info() into dev_dbg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251204-iio-axi-adc-minor-change-v1-2-2d441d6c5b65@analog.com>
References: <20251204-iio-axi-adc-minor-change-v1-0-2d441d6c5b65@analog.com>
In-Reply-To: <20251204-iio-axi-adc-minor-change-v1-0-2d441d6c5b65@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764861858; l=1066;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=OePNUCXm116ME9HrJY6rNf7OR2YjvC53VyV6nWYOz84=;
 b=DIxewfLl515CJKJ/cqdp8asPzOrG8UhLdACYGPEZ/wF3ZuyQ+FTwuWFdSM3xPfTx3KpE0POW1
 FeBL1mnEdggADitiS+4HsqKPeY9JVYcL4oc6wakLcYiToAYSCz+Xn9P
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We should not abuse logging and logging a successful probe is clearly
abuse. Turn it into dev_dbg().

If it turns out the IP version is that relevant we can make it easy to
get through a new debugfs interface later on.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 8b8955841afa..32af2bfc2bf1 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -753,10 +753,10 @@ static int adi_axi_adc_probe(struct platform_device *pdev)
 					     "cannot create device.");
 	}
 
-	dev_info(&pdev->dev, "AXI ADC IP core (%d.%.2d.%c) probed\n",
-		 ADI_AXI_PCORE_VER_MAJOR(ver),
-		 ADI_AXI_PCORE_VER_MINOR(ver),
-		 ADI_AXI_PCORE_VER_PATCH(ver));
+	dev_dbg(&pdev->dev, "AXI ADC IP core (%d.%.2d.%c) probed\n",
+		ADI_AXI_PCORE_VER_MAJOR(ver),
+		ADI_AXI_PCORE_VER_MINOR(ver),
+		ADI_AXI_PCORE_VER_PATCH(ver));
 
 	return 0;
 }

-- 
2.52.0

