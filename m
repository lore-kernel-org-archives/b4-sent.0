From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 15 Oct 2026 13:49:45 -0300
Subject: [PATCH 05/10] iio: frequency: ad9910: move channel indexes into a
 shared header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-ad9910-backend-support-v1-5-3c21648c8e26@analog.com>
References: <20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com>
In-Reply-To: <20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792082993; l=4329;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=VsqJQc+ePynwFhVyVl6Uf/Qo3uusPG2hDGbHDjQCWp0=;
 b=/CtkwCFECJiXQy82RHizUoY1L5pL8v0dEkVDf9WFdxSwKGcRXjmJODpFTeuOxLWX176uDGKmM
 foVnVG0qwpzDe9lXDZj+Mnprl0WimFHjcChHUyMHzF9pnD1uTLBCupR
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The channel indexes are used as channel identifiers in IIO backend
operations, such as enabling a parallel data port destination or
selecting a profile. Move them, along with the data destination
definitions, into a shared header, so that the frontend and backend
drivers agree on those identifiers.

No functional change.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 MAINTAINERS                    |  1 +
 drivers/iio/frequency/ad9910.c | 35 ++-------------------------------
 drivers/iio/frequency/ad9910.h | 44 ++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 47 insertions(+), 33 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 93ad6a829cb3..a9cb4396b3e1 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1735,6 +1735,7 @@ F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910-axi-backend.yaml
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
 F:	Documentation/iio/ad9910.rst
 F:	drivers/iio/frequency/ad9910.c
+F:	drivers/iio/frequency/ad9910.h
 
 ANALOG DEVICES INC MAX22007 DRIVER
 M:	Janani Sunil <janani.sunil@analog.com>
diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 8bc24d0b7442..dc13986dff3d 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -33,6 +33,8 @@
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
 
+#include "ad9910.h"
+
 /* Register addresses */
 #define AD9910_REG_CFR1			0x00
 #define AD9910_REG_CFR2			0x01
@@ -194,11 +196,6 @@
 #define AD9910_RAM_ENABLED(st)		\
 	FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, (st)->reg[AD9910_REG_CFR1].val32)
 
-#define AD9910_DEST_FREQUENCY		0
-#define AD9910_DEST_PHASE		1
-#define AD9910_DEST_AMPLITUDE		2
-#define AD9910_DEST_POLAR		3
-
 /* PLL constants */
 #define AD9910_PLL_MIN_N		12
 #define AD9910_PLL_MAX_N		127
@@ -302,34 +299,6 @@ struct ad9910_ram_fw {
 	__be32 words[] __counted_by_be(wcount);
 } __packed;
 
-enum {
-	AD9910_CHAN_IDX_PHY,
-	AD9910_CHAN_IDX_PROFILE_0,
-	AD9910_CHAN_IDX_PROFILE_1,
-	AD9910_CHAN_IDX_PROFILE_2,
-	AD9910_CHAN_IDX_PROFILE_3,
-	AD9910_CHAN_IDX_PROFILE_4,
-	AD9910_CHAN_IDX_PROFILE_5,
-	AD9910_CHAN_IDX_PROFILE_6,
-	AD9910_CHAN_IDX_PROFILE_7,
-	AD9910_CHAN_IDX_PARALLEL_AMP,
-	AD9910_CHAN_IDX_PARALLEL_PHASE,
-	AD9910_CHAN_IDX_PARALLEL_FREQ,
-	AD9910_CHAN_IDX_PARALLEL_POLAR_AMP,
-	AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE,
-	AD9910_CHAN_IDX_DRG_FREQ,
-	AD9910_CHAN_IDX_DRG_PHASE,
-	AD9910_CHAN_IDX_DRG_AMP,
-	AD9910_CHAN_IDX_DRG_FREQ_RAMP_UP,
-	AD9910_CHAN_IDX_DRG_FREQ_RAMP_DOWN,
-	AD9910_CHAN_IDX_DRG_PHASE_RAMP_UP,
-	AD9910_CHAN_IDX_DRG_PHASE_RAMP_DOWN,
-	AD9910_CHAN_IDX_DRG_AMP_RAMP_UP,
-	AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN,
-	AD9910_CHAN_IDX_RAM,
-	AD9910_CHAN_IDX_OSK,
-};
-
 enum {
 	AD9910_POWERDOWN,
 	AD9910_DWELL_EN,
diff --git a/drivers/iio/frequency/ad9910.h b/drivers/iio/frequency/ad9910.h
new file mode 100644
index 000000000000..6452a8678ed9
--- /dev/null
+++ b/drivers/iio/frequency/ad9910.h
@@ -0,0 +1,44 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * AD9910 SPI DDS (Direct Digital Synthesizer) driver
+ *
+ * Copyright 2026 Analog Devices Inc.
+ */
+
+#ifndef IIO_FREQUENCY_AD9910_H_
+#define IIO_FREQUENCY_AD9910_H_
+
+#define AD9910_DEST_FREQUENCY		0
+#define AD9910_DEST_PHASE		1
+#define AD9910_DEST_AMPLITUDE		2
+#define AD9910_DEST_POLAR		3
+
+enum ad9910_channel_idx {
+	AD9910_CHAN_IDX_PHY,
+	AD9910_CHAN_IDX_PROFILE_0,
+	AD9910_CHAN_IDX_PROFILE_1,
+	AD9910_CHAN_IDX_PROFILE_2,
+	AD9910_CHAN_IDX_PROFILE_3,
+	AD9910_CHAN_IDX_PROFILE_4,
+	AD9910_CHAN_IDX_PROFILE_5,
+	AD9910_CHAN_IDX_PROFILE_6,
+	AD9910_CHAN_IDX_PROFILE_7,
+	AD9910_CHAN_IDX_PARALLEL_AMP,
+	AD9910_CHAN_IDX_PARALLEL_PHASE,
+	AD9910_CHAN_IDX_PARALLEL_FREQ,
+	AD9910_CHAN_IDX_PARALLEL_POLAR_AMP,
+	AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE,
+	AD9910_CHAN_IDX_DRG_FREQ,
+	AD9910_CHAN_IDX_DRG_PHASE,
+	AD9910_CHAN_IDX_DRG_AMP,
+	AD9910_CHAN_IDX_DRG_FREQ_RAMP_UP,
+	AD9910_CHAN_IDX_DRG_FREQ_RAMP_DOWN,
+	AD9910_CHAN_IDX_DRG_PHASE_RAMP_UP,
+	AD9910_CHAN_IDX_DRG_PHASE_RAMP_DOWN,
+	AD9910_CHAN_IDX_DRG_AMP_RAMP_UP,
+	AD9910_CHAN_IDX_DRG_AMP_RAMP_DOWN,
+	AD9910_CHAN_IDX_RAM,
+	AD9910_CHAN_IDX_OSK,
+};
+
+#endif /* IIO_FREQUENCY_AD9910_H_ */

-- 
2.43.0

