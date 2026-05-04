From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:17 +0200
Subject: [PATCH v4 05/17] iio: magnetometer: ak8975: fix wrong errno on
 return
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-5-a291c2a7c71a@gmail.com>
References: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
In-Reply-To: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888111; l=2202;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=9ktKUq7LUuC30Nz9Y4JUVYutq/hQ0HQt0x6idr2JCxo=;
 b=MsXORgSWCSqZKGyJVv3GS3nKQXvavEmrU1hMGojhecTzGE/QwyuoYgmDE8/Bhs2PyAbl8sq27
 2aMk+sJm+9GDIYpC+1jWDFmNEBNBpUeULIXjlOFahDmEHy6d3WfPAQF
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver currently returns -EINVAL on polling timeout instead of
-ETIMEDOUT.

Replace return code for -ETIMEDOUT and remove unnecessary error
message as -ETIMEDOUT is a standard POSIX error. Also replace
instances of -EINVAL in comments.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Co-developed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 16 ++++++----------
 1 file changed, 6 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 6ca8c24b9fba452b6fed8155957a8e5fcbc6511c..57f50c09cca539c3733f516a1617375e9134c349 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -662,10 +662,8 @@ static int wait_conversion_complete_gpio(struct ak8975_data *data)
 			break;
 		timeout_ms -= AK8975_CONVERSION_DONE_POLL_TIME;
 	}
-	if (!timeout_ms) {
-		dev_err(&client->dev, "Conversion timeout happened\n");
-		return -EINVAL;
-	}
+	if (!timeout_ms)
+		return -ETIMEDOUT;
 
 	ret = i2c_smbus_read_byte_data(client, data->def->ctrl_regs[ST1]);
 	if (ret < 0)
@@ -695,15 +693,13 @@ static int wait_conversion_complete_polled(struct ak8975_data *data)
 			break;
 		timeout_ms -= AK8975_CONVERSION_DONE_POLL_TIME;
 	}
-	if (!timeout_ms) {
-		dev_err(&client->dev, "Conversion timeout happened\n");
-		return -EINVAL;
-	}
+	if (!timeout_ms)
+		return -ETIMEDOUT;
 
 	return read_status;
 }
 
-/* Returns 0 if the end of conversion interrupt occurred or -ETIME otherwise */
+/* Returns 0 if the end of conversion interrupt occurred or -ETIMEDOUT otherwise */
 static int wait_conversion_complete_interrupt(struct ak8975_data *data)
 {
 	int ret;
@@ -713,7 +709,7 @@ static int wait_conversion_complete_interrupt(struct ak8975_data *data)
 				 AK8975_DATA_READY_TIMEOUT);
 	clear_bit(0, &data->flags);
 
-	return ret > 0 ? 0 : -ETIME;
+	return ret > 0 ? 0 : -ETIMEDOUT;
 }
 
 static int ak8975_start_read_axis(struct ak8975_data *data,

-- 
2.47.3

