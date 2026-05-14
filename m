From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 14 May 2026 13:38:17 +0200
Subject: [PATCH] iio: magnetometer: ak8975: fix potential kernel stack
 memory leak
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-magnetometer-kernel-mem-leak-v1-1-35b48d699faf@gmail.com>
X-B4-Tracking: v=1; b=H4sIACi0BWoC/x3MQQqDMBAF0KvIrB2IoUroVYqLwfzaQRPLREQQ7
 97Q5du8iwpMUejZXGQ4tOiWK7q2oekjeQZrrCbv/OD67sFJ5ox9S9hhvMAyVk5IvEIWjiFI6KM
 PMjiqxdfw1vPfv8b7/gHj0abRbgAAAA==
X-Change-ID: 20260514-magnetometer-kernel-mem-leak-d88a85d28a60
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Gregor Boirie <gregor.boirie@parrot.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sashiko <sashiko-bot@kernel.org>, stable@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778758707; l=2174;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=GqOXxU45elozlqyCiK4X26ELkyrFrvZVLWhrLgBFlvc=;
 b=h31IQxZQ1kG/gxFRDpDa3i+MGZyJqxMm3jAJuJz+YEASakyBIDnUtnqy8/JHJeyuFbOYXG5v5
 +ebElN3ACRHCyFhMu0LVJZRA04GwZ5fLrL8Z3pnLhF9rcOMyP81LvR3
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently in the AK8975 driver there are two instances where potential
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
 drivers/iio/magnetometer/ak8975.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index b648b0afa5733fd7a54bdf2b8f92f00e924c074b..9d23c8136291a52ca9ab928d81332aa32933fec6 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -756,8 +756,11 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 	ret = i2c_smbus_read_i2c_block_data_or_emulated(
 			client, def->data_regs[index],
 			sizeof(rval), (u8*)&rval);
-	if (ret < 0)
+	if (ret != sizeof(rval)) {
+		if (ret >= 0)
+			ret = -EIO;
 		goto exit;
+	}
 
 	/* Read out ST2 for release lock on measurement data. */
 	ret = i2c_smbus_read_byte_data(client, data->def->ctrl_regs[ST2]);
@@ -871,8 +874,11 @@ static void ak8975_fill_buffer(struct iio_dev *indio_dev)
 							def->data_regs[0],
 							3 * sizeof(fval[0]),
 							(u8 *)fval);
-	if (ret < 0)
+	if (ret != sizeof(fval)) {
+		if (ret >= 0)
+			ret = -EIO;
 		goto unlock;
+	}
 
 	mutex_unlock(&data->lock);
 

---
base-commit: 86138b484d6367a57312f69af4ec958806c2673c
change-id: 20260514-magnetometer-kernel-mem-leak-d88a85d28a60

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

