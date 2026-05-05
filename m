From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 13:45:59 +0200
Subject: [PATCH v5 03/18] iio: magnetometer: ak8975: replace usleep_range()
 with fsleep()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-magnetometer-fixes-v5-3-831b9b5550fc@gmail.com>
References: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
In-Reply-To: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777981558; l=1188;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=pYNXSLcsScB1UFEjU4yV7Zvmf3IflZ84nydrNj+FmrM=;
 b=wvpjzx4+gaHs/FYy/Y7NJ62of+Dey/92o5FsA17FklklNFHVdaMH8Lxy/O65/HU3+uEwXljJW
 DI7Cq5uhJ7jD1QsR24OGh/SpwMqY9G/kipKBhBloPNaIAnKMN+wPLoZ
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace usleep_range() calls with fsleep(), passing the minimum value
required by the sensor for hardware delays.

fsleep() automatically selects the optimal sleep mechanism, simplifying
driver code and time management.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index dac0a90c33eebd43f8aeed846c9cbf5fd1a6ab91..a84a05a1b64280e26c428e9752a39380e386c234 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -461,7 +461,8 @@ static int ak8975_power_on(const struct ak8975_data *data)
 	 * and the minimum wait time before mode setting is 100us, in
 	 * total 300us. Add some margin and say minimum 500us here.
 	 */
-	usleep_range(500, 1000);
+	fsleep(500);
+
 	return 0;
 }
 
@@ -551,7 +552,7 @@ static int ak8975_set_mode(struct ak8975_data *data, enum ak_ctrl_mode mode)
 
 	data->cntl_cache = regval;
 	/* After mode change wait at least 100us */
-	usleep_range(100, 500);
+	fsleep(100);
 
 	return 0;
 }

-- 
2.47.3

