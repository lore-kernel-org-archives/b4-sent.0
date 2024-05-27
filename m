From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 27 May 2024 20:02:39 +0300
Subject: [PATCH v3 6/6] iio: adc: ad7173: Reduce device info struct size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240527-ad4111-v3-6-7e9eddbbd3eb@analog.com>
References: <20240527-ad4111-v3-0-7e9eddbbd3eb@analog.com>
In-Reply-To: <20240527-ad4111-v3-0-7e9eddbbd3eb@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716829358; l=1076;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=i/3qfPHmc9/fJMS7GphA3tYcltv4y8f3THcKw3nnHnI=;
 b=oSmM/iCHqtU2Fbgfsws2MdnrTzKs8xA2r7xrX1RGY/f4pWMUgc3baXJjLPh76lfEP9jLgyv+Q
 wZCFDZRWSVDDFqbaVPfUz/FVnu+aTuBc8FU1MnaNEvsVH16Mdyk/qMU
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
index 328685ce25e0..e8357a21d513 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -179,15 +179,15 @@ struct ad7173_device_info {
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

