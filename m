From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 19 Dec 2025 15:40:39 +0000
Subject: [PATCH v2 2/2] iio: adc: adi-axi-adc: Slightly simplify
 axi_adc_create_platform_device()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251219-iio-axi-adc-minor-change-v2-2-9d8e7270d19a@analog.com>
References: <20251219-iio-axi-adc-minor-change-v2-0-9d8e7270d19a@analog.com>
In-Reply-To: <20251219-iio-axi-adc-minor-change-v2-0-9d8e7270d19a@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766158839; l=1128;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=eSSzk0RaR2Q7Wh4xhuLnatBHuxxp6eXT3J54PD457xY=;
 b=MlOkMyQzJfZNTLK7022s5XkmW2Sju2Vl1GfY1daoxzW18ME1m6vD6UEHVDFDzwif+O9t1kkYt
 WqL6J1kpAwCCsGYEdWLt+Fjqdgzn/8WJCSxWmKOZJnEFyH5C1A/U64t
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's no point in having a ret variable and checking for errors (as we
do nothing with it). Instead, save some lines of code and directly
return the devm_add_action_or_reset() call.

Reviewed-by: Andy Shevchenko <andy@kernel.org>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index fef4fdedb976..5f445e0de9ea 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -591,17 +591,12 @@ static int axi_adc_create_platform_device(struct adi_axi_adc_state *st,
 	    .size_data = st->info->pdata_sz,
 	};
 	struct platform_device *pdev;
-	int ret;
 
 	pdev = platform_device_register_full(&pi);
 	if (IS_ERR(pdev))
 		return PTR_ERR(pdev);
 
-	ret = devm_add_action_or_reset(st->dev, axi_adc_child_remove, pdev);
-	if (ret)
-		return ret;
-
-	return 0;
+	return devm_add_action_or_reset(st->dev, axi_adc_child_remove, pdev);
 }
 
 static const struct iio_backend_ops adi_axi_adc_ops = {

-- 
2.52.0

