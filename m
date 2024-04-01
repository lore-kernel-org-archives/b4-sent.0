From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 01 Apr 2024 18:32:23 +0300
Subject: [PATCH 5/6] iio: adc: ad7173: Remove index from temp channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240401-ad4111-v1-5-34618a9cc502@analog.com>
References: <20240401-ad4111-v1-0-34618a9cc502@analog.com>
In-Reply-To: <20240401-ad4111-v1-0-34618a9cc502@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711985550; l=697;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=BEq6V85bjOhRpMOZUvZXO8DDCT8wIyhHIFI5fumHsUQ=;
 b=uRtEs9PSWhwA2agYFbdIGhRPxleMz2YI6DJQGcqKWjiKcckx5OaBkgBeVypd7Pkc4k2o8EF4Z
 Oe/2pVoVCLyDEuuNazmWNj21SPV6BuCXgX9le+FvPpRM4d/974PE+6r
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Temperature channel is unique per device, index is not needed.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index bf5a5b384fe2..9526585e6929 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -797,7 +797,6 @@ static const struct iio_info ad7173_info = {
 
 static const struct iio_chan_spec ad7173_channel_template = {
 	.type = IIO_VOLTAGE,
-	.indexed = 1,
 	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 		BIT(IIO_CHAN_INFO_SCALE),
 	.info_mask_shared_by_all = BIT(IIO_CHAN_INFO_SAMP_FREQ),

-- 
2.43.0

