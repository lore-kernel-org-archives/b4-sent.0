From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 12 Aug 2024 11:13:15 +0300
Subject: [PATCH v3 2/3] iio: adc: ad7173: order chipID by value
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240812-ad4113-v3-2-046e785dd253@analog.com>
References: <20240812-ad4113-v3-0-046e785dd253@analog.com>
In-Reply-To: <20240812-ad4113-v3-0-046e785dd253@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: mitrutzceclan@gmail.com, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723450395; l=698;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=k1tXhRvf85CI0lNgZZec7J3hSBj8X2rculRMdGUY4Mg=;
 b=ZaUjIQ1ZmMMYE8/2KaC+AqeSgH02Zl2dXe4SLTvI5NDQXg11U2LNB5RIR99bONIRf+36TAhhA
 N31IKgTLRsTD826unsuR1Fvlr9UY4G+9ll1OE92n6WBtbx/QDRClAX2
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The chipIDs defines were supposed to be ordered by value, one was out of
order. Fix the order.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index a854f2d30174..a2bfc28932a5 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -76,8 +76,8 @@
 					(x) == AD7173_AIN_REF_NEG)
 
 #define AD7172_2_ID			0x00d0
-#define AD7175_ID			0x0cd0
 #define AD7176_ID			0x0c90
+#define AD7175_ID			0x0cd0
 #define AD7175_2_ID			0x0cd0
 #define AD7172_4_ID			0x2050
 #define AD7173_ID			0x30d0

-- 
2.43.0

