From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 12:04:11 +0200
Subject: [PATCH 6/7] iio: light: opt3001: remove unnecessary comments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-opt3001-cleanup-v1-6-f7879dc3455c@gmail.com>
References: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
In-Reply-To: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=1455;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=CvHqUzEKYCIaa3N5Ba+LTLV0AD0IUgdZt4E0WfgOkO0=;
 b=kq+ViCYTpJEMuFKTmLB8xYd+E7aaOT2pMcseoIDJy1ikaxaUa82+PpyppDf8eTy1eTKdgBeqn
 0SX0Hl8VCUHCP73MvCV+nXy13peu0xGFU+h/9l6Qnt5It/Sg8zwkMVH
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unnecessary comments as code is self explanatory.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 3719757f6ed7784cbf2e4aa659e5c69a39b0cce2..155794bb28f68a945e20b083e382561ca6ad462e 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -369,7 +369,6 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 		if (ret == 0)
 			return -ETIMEDOUT;
 	} else {
-		/* Sleep for result ready time */
 		timeout = (opt->int_time == OPT3001_INT_TIME_SHORT) ?
 			OPT3001_RESULT_READY_SHORT : OPT3001_RESULT_READY_LONG;
 		msleep(timeout);
@@ -388,7 +387,6 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 			goto err;
 		}
 
-		/* Obtain value */
 		ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_RESULT);
 		if (ret < 0) {
 			dev_err(opt->dev, "failed to read register %02x\n",
@@ -919,7 +917,7 @@ static const struct opt3001_chip_info opt3002_chip_information = {
 static const struct i2c_device_id opt3001_id[] = {
 	{ "opt3001", (kernel_ulong_t)&opt3001_chip_information },
 	{ "opt3002", (kernel_ulong_t)&opt3002_chip_information },
-	{ } /* Terminating Entry */
+	{ }
 };
 MODULE_DEVICE_TABLE(i2c, opt3001_id);
 

-- 
2.47.3

