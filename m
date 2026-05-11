From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 12:04:07 +0200
Subject: [PATCH 2/7] iio: light: opt3001: use macros from bits.h header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-opt3001-cleanup-v1-2-f7879dc3455c@gmail.com>
References: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
In-Reply-To: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=1682;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=zkqAxPRq6/NV7Ilc+m0WZWAlcRf1i5Dhxp0SPGrlRjQ=;
 b=0ZeX+lchsOcqZ4Qd3Ks6hyYrVBLNiiotTh2GxqSFczFkylWut1VavjFcFW0qK2tAALw7WdIv1
 uflqOVaB6LDDUQV0UzW+VB+Fhvli6Kd1dwhpJ/kAwMUGe3jjRMUBgKu
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use GENMASK() and BIT() macros from bits.h header where it makes
sense. While at it, remove unused macro.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index e6c3665f46be47129097c3997c7551ba9a8f6440..47f0e01a95e772954de0f1337ac0d881b8b32de6 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -33,17 +33,16 @@
 #define OPT3001_MANUFACTURER_ID	0x7e
 #define OPT3001_DEVICE_ID	0x7f
 
-#define OPT3001_CONFIGURATION_RN_MASK	(0xf << 12)
+#define OPT3001_CONFIGURATION_RN_MASK	GENMASK(15, 12)
 #define OPT3001_CONFIGURATION_RN_AUTO	(0xc << 12)
 
 #define OPT3001_CONFIGURATION_CT	BIT(11)
 
-#define OPT3001_CONFIGURATION_M_MASK	(3 << 9)
+#define OPT3001_CONFIGURATION_M_MASK	GENMASK(10, 9)
 #define OPT3001_CONFIGURATION_M_SHUTDOWN (0 << 9)
-#define OPT3001_CONFIGURATION_M_SINGLE	(1 << 9)
+#define OPT3001_CONFIGURATION_M_SINGLE	BIT(9)
 #define OPT3001_CONFIGURATION_M_CONTINUOUS (2 << 9) /* also 3 << 9 */
 
-#define OPT3001_CONFIGURATION_OVF	BIT(8)
 #define OPT3001_CONFIGURATION_CRF	BIT(7)
 #define OPT3001_CONFIGURATION_FH	BIT(6)
 #define OPT3001_CONFIGURATION_FL	BIT(5)
@@ -51,7 +50,7 @@
 #define OPT3001_CONFIGURATION_POL	BIT(3)
 #define OPT3001_CONFIGURATION_ME	BIT(2)
 
-#define OPT3001_CONFIGURATION_FC_MASK	(3 << 0)
+#define OPT3001_CONFIGURATION_FC_MASK	GENMASK(1, 0)
 
 /* The end-of-conversion enable is located in the low-limit register */
 #define OPT3001_LOW_LIMIT_EOC_ENABLE	0xc000

-- 
2.47.3

