From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 30 May 2024 15:07:50 +0300
Subject: [PATCH v3 2/5] iio: adc: ad7173: Add ad7173_device_info names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240530-ad7173-fixes-v3-2-b85f33079e18@analog.com>
References: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
In-Reply-To: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717070881; l=1300;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=jyW8M3kG3uqXuCNPYLLJGiYuxqeZCfGKeCCNwqrSJqE=;
 b=4ER/UoEn/wZkI/mak5zAphUNqZ5UqOLKaguF+1NemNuXpdxwqAYvU7JqWghs5G4GC1++u9dYk
 QcklpdWm3gDCBALYdzKaYyoU2WcJ5jcZdZ03thUV592FTTXKtZ/1XUo
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missing names from the device info struct for 3 models to ensure
consistency with the rest of the models.

Fixes: 8eb903272f75 ("iio: adc: ad7173: add AD7173 driver")
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 850574437bda..58620be41ef5 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -220,6 +220,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
 	},
 	[ID_AD7172_4] = {
+		.name = "ad7172-4",
 		.id = AD7172_4_ID,
 		.num_inputs = 9,
 		.num_channels = 8,
@@ -262,6 +263,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
 	},
 	[ID_AD7175_8] = {
+		.name = "ad7175-8",
 		.id = AD7175_8_ID,
 		.num_inputs = 17,
 		.num_channels = 16,
@@ -290,6 +292,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
 	},
 	[ID_AD7177_2] = {
+		.name = "ad7177-2",
 		.id = AD7177_ID,
 		.num_inputs = 5,
 		.num_channels = 4,

-- 
2.43.0

