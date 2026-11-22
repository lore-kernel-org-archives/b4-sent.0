From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 22 Nov 2026 19:15:48 +0200
Subject: [PATCH v3 7/7] iio: light: stk3310: add STK3331-A support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-6768-stk3337-v3-7-b0d0a924e843@protonmail.com>
References: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
In-Reply-To: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Joshua Crofts <crofts@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795367795; l=1115;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=5Lb0wBjkKirl6paCvZStiiK+HOmi2iCm2HR1MhrJJ0c=;
 b=bT6AmY/HNuP+2j4nkBV8i/5kVozT97Iq41N3J9UlmTdlbzYaAguB3sr/Y+zXwQfWxcXNvS8Cc
 WH1zcJSuFMMBM4gKOtqAd5jm5d53EBJRk/zapvnWpgyU6mXpqoKwL7B
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

STK3331 is a STK3337 with slightly bigger package. Add support for the A
revision.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
A revision has different chip ID compared to the base STK3331, but
otherwise chips are identical. Only this revision is added since I have
no other hardware with stk3331.
---
 drivers/iio/light/stk3310.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/light/stk3310.c b/drivers/iio/light/stk3310.c
index 83f40714b972..8f640ab10677 100644
--- a/drivers/iio/light/stk3310.c
+++ b/drivers/iio/light/stk3310.c
@@ -60,6 +60,7 @@
 #define STK3311A_CHIP_ID_VAL			0x15
 #define STK3311S34_CHIP_ID_VAL			0x1E
 #define STK3311X_CHIP_ID_VAL			0x12
+#define STK3331A_CHIP_ID_VAL			0x5E
 #define STK3335_CHIP_ID_VAL			0x51
 #define STK3337_CHIP_ID_VAL			0x5F
 #define STK36C61_CHIP_ID_VAL			0x95
@@ -112,6 +113,7 @@ static const u8 stk3310_chip_ids[] = {
 	STK3311S34_CHIP_ID_VAL,
 	STK3311X_CHIP_ID_VAL,
 	STK3311_CHIP_ID_VAL,
+	STK3331A_CHIP_ID_VAL,
 	STK3335_CHIP_ID_VAL,
 	STK3337_CHIP_ID_VAL,
 	STK36C61_CHIP_ID_VAL,

-- 
2.56.1

