From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Fri, 15 May 2026 12:28:23 +0200
Subject: [PATCH v2] iio: magnetometer: ak8975: fix potential kernel stack
 memory leak
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-magnetometer-kernel-mem-leak-v2-1-320e1ad4843d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEb1BmoC/43NQQ6CMBCF4auYWTuGViDFlfcwLEY6wATampYQD
 eHuVk7g8nuL/22QOAonuJ02iLxKkuAz9PkE3Uh+YBSbDbrQdVGpEh0NnpfgeOGIE0fPMzp2ODN
 NaI0hU1ltqC4gJ16Re3kf+UebPUpaQvwcb6v6rX+GV4UKr9WzNLZump76++BI5ksXHLT7vn8BC
 3Pz5MgAAAA=
X-Change-ID: 20260514-magnetometer-kernel-mem-leak-d88a85d28a60
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Gregor Boirie <gregor.boirie@parrot.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sashiko <sashiko-bot@kernel.org>, stable@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778840936; l=2859;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=DGUZ8ICq5s3dP8tVuyORKa78JXv6M2/K7bYZ13VS8lM=;
 b=WIr5H10DW5ZEdrIL5D81+NvLroUVPHffahavXKKec3pqdz7IrlycqW8IFlmV2j3w92IeXyTtW
 p2SU1eYxSOnD73S1Qwzt9d5kOmNpdg+UNzB/8ADA9aqgGJo302QQfn2
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently in the AK8975 driver there are four instances where potential
uninitialized kernel stack memory leaks can occur. If
i2c_smbus_read_i2c_block_data_or_emulated() returns a value less than
the size of the buffer, uninitialized bytes are retained in the buffer
and later the buffer is passed on to IIO buffers, potentially leaking
memory to userspace.

Fix this by adding checks whether the return value of the function is
equal to the size of the buffer and subsequently if the value is
lesser than zero to distinguish from a returned error code.

Fixes: bc11ca4a0b84 ("iio:magnetometer:ak8975: triggered buffer support")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20260513-ak8975-fix-v1-1-104ea605dd54%40gmail.com
Cc: stable@vger.kernel.org
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
Changes in v2:
- Added 2 additional checks
- Removed nested if statements
- Link to v1: https://lore.kernel.org/r/20260514-magnetometer-kernel-mem-leak-v1-1-35b48d699faf@gmail.com
---
 drivers/iio/magnetometer/ak8975.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index b648b0afa5733fd7a54bdf2b8f92f00e924c074b..e085c5a6583dfe40c653abf4936594a5acd08f51 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -495,6 +495,10 @@ static int ak8975_who_i_am(struct i2c_client *client,
 		dev_err(&client->dev, "Error reading WIA\n");
 		return ret;
 	}
+	if (ret != sizeof(wia_val)) {
+		dev_err(&client->dev, "Error reading WIA\n");
+		return -EIO;
+	}
 
 	if (wia_val[0] != AK8975_DEVICE_ID)
 		return -ENODEV;
@@ -619,6 +623,10 @@ static int ak8975_setup(struct i2c_client *client)
 		dev_err(&client->dev, "Not able to read asa data\n");
 		return ret;
 	}
+	if (ret != sizeof(data->asa)) {
+		dev_err(&client->dev, "Error reading asa data\n");
+		return -EIO;
+	}
 
 	/* After reading fuse ROM data set power-down mode */
 	ret = ak8975_set_mode(data, POWER_DOWN);
@@ -758,6 +766,10 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 			sizeof(rval), (u8*)&rval);
 	if (ret < 0)
 		goto exit;
+	if (ret != sizeof(rval)) {
+		ret = -EIO;
+		goto exit;
+	}
 
 	/* Read out ST2 for release lock on measurement data. */
 	ret = i2c_smbus_read_byte_data(client, data->def->ctrl_regs[ST2]);
@@ -873,6 +885,8 @@ static void ak8975_fill_buffer(struct iio_dev *indio_dev)
 							(u8 *)fval);
 	if (ret < 0)
 		goto unlock;
+	if (ret != sizeof(fval))
+		goto unlock;
 
 	mutex_unlock(&data->lock);
 

---
base-commit: 86138b484d6367a57312f69af4ec958806c2673c
change-id: 20260514-magnetometer-kernel-mem-leak-d88a85d28a60

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

