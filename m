From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 13:26:16 +0200
Subject: [PATCH v7 7/8] iio: magnetometer: ak8975: add scan mask index enum
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260511-magnetometer-fixes-post-pickup-v7-7-9d910faa28b6@gmail.com>
References: <20260511-magnetometer-fixes-post-pickup-v7-0-9d910faa28b6@gmail.com>
In-Reply-To: <20260511-magnetometer-fixes-post-pickup-v7-0-9d910faa28b6@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778498777; l=1586;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=ewbNSwOSC0k1f6ppPGABML5drGHyj3QXLXQNhui/6vk=;
 b=8vRWaFESnkMXRugrjFcALRwt5DYWjflVQqOWqkP3zlfVHojRl/4mj4qu4CU15TZTnIUh853Dn
 IefvZdhaYtGBZhYl6E7bDrL7VahKKYhZLtmu3SIX/Ei7qyATogaIFKe
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an enum to explicitly define scan mask indexes for the X, Y, Z and
timestamp channels. Also, update the struct iio_chan_spec to use said
enum for the .scan_index parameter.

This prevents magic numbers from obscuring the hardware channel mapping
and improves code style.

No functional change.

Suggested-by: Jonathan Cameron <jic23@kernel.org>
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 2267928a136912c901e604fe938e9a17c8cd5607..d87a98090c991508ac835839286da0371d689cd8 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -238,6 +238,13 @@ enum ak_ctrl_mode {
 	MODE_END,
 };
 
+enum ak_scan_index {
+	AK8975_SCAN_X,
+	AK8975_SCAN_Y,
+	AK8975_SCAN_Z,
+	AK8975_SCAN_TS,
+};
+
 struct ak_def {
 	enum asahi_compass_chipset type;
 	long (*raw_to_gauss)(u16 data);
@@ -835,8 +842,10 @@ static const struct iio_chan_spec_ext_info ak8975_ext_info[] = {
 	}
 
 static const struct iio_chan_spec ak8975_channels[] = {
-	AK8975_CHANNEL(X, 0), AK8975_CHANNEL(Y, 1), AK8975_CHANNEL(Z, 2),
-	IIO_CHAN_SOFT_TIMESTAMP(3),
+	AK8975_CHANNEL(X, AK8975_SCAN_X),
+	AK8975_CHANNEL(Y, AK8975_SCAN_Y),
+	AK8975_CHANNEL(Z, AK8975_SCAN_Z),
+	IIO_CHAN_SOFT_TIMESTAMP(AK8975_SCAN_TS),
 };
 
 static const unsigned long ak8975_scan_masks[] = { 0x7, 0 };

-- 
2.47.3

