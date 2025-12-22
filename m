From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 22 Dec 2025 13:48:02 +0000
Subject: [PATCH v3 2/2] iio: dac: adi-axi-dac: Make use of dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251222-iio-axi-dac-minor-changes-v3-2-29199f239d9c@analog.com>
References: <20251222-iio-axi-dac-minor-changes-v3-0-29199f239d9c@analog.com>
In-Reply-To: <20251222-iio-axi-dac-minor-changes-v3-0-29199f239d9c@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766411287; l=1808;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=SY3JK+/HNrlZmomtHnAKg89zL88xQuNk8wgu42OPM3Y=;
 b=YRGfTjE3H+Hf3BIVR13PdwmpqoU4jU/OPIF2oiZb7RD0/pDduVEXKRqufn1k0CUDQKNXI0lZT
 j56hxffPCIxA0tcRX0dqzP5uRr4c0aOWk4elQFfwXz8FxcNJKlX7OmV
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
 drivers/iio/dac/adi-axi-dac.c | 21 +++++++++------------
 1 file changed, 9 insertions(+), 12 deletions(-)

diff --git a/drivers/iio/dac/adi-axi-dac.c b/drivers/iio/dac/adi-axi-dac.c
index 851d837d7ced..9cc895bbe51a 100644
--- a/drivers/iio/dac/adi-axi-dac.c
+++ b/drivers/iio/dac/adi-axi-dac.c
@@ -942,18 +942,15 @@ static int axi_dac_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	if (ADI_AXI_PCORE_VER_MAJOR(ver) !=
-		ADI_AXI_PCORE_VER_MAJOR(st->info->version)) {
-		dev_err(dev,
-			"Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
-			ADI_AXI_PCORE_VER_MAJOR(st->info->version),
-			ADI_AXI_PCORE_VER_MINOR(st->info->version),
-			ADI_AXI_PCORE_VER_PATCH(st->info->version),
-			ADI_AXI_PCORE_VER_MAJOR(ver),
-			ADI_AXI_PCORE_VER_MINOR(ver),
-			ADI_AXI_PCORE_VER_PATCH(ver));
-		return -ENODEV;
-	}
+	if (ADI_AXI_PCORE_VER_MAJOR(ver) != ADI_AXI_PCORE_VER_MAJOR(st->info->version))
+		return dev_err_probe(dev, -ENODEV,
+				     "Major version mismatch. Expected %d.%.2d.%c, Reported %d.%.2d.%c\n",
+				     ADI_AXI_PCORE_VER_MAJOR(st->info->version),
+				     ADI_AXI_PCORE_VER_MINOR(st->info->version),
+				     ADI_AXI_PCORE_VER_PATCH(st->info->version),
+				     ADI_AXI_PCORE_VER_MAJOR(ver),
+				     ADI_AXI_PCORE_VER_MINOR(ver),
+				     ADI_AXI_PCORE_VER_PATCH(ver));
 
 	/* Let's get the core read only configuration */
 	ret = regmap_read(st->regmap, AXI_DAC_CONFIG_REG, &st->reg_config);

-- 
2.52.0

