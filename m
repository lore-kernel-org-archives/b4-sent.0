From: Radu Sabau <radu.sabau@analog.com>
Date: Fri, 23 Oct 2026 12:30:20 +0300
Subject: [PATCH v4 3/8] iio: imu: adis: Add optional post_reset_setup
 callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-adis16607-v4-3-a4d541ebfd13@analog.com>
References: <20261023-adis16607-v4-0-a4d541ebfd13@analog.com>
In-Reply-To: <20261023-adis16607-v4-0-a4d541ebfd13@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792747820; l=2254;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=AxyPMdWe1dfHmRZJ8557DpedZhOiyzpzTaIVnfJheV8=;
 b=FZXhlGaYJE1OPG3ofpX4RgWCnZf6/yfkixVe6xYjUp/sgvByJFsh1LO9NEQu5KAw2U3UYHodq
 xTliY6bzpeoCMBmJtCPDVLcHFkc23PjHo3ax/yy0Q3gfmtXj2bnplTd
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an optional post_reset_setup callback to struct adis_data, called
right after reset and before self-test. Not all ADIS devices need
extra bring-up between reset and self-test (SPI mode locking, status
or bootloader checks, pin or burst-mode configuration, etc.) - purely
additive: defaults to NULL, no change for existing drivers.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis.c       | 6 ++++++
 include/linux/iio/imu/adis.h | 7 +++++++
 2 files changed, 13 insertions(+)

diff --git a/drivers/iio/imu/adis.c b/drivers/iio/imu/adis.c
index 5c3bb7259037..332cc7b0ff35 100644
--- a/drivers/iio/imu/adis.c
+++ b/drivers/iio/imu/adis.c
@@ -419,6 +419,12 @@ int __adis_initial_startup(struct adis *adis)
 		msleep(timeouts->sw_reset_ms);
 	}
 
+	if (adis->data->post_reset_setup) {
+		ret = adis->data->post_reset_setup(adis);
+		if (ret)
+			return ret;
+	}
+
 	ret = adis_self_test(adis);
 	if (ret)
 		return ret;
diff --git a/include/linux/iio/imu/adis.h b/include/linux/iio/imu/adis.h
index c09b381eb619..3d7c7febaec6 100644
--- a/include/linux/iio/imu/adis.h
+++ b/include/linux/iio/imu/adis.h
@@ -52,6 +52,12 @@ struct adis_timeout {
  * @self_test_mask: Bitmask of supported self-test operations
  * @self_test_reg: Register address to request self test command
  * @self_test_no_autoclear: True if device's self-test needs clear of ctrl reg
+ * @post_reset_setup: Optional device-specific hook called after reset,
+ *		before self-test. Not all ADIS devices need extra bring-up
+ *		between reset and self-test (SPI mode locking, status or
+ *		bootloader checks, pin or burst-mode configuration, etc.) -
+ *		only called when set. Must return 0 on success, a negative
+ *		error code otherwise.
  * @self_test: Optional device-specific self-test override. When set,
  *		it is called instead of the generic mask-write/sleep/
  *		check-status sequence. The callback owns its own pass/fail
@@ -88,6 +94,7 @@ struct adis_data {
 	unsigned int self_test_mask;
 	unsigned int self_test_reg;
 	bool self_test_no_autoclear;
+	int (*post_reset_setup)(struct adis *adis);
 	int (*self_test)(struct adis *adis);
 	const struct adis_timeout *timeouts;
 

-- 
2.43.0

