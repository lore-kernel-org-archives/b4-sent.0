From: Andrei Stancovici <andrei.stancovici@analog.com>
Date: Fri, 09 Oct 2026 11:43:39 +0300
Subject: [PATCH 6/6] iio: adc: ltc2497: enable line-frequency rejection on
 LTC2493
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-submission-ltc2493-support-v1-v1-6-3dad1d4b152a@analog.com>
References: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
In-Reply-To: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Andrei Stancovici <andrei.stancovici@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791535413; l=1838;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=7ewq8alFihW5vhjreGYIj3/9edWfbR2R3OHLsw5SrBg=;
 b=bNkz55wgzX/UAqbefg/RmsiFTJUcEQxm5UkHI1KyBb3zLZewB2ZGlKQu0X1Zj6IwsYIlqztLD
 ue2poOvZ6ydAOlq9DcEAaJtEXjC1VTmiZjwVwWkU2O90+x+M6hTeHJB
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC2493 carries the same second configuration byte as the LTC2499,
with identical FA/FB line-rejection semantics and the same per-rejection
conversion times (50Hz-only being the longest at 163.5ms). The generic
filter_mode infrastructure is already implemented in the core and enabled
for the LTC2499. Enable the same flag for the LTC2493.

Tested on live LTC2493 hardware connected through an IIO network backend:
all three modes are selectable; conversion times are respected; voltage
and temperature reads succeed in each mode with no -EIO.

Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/2493fe.pdf
Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>
---
 drivers/iio/adc/ltc2497.c | 1 +
 drivers/iio/adc/ltc2497.h | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ltc2497.c b/drivers/iio/adc/ltc2497.c
index 0df2ad9b3243..d668a81f1ff7 100644
--- a/drivers/iio/adc/ltc2497.c
+++ b/drivers/iio/adc/ltc2497.c
@@ -195,6 +195,7 @@ static const struct ltc2497_chip_info ltc2497_info[] = {
 		.name = "ltc2493",
 		.has_temp = true,
 		.has_speed_mode = true,
+		.has_rejection_mode = true,
 		.four_channel = true,
 	},
 	[TYPE_LTC2497] = {
diff --git a/drivers/iio/adc/ltc2497.h b/drivers/iio/adc/ltc2497.h
index 34ea62c2a4bc..af939e57e1f8 100644
--- a/drivers/iio/adc/ltc2497.h
+++ b/drivers/iio/adc/ltc2497.h
@@ -50,7 +50,7 @@ struct ltc2497_chip_info {
 	u32 resolution;
 	bool has_temp;
 	bool has_speed_mode;	/* SPD bit in the 2nd config byte (LTC2499/LTC2493) */
-	bool has_rejection_mode;	/* FA/FB bits in the 2nd config byte (LTC2499) */
+	bool has_rejection_mode;	/* FA/FB bits in the 2nd config byte (LTC2499/LTC2493) */
 	bool four_channel;	/* 4 inputs (LTC2493) instead of 16 */
 };
 

-- 
2.43.0

