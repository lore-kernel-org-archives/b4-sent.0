From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 09:31:32 +0200
Subject: [PATCH v5 7/8] iio: light: si1133: add local variable for timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-si1133-checkup-v5-7-5df86a9024ed@gmail.com>
References: <20260505-si1133-checkup-v5-0-5df86a9024ed@gmail.com>
In-Reply-To: <20260505-si1133-checkup-v5-0-5df86a9024ed@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Jean-Francois Dagenais <jeff.dagenais@gmail.com>, 
 =?utf-8?q?Maxime_Roussin-B=C3=A9langer?= <maxime.roussinbelanger@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777966306; l=1250;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=/XJFGcdvil+2we7+TC+ip157GN0rAXA5yY6shTe6uEY=;
 b=0C7lCRmCfOweFgiVXLhrhvNfCyI0u26mSlQ8O++RVhUHIz35bIcTcpJk/ZJVaqhBIQ9boHZxs
 AiaKs2OKqsaB61zoA1MJoxxCLHakBnYUycxbbdU49jZYlxMNBo2d8OQ
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
index fdffdee16e493277d95c369ec2f6c0678cf9f61c..a3e4ab25acdc105d3800994f4391a7e4291e1c74 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -390,6 +390,7 @@ static int si1133_cmd_reset_counter(struct si1133_data *data)
 
 static int si1133_command(struct si1133_data *data, u8 cmd)
 {
+	unsigned long timeout = msecs_to_jiffies(SI1133_COMPLETION_TIMEOUT_MS);
 	struct device *dev = &data->client->dev;
 	u32 resp;
 	int err;
@@ -417,8 +418,7 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 
 	if (cmd == SI1133_CMD_FORCE) {
 		/* wait for irq */
-		if (!wait_for_completion_timeout(&data->completion,
-			msecs_to_jiffies(SI1133_COMPLETION_TIMEOUT_MS))) {
+		if (!wait_for_completion_timeout(&data->completion, timeout)) {
 			regmap_write(data->regmap, SI1133_REG_IRQ_ENABLE, 0);
 			err = -ETIMEDOUT;
 			goto out;

-- 
2.47.3

