From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 13:46:00 +0200
Subject: [PATCH v5 04/18] iio: magnetometer: ak8975: change 'u8*' to 'u8 *'
 in cast
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-magnetometer-fixes-v5-4-831b9b5550fc@gmail.com>
References: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
In-Reply-To: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777981558; l=1056;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=Wdt8KANnDoSFXBcgrJIrMksQrP9sjlwOf4hExOFf40Y=;
 b=M7KAiGPTTXPM3TeKKNkwu0h0VKki3nc7Ksn7ZOWxI5nq8pa0kF+5UyDj4bc4dvZQGC2NwY1+f
 06jKMy6kTxHDwVmsUGmVWfVohTE0uk+C0LTNdF7yLbP4BEhB+5X6SM6
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change 'u8*' cast to 'u8 *' as the former triggers a checkpatch error.
Also fix the indentation of parameters in
i2c_smbus_read_i2c_block_data_or_emulated() function.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index a84a05a1b64280e26c428e9752a39380e386c234..6ca8c24b9fba452b6fed8155957a8e5fcbc6511c 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -759,9 +759,10 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 	if (ret)
 		goto exit;
 
-	ret = i2c_smbus_read_i2c_block_data_or_emulated(
-			client, def->data_regs[index],
-			sizeof(rval), (u8*)&rval);
+	ret = i2c_smbus_read_i2c_block_data_or_emulated(client,
+							def->data_regs[index],
+							sizeof(rval),
+							(u8 *)&rval);
 	if (ret < 0)
 		goto exit;
 

-- 
2.47.3

