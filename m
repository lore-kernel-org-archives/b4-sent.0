From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 26 May 2026 13:15:29 +0200
Subject: [PATCH] iio: light: opt3001: fix missing state reset on timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260526-fix-early-return-v1-1-c70e886329f3@gmail.com>
X-B4-Tracking: v=1; b=H4sIANCAFWoC/x2MQQqAMAzAviI9W9gqDvEr4kG0akGmdCrK2N8dH
 gNJIgRW4QBtEUH5liC7z2DLAsZ18AujTJmBDDlTk8NZHuRBtxeVz0s9Ms12qpwj2xjI2aGcnX/
 Z9Sl9llFvmWIAAAA=
X-Change-ID: 20260526-fix-early-return-e2f1d3662180
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Valek - 2N <valek@2n.cz>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, Sashiko <sashiko-bot@kernel.org>, 
 stable@vger.kernel.org, Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779794147; l=1681;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=t1vAsfv7B7LZdWUZQljLoYaL7Vobksl8g4LhkH8Ck5M=;
 b=2yocHaz4/GslAVgqXwiLfzhUVXdUsmZd3OY3tNGHW2oaS7yNIUt1roT9g9QfPzimU3oczQ1yQ
 F93sH8jlbP/BAMTTjGjeAdxRFRJGGH/BPF8ahmdXgjbsmIDul1w/9hs
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently in the function opt3001_get_processed(), there is a check
that directly returns -ETIMEDOUT if the conversion IRQ times out,
completely bypassing the err label, leaving ok_to_ignore_lock
permanently true, potentially breaking the device's falling threshold
interrupt detection.

Assign -ETIMEDOUT to the return variable and jump to the error label
to ensure ok_to_ignore_lock is properly reset.

Fixes: 26d90b559057 ("iio: light: opt3001: Fixed timeout error when 0 lux")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20260525-opt3001-cleanup-v4-0-65b36a174f78%40gmail.com?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 03c7a87b4a8eef13bbdcf48dcaf969781aa76bd1..0743e16f2a8fa0f07acd19c7dd6b54bec9e5c7b2 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -366,8 +366,10 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 		ret = wait_event_timeout(opt->result_ready_queue,
 				opt->result_ready,
 				msecs_to_jiffies(OPT3001_RESULT_READY_LONG));
-		if (ret == 0)
-			return -ETIMEDOUT;
+		if (ret == 0) {
+			ret = -ETIMEDOUT;
+			goto err;
+		}
 	} else {
 		/* Sleep for result ready time */
 		timeout = (opt->int_time == OPT3001_INT_TIME_SHORT) ?

---
base-commit: 0e7dbde323808f28c5220295bfc1c5bc6f08c3f4
change-id: 20260526-fix-early-return-e2f1d3662180

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

