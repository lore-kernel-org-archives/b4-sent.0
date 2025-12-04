From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 04 Dec 2025 15:24:19 +0000
Subject: [PATCH 3/3] iio: adc: adi-axi-adc: Slightly simplify
 axi_adc_create_platform_device()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251204-iio-axi-adc-minor-change-v1-3-2d441d6c5b65@analog.com>
References: <20251204-iio-axi-adc-minor-change-v1-0-2d441d6c5b65@analog.com>
In-Reply-To: <20251204-iio-axi-adc-minor-change-v1-0-2d441d6c5b65@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764861858; l=1080;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=M3sXn3XZpAfRUaGPA0yUjTsmlXal1gTgD6ZYc2L8B4s=;
 b=XUZKTkQzo0esGtR2IPoM17ul2k561+g6JV6U1L457Hx79BgtP3QBDDGN8S2LAFmZ703nUV2wm
 tuOmbcTv6HvAcvEAcvpbQksxQ8xjMgZ03N4RaD8xXvC6fNfmWLfWoqe
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's no point in having a ret variable and checking for errors (as we
do nothing with it). Instead, save some lines of code and directly
return the devm_add_action_or_reset() call.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 32af2bfc2bf1..9079e7c7332d 100644
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

