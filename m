From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Tue, 14 May 2024 10:22:51 +0300
Subject: [PATCH v2 6/9] iio: adc: ad7173: Add ad7173_device_info names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240514-ad4111-v2-6-29be6a55efb5@analog.com>
References: <20240514-ad4111-v2-0-29be6a55efb5@analog.com>
In-Reply-To: <20240514-ad4111-v2-0-29be6a55efb5@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715671396; l=1239;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=PqeTnj5w9/XrPfeAGecqWJITOQlmi0XSad6CyOICJio=;
 b=5EmB4s4xRNoWeii1HzRetU0NZrVJYr0z8L4RtClGtisPJFdo5sZtmdPDFdLDUxxzYyPeA0Qio
 ccQ28CIMpNXB0mTmg+X4S/OGoM3YwoBVgE4QS1NuSjrZFDVu11nkqeT
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missing names from the device info struct for 3 models to ensure
consistency with the rest of the models.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 1e9ba3070770..d965b66d4d5a 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -227,6 +227,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7173_sinc5_data_rates),
 	},
 	[ID_AD7172_4] = {
+		.name = "ad7172-4",
 		.id = AD7172_4_ID,
 		.num_inputs = 9,
 		.num_channels = 8,
@@ -272,6 +273,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
 	},
 	[ID_AD7175_8] = {
+		.name = "ad7175-8",
 		.id = AD7175_8_ID,
 		.num_inputs = 17,
 		.num_channels = 16,
@@ -302,6 +304,7 @@ static const struct ad7173_device_info ad7173_device_info[] = {
 		.num_sinc5_data_rates = ARRAY_SIZE(ad7175_sinc5_data_rates),
 	},
 	[ID_AD7177_2] = {
+		.name = "ad7177-2",
 		.id = AD7177_ID,
 		.num_inputs = 5,
 		.num_channels = 4,

-- 
2.43.0

