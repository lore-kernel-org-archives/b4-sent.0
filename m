From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Wed, 29 Apr 2026 17:04:54 +0200
Subject: [PATCH v3 6/8] iio: light: si1133: add local variable for timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-si1133-checkup-v3-6-469f21d960eb@gmail.com>
References: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
In-Reply-To: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777475147; l=1252;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=iQP88I6gwVGTwRDphxjIwdJr1kTAAQWffLw4TQszN6k=;
 b=zTiBost0YlvK3XbHuAiNx79dFexGpDB9KWK63Qka+PcE6GQD6XhW+PKHMM6eyCNfLjgXJ7BHP
 06HM54tKl7hC6sfSpF2FP3FsXH5J2ckEQCBn8mfnqgvksU3dwbNz7eE
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add local variable for timeout to improve readability.

No functional change.

Suggested-by: Jonathan Cameron <jic23@kernel.org>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index 939189d8c18a85ad64d8c05dfb83b5989f524791..471692057b0f16c82946507bf7d23a0004f80bf0 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -391,6 +391,7 @@ static int si1133_cmd_reset_counter(struct si1133_data *data)
 
 static int si1133_command(struct si1133_data *data, u8 cmd)
 {
+	unsigned long timeout = msecs_to_jiffies(SI1133_COMPLETION_TIMEOUT_MS);
 	struct device *dev = &data->client->dev;
 	u32 resp;
 	int err;
@@ -412,8 +413,7 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 
 	if (cmd == SI1133_CMD_FORCE) {
 		/* wait for irq */
-		if (!wait_for_completion_timeout(&data->completion,
-			msecs_to_jiffies(SI1133_COMPLETION_TIMEOUT_MS)))
+		if (!wait_for_completion_timeout(&data->completion, timeout))
 			return -ETIMEDOUT;
 		err = regmap_read(data->regmap, SI1133_REG_RESPONSE0, &resp);
 		if (err)

-- 
2.47.3

