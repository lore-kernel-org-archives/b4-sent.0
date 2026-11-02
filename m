From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 02 Nov 2026 11:25:37 +0200
Subject: [PATCH v5 1/8] iio: imu: adis: Fix custom reset dispatch in
 adislib
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261102-adis16607-v5-1-4f98b0d271ac@analog.com>
References: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
In-Reply-To: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux@analog.com, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793611539; l=2794;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=SC/SubIQdTMZFTL014FlawEjYwq6iuRw3fYYRQBfK7Q=;
 b=NEgpqLVygM+nDG23xfzaxjfKjvQRdtQbJuMROEdwQsTVjoTgn14nHNkmiFqPWdIAdzQrqfIHl
 kVAdCY0RIAYA9qRllp1or/SSu4peU5owNr2voTIpnyrgscXAi9GoIp9
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__adis_initial_startup()'s no-reset-gpio path called __adis_reset()
directly instead of adis->ops->reset(), silently ignoring any driver's
custom reset implementation. Invisible until now since
adis_default_ops.reset is __adis_reset() itself. Dispatch through
adis->ops->reset() instead - the same bug existed in the public
adis_reset() wrapper, fixed here too.

Move the settle-time sleep out of __adis_reset() and into both call
sites instead, so every reset op (default or custom) is treated
uniformly: adis->ops->reset() is expected to just do the write, and
the library always sleeps the settle time afterwards. This removes
the previous asymmetric "sleep here only for custom ops" special
case entirely.

Fixes: ecb010d44108 ("iio: imu: adis: Refactor adis_initial_startup")
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis.c       |  6 ++----
 include/linux/iio/imu/adis.h | 12 +++++++++++-
 2 files changed, 13 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/imu/adis.c b/drivers/iio/imu/adis.c
index a2bc1d14ed91..793e3b6b0ea7 100644
--- a/drivers/iio/imu/adis.c
+++ b/drivers/iio/imu/adis.c
@@ -340,7 +340,6 @@ EXPORT_SYMBOL_NS_GPL(__adis_check_status, "IIO_ADISLIB");
 int __adis_reset(struct adis *adis)
 {
 	int ret;
-	const struct adis_timeout *timeouts = adis->data->timeouts;
 
 	ret = __adis_write_reg_8(adis, adis->data->glob_cmd_reg,
 				 ADIS_GLOB_CMD_SW_RESET);
@@ -349,8 +348,6 @@ int __adis_reset(struct adis *adis)
 		return ret;
 	}
 
-	msleep(timeouts->sw_reset_ms);
-
 	return 0;
 }
 EXPORT_SYMBOL_NS_GPL(__adis_reset, "IIO_ADIS_LIB");
@@ -413,9 +410,10 @@ int __adis_initial_startup(struct adis *adis)
 		gpiod_set_value_cansleep(gpio, 0);
 		msleep(timeouts->reset_ms);
 	} else {
-		ret = __adis_reset(adis);
+		ret = adis->ops->reset(adis);
 		if (ret)
 			return ret;
+		msleep(timeouts->sw_reset_ms);
 	}
 
 	ret = adis_self_test(adis);
diff --git a/include/linux/iio/imu/adis.h b/include/linux/iio/imu/adis.h
index bfb6df68e6c9..97323b8d1cb3 100644
--- a/include/linux/iio/imu/adis.h
+++ b/include/linux/iio/imu/adis.h
@@ -10,6 +10,7 @@
 #define __IIO_ADIS_H__
 
 #include <linux/cleanup.h>
+#include <linux/delay.h>
 #include <linux/spi/spi.h>
 #include <linux/interrupt.h>
 #include <linux/iio/iio.h>
@@ -171,8 +172,17 @@ int __adis_reset(struct adis *adis);
  */
 static inline int adis_reset(struct adis *adis)
 {
+	int ret;
+
 	guard(mutex)(&adis->state_lock);
-	return __adis_reset(adis);
+
+	ret = adis->ops->reset(adis);
+	if (ret)
+		return ret;
+
+	msleep(adis->data->timeouts->sw_reset_ms);
+
+	return 0;
 }
 
 int __adis_write_reg(struct adis *adis, unsigned int reg,

-- 
2.43.0

