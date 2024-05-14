From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Tue, 14 May 2024 10:22:54 +0300
Subject: [PATCH v2 9/9] iio: adc: ad7173: Reduce device info struct size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240514-ad4111-v2-9-29be6a55efb5@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715671396; l=1076;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=RmIUo6Mi25zkqE47X3KPvkctN+OcwkN8pU6glB5Vkrs=;
 b=rzsfG15wDQ+1f9c6J8mg/V77m6QEu332viIRx2GWiZgtebRG93ls/4H1z9xLYV+VM551lCcq4
 wKwALbRSrbpAfDYDCXinF1na7NgfPMqR2r7GHjJTUm1jyC8MUNx2ZXs
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reduce the size used by the device info struct by packing the bool
 fields within the same byte. This reduces the struct size from 52 bytes
 to 44 bytes.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index f049d79380ac..f963c731cae3 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -180,15 +180,15 @@ struct ad7173_device_info {
 	unsigned int clock;
 	unsigned int id;
 	char *name;
-	bool has_current_inputs;
-	bool has_vcom_input;
-	bool has_temp;
+	bool has_current_inputs		:1;
+	bool has_vcom_input		:1;
+	bool has_temp			:1;
 	/* ((AVDD1 − AVSS)/5) */
-	bool has_common_input;
-	bool has_input_buf;
-	bool has_int_ref;
-	bool has_ref2;
-	bool higher_gpio_bits;
+	bool has_common_input		:1;
+	bool has_input_buf		:1;
+	bool has_int_ref		:1;
+	bool has_ref2			:1;
+	bool higher_gpio_bits		:1;
 	u8 num_gpios;
 };
 

-- 
2.43.0

