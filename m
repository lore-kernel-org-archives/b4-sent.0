From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 05 Feb 2026 17:59:14 +0100
Subject: [PATCH v3] iio: imu: inv_icm45600: fix INT1 drive bit inverted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260205-inv-icm45600-fix-int1-drive-bit-v3-1-9c60c354dadb@tdk.com>
X-B4-Tracking: v=1; b=H4sIAGHMhGkC/5XNwQ6CMBAE0F8xPbumXSglnvwP46G2q2wMYErTa
 Aj/7sLFqx5nMnkzq4kS06SOu1klKjzxOEio9jsVOj/cCThKVqix0agt8FCAQ1/bRmu48UuKbCA
 mLgRXzuCiQfIVYYioRHkmktX2cL5I7njKY3pvh8Ws7e92MWDAoXdtiNoZq085Pg5h7NUqF/xTQ
 9EsOZm35I2tv9qyLB+o1hhNGgEAAA==
X-Change-ID: 20260205-inv-icm45600-fix-int1-drive-bit-7d12ea3e2cd2
To: Remi Buisson <remi.buisson@tdk.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770310755; l=2533;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=QGN91Pwgl8UMh04RqyiuclAgzRVc3mqHRx1WHkaYI5A=;
 b=/jwqFXltzDkd5c6YB8QcLqBmbzGhn2UTjgkWON97MSMAKH/RrTfWV2Lf7evT6QNJHnt2wcPAi
 js3C85/eo8KBWy8ZcU+SZo6bQ3xemS+oC246eqOjGHm/ljSDhcceTPq
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drive bit must be set for open-drain mode and be cleared for push-pull
mode.

Referring to datasheet DS-000576_ICM-45605.pdf section 17.23
INT1_CONFIG2.

Fixes: 06674a72cf7a ("iio: imu: inv_icm45600: add buffer support in iio devices")
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Reviewed-by: Andy Shevchenko <andy@kernel.org>
Cc: stable@vger.kernel.org
---
Changes in v3:
- Add precisions in datasheet reference
- Add missing reviewed-by tag
- Link to v2: https://lore.kernel.org/r/20260205-inv-icm45600-fix-int1-drive-bit-v2-1-5e72608ea154@tdk.com

Changes in v2:
- Add datasheet precision where to find the bits
- Link to v1: https://lore.kernel.org/r/20260205-inv-icm45600-fix-int1-drive-bit-v1-1-72a78cd07150@tdk.com
---
 drivers/iio/imu/inv_icm45600/inv_icm45600.h      | 2 +-
 drivers/iio/imu/inv_icm45600/inv_icm45600_core.c | 4 ++--
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600.h b/drivers/iio/imu/inv_icm45600/inv_icm45600.h
index c5b5446f6c3b43150512bcc4357cee385080b634..1c796d4b2a4038203f734f80d7bf7bad138c3497 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600.h
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600.h
@@ -205,7 +205,7 @@ struct inv_icm45600_sensor_state {
 #define INV_ICM45600_SPI_SLEW_RATE_38NS			0
 
 #define INV_ICM45600_REG_INT1_CONFIG2			0x0018
-#define INV_ICM45600_INT1_CONFIG2_PUSH_PULL		BIT(2)
+#define INV_ICM45600_INT1_CONFIG2_OPEN_DRAIN		BIT(2)
 #define INV_ICM45600_INT1_CONFIG2_LATCHED		BIT(1)
 #define INV_ICM45600_INT1_CONFIG2_ACTIVE_HIGH		BIT(0)
 #define INV_ICM45600_INT1_CONFIG2_ACTIVE_LOW		0x00
diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
index ab1cb7b9dba435a3280e50ab77cd16e903c7816c..b028044d609a41f6d4b747383323130ded0d2e79 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
@@ -637,8 +637,8 @@ static int inv_icm45600_irq_init(struct inv_icm45600_state *st, int irq,
 		break;
 	}
 
-	if (!open_drain)
-		val |= INV_ICM45600_INT1_CONFIG2_PUSH_PULL;
+	if (open_drain)
+		val |= INV_ICM45600_INT1_CONFIG2_OPEN_DRAIN;
 
 	ret = regmap_write(st->map, INV_ICM45600_REG_INT1_CONFIG2, val);
 	if (ret)

---
base-commit: d820183f371d9aa8517a1cd21fe6edacf0f94b7f
change-id: 20260205-inv-icm45600-fix-int1-drive-bit-7d12ea3e2cd2

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

