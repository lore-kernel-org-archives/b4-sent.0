From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 03 Dec 2025 15:53:36 +0000
Subject: [PATCH 1/2] iio: dac: adi-axi-dac: Make use of dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251203-iio-axi-dac-minor-changes-v1-1-b54650cbeb33@analog.com>
References: <20251203-iio-axi-dac-minor-changes-v1-0-b54650cbeb33@analog.com>
In-Reply-To: <20251203-iio-axi-dac-minor-changes-v1-0-b54650cbeb33@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764777217; l=1752;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=8mvNrUBom7hQsbFUetN1gZgHBDbTPlojxNzlZxLUsoQ=;
 b=ny2Ss3RaoTCpYGC7+VUE7aaooNC2eVT3XX7ukwTp/8kbu5jvYCKF+bCkAmQ4mC7NwTcB6WEc2
 r+rG87ynjPBBVUH0V7HzWNYSLHq0VG/FdDyyBU3M6DAJQEpavY7ecAQ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Be consistent and use dev_err_probe() as in all other places in the
.probe() path.

While at it, remove the line break in the version condition. Yes, it
goes over the 80 column limit but I do think the line break hurts
readability in this case.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/adi-axi-dac.c | 20 +++++++++-----------
 1 file changed, 9 insertions(+), 11 deletions(-)

diff --git a/drivers/iio/dac/adi-axi-dac.c b/drivers/iio/dac/adi-axi-dac.c
index 0d525272a8a8..0c7b62f5357d 100644
--- a/drivers/iio/dac/adi-axi-dac.c
+++ b/drivers/iio/dac/adi-axi-dac.c
@@ -942,17 +942,15 @@ static int axi_dac_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	if (ADI_AXI_PCORE_VER_MAJOR(ver) !=
-		ADI_AXI_PCORE_VER_MAJOR(st->info->version)) {
-		dev_err(&pdev->dev,
-			"Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
-			ADI_AXI_PCORE_VER_MAJOR(st->info->version),
-			ADI_AXI_PCORE_VER_MINOR(st->info->version),
-			ADI_AXI_PCORE_VER_PATCH(st->info->version),
-			ADI_AXI_PCORE_VER_MAJOR(ver),
-			ADI_AXI_PCORE_VER_MINOR(ver),
-			ADI_AXI_PCORE_VER_PATCH(ver));
-		return -ENODEV;
+	if (ADI_AXI_PCORE_VER_MAJOR(ver) != ADI_AXI_PCORE_VER_MAJOR(st->info->version)) {
+		return dev_err_probe(&pdev->dev, -ENODEV,
+				     "Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
+				     ADI_AXI_PCORE_VER_MAJOR(st->info->version),
+				     ADI_AXI_PCORE_VER_MINOR(st->info->version),
+				     ADI_AXI_PCORE_VER_PATCH(st->info->version),
+				     ADI_AXI_PCORE_VER_MAJOR(ver),
+				     ADI_AXI_PCORE_VER_MINOR(ver),
+				     ADI_AXI_PCORE_VER_PATCH(ver));
 	}
 
 	/* Let's get the core read only configuration */

-- 
2.52.0

