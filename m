From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 31 May 2024 11:41:54 +0200
Subject: [PATCH v3 1/2] iio: adc: adi-axi-adc: don't allow concurrent
 enable/disable calls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240531-dev-axi-adc-drp-v3-1-e3fa79447c67@analog.com>
References: <20240531-dev-axi-adc-drp-v3-0-e3fa79447c67@analog.com>
In-Reply-To: <20240531-dev-axi-adc-drp-v3-0-e3fa79447c67@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717148521; l=1133;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=JoueMCiuIGkQcabjP3EvL+lebFySB1NCgLCP/9+LfjA=;
 b=Q9oULb7KbIlafIfeRmO8n+dn4n9jSgM88dKqt4bdGSeb4ceHAD72mFDx93Br21r/pCpbzh5DJ
 kEa0Oyg3v9SBJvHRrTvy3HfQ8Grtq1GF/NABLZDUqQ6wSnMPAj86x0q
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add proper mutex guards as we should not be able to disable
the core in the middle of enabling it.

Note there's no need to rush in backporting this as the only user of the
backend does not do anything crazy..

Fixes: 794ef0e57854 ("iio: adc: adi-axi-adc: move to backend framework")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 0cf0d81358fd..bf51d619ebbc 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -85,6 +85,7 @@ static int axi_adc_enable(struct iio_backend *back)
 	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
 	int ret;
 
+	guard(mutex)(&st->lock);
 	ret = regmap_set_bits(st->regmap, ADI_AXI_REG_RSTN,
 			      ADI_AXI_REG_RSTN_MMCM_RSTN);
 	if (ret)
@@ -99,6 +100,7 @@ static void axi_adc_disable(struct iio_backend *back)
 {
 	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
 
+	guard(mutex)(&st->lock);
 	regmap_write(st->regmap, ADI_AXI_REG_RSTN, 0);
 }
 

-- 
2.45.1

