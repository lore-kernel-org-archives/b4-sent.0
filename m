From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 07 May 2026 16:35:51 +0200
Subject: [PATCH 2/8] iio: magnetometer: ak8975: check if gpiod read was
 successful
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-magnetometer-fixes-post-pickup-v1-2-37827ca68fb3@gmail.com>
References: <20260507-magnetometer-fixes-post-pickup-v1-0-37827ca68fb3@gmail.com>
In-Reply-To: <20260507-magnetometer-fixes-post-pickup-v1-0-37827ca68fb3@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778164567; l=936;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=rgh2T/BraT11/1sDogsM03wH+GIDtJpudp0bLFkpppg=;
 b=kw14rqVLrLwHvzqYtMWqjVGldMXWJUomqSjyqG61K4vLS/7Ka67Bzq6yOzxmV41FVGQreapZV
 4eV+neL0kYTBvgWhS4KY2yovbAT6BZ6w8CKaGkG41bAO9Ilred5zCCp
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a check that ensures that valid data has been read from GPIOD. If
not, log an error and return the negative read value.

Suggested-by: Jonathan Cameron <jic23@kernel.org>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index b990c123e2808c2078abcfaf6b2ef86c09393e6b..63b6e8465f5f3873841550a1cd03ce86b95d1d67 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -658,6 +658,10 @@ static int wait_conversion_complete_gpio(struct ak8975_data *data,
 				 timeout_ms * USEC_PER_MSEC);
 	if (ret)
 		return ret;
+	if (val < 0) {
+		dev_err(&client->dev, "Error in reading GPIOD\n");
+		return val;
+	}
 
 	ret = i2c_smbus_read_byte_data(client, data->def->ctrl_regs[ST1]);
 	if (ret < 0)

-- 
2.47.3

