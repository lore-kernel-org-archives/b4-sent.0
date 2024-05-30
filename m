From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 30 May 2024 15:07:52 +0300
Subject: [PATCH v3 4/5] iio: adc: ad7173: Clear append status bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240530-ad7173-fixes-v3-4-b85f33079e18@analog.com>
References: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
In-Reply-To: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717070881; l=1000;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=3Lih309+QmE+/CCcvFgIQ2n+1Fi+3MwieGtcQTnVs2U=;
 b=tfCorgq0OSKRQvM2Q3NGFOUZ1X2YYA74t5jLnItpkypqPxNNNi3vR/gUXjZgy9xDWyb8j/uLq
 NDCDOpATRj3CWE2Yawyq8iYYrUX1Tu74KX8etJRApoMR6nCL1zl+TDQ
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The previous value of the append status bit was not cleared before
setting the new value. This caused the bit to remain set after enabling
buffered mode for multiple channels and not permit further buffered
reads from a single channel after the fact.

Fixes: 8eb903272f75 ("iio: adc: ad7173: add AD7173 driver")
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index eb512878c30e..e66a137a76be 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -543,6 +543,7 @@ static int ad7173_append_status(struct ad_sigma_delta *sd, bool append)
 	unsigned int interface_mode = st->interface_mode;
 	int ret;
 
+	interface_mode &= ~AD7173_INTERFACE_DATA_STAT;
 	interface_mode |= AD7173_INTERFACE_DATA_STAT_EN(append);
 	ret = ad_sd_write_reg(&st->sd, AD7173_REG_INTERFACE_MODE, 2, interface_mode);
 	if (ret)

-- 
2.43.0

