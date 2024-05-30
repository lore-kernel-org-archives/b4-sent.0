From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 30 May 2024 15:07:51 +0300
Subject: [PATCH v3 3/5] iio: adc: ad7173: Remove index from temp channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240530-ad7173-fixes-v3-3-b85f33079e18@analog.com>
References: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
In-Reply-To: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717070881; l=851;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=qHzAb3Lr8QOhPoRlBg0Itkn9NRPMWDsCz2unbRqp8RE=;
 b=/16b4nMtXcLOu4ow4Fo36AISvbGQFYNZfcH6Ew8bLJc677ALZIM/4O0JxSjII5wclXnV8aT2m
 nWG7G+MZxNRCAuXDy3y7k7xXZJy0ST3XJcydCTvt7PkOv1o7cfGWCwC
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Temperature channel is unique per device, index is not needed.
This is breaking userspace: Include fixes tag to be released within the
same rc cycle.

Fixes: 8eb903272f75 ("iio: adc: ad7173: add AD7173 driver")
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 58620be41ef5..eb512878c30e 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -815,7 +815,6 @@ static const struct iio_chan_spec ad7173_channel_template = {
 
 static const struct iio_chan_spec ad7173_temp_iio_channel_template = {
 	.type = IIO_TEMP,
-	.indexed = 1,
 	.channel = AD7173_AIN_TEMP_POS,
 	.channel2 = AD7173_AIN_TEMP_NEG,
 	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |

-- 
2.43.0

