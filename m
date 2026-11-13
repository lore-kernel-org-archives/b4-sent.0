From: Radu Sabau <radu.sabau@analog.com>
Date: Fri, 13 Nov 2026 14:33:32 +0200
Subject: [PATCH v6 2/8] iio: imu: adis: Add optional self_test callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261113-adis16607-v6-2-3f678719942a@analog.com>
References: <20261113-adis16607-v6-0-3f678719942a@analog.com>
In-Reply-To: <20261113-adis16607-v6-0-3f678719942a@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Robert Budai <robert.budai@analog.com>, 
 Ramona Gradinariu <ramona.gradinariu@analog.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux@analog.com, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794573212; l=2180;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=tkzZy4kOyhyn9i1xmuSSgwdCRKGw+8zTfZiJqELNqH0=;
 b=pgGvzwGmPoVM16HB7sUAC2LP9nqntZF5PN0k0yM2o5UPUqVvReJUbCfcq/vKKOx3YVThrgip7
 Wdp3WD1OlFXBlfPoTN6FVg7QHkoq0+t831iS30Rm1+9QpbsB5B5DOSt
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an optional self_test callback to struct adis_data, for devices
whose self-test doesn't fit the generic mask-write/sleep/check-status
sequence. Purely additive: defaults to NULL, no change for existing
drivers.

Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis.c       | 3 +++
 include/linux/iio/imu/adis.h | 7 +++++++
 2 files changed, 10 insertions(+)

diff --git a/drivers/iio/imu/adis.c b/drivers/iio/imu/adis.c
index 793e3b6b0ea7..5c3bb7259037 100644
--- a/drivers/iio/imu/adis.c
+++ b/drivers/iio/imu/adis.c
@@ -357,6 +357,9 @@ static int adis_self_test(struct adis *adis)
 	int ret;
 	const struct adis_timeout *timeouts = adis->data->timeouts;
 
+	if (adis->data->self_test)
+		return adis->data->self_test(adis);
+
 	ret = __adis_write_reg_16(adis, adis->data->self_test_reg,
 				  adis->data->self_test_mask);
 	if (ret) {
diff --git a/include/linux/iio/imu/adis.h b/include/linux/iio/imu/adis.h
index 97323b8d1cb3..c09b381eb619 100644
--- a/include/linux/iio/imu/adis.h
+++ b/include/linux/iio/imu/adis.h
@@ -52,6 +52,12 @@ struct adis_timeout {
  * @self_test_mask: Bitmask of supported self-test operations
  * @self_test_reg: Register address to request self test command
  * @self_test_no_autoclear: True if device's self-test needs clear of ctrl reg
+ * @self_test: Optional device-specific self-test override. When set,
+ *		it is called instead of the generic mask-write/sleep/
+ *		check-status sequence. The callback owns its own pass/fail
+ *		determination entirely (it should call __adis_check_status()
+ *		itself if it wants status-register checks). Must return 0 on
+ *		success, a negative error code otherwise.
  * @status_error_msgs: Array of error messages
  * @status_error_mask: Bitmask of errors supported by the device
  * @timeouts: Chip specific delays
@@ -82,6 +88,7 @@ struct adis_data {
 	unsigned int self_test_mask;
 	unsigned int self_test_reg;
 	bool self_test_no_autoclear;
+	int (*self_test)(struct adis *adis);
 	const struct adis_timeout *timeouts;
 
 	const char * const *status_error_msgs;

-- 
2.43.0

