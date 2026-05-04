From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:22 +0200
Subject: [PATCH v4 10/17] iio: magnetometer: ak8975: remove duplicate error
 message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-10-a291c2a7c71a@gmail.com>
References: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
In-Reply-To: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888112; l=1086;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=z9DRykPnGYvT6CD8nI23X4tG9TQg6CGBxpeXGPGfMa8=;
 b=YpFqTWYwylZsbWv8RaO4XMob29BCL15Oaz2iPgryOjSeEJOxIsvDE8rQ1DWuKR7OGoX+x9X6l
 QPpysEFvFvDChS9n8T66IfjQHmw5XH378fkI1WcnQdY1LE334KD4NZY
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

The devm_request_irq() already prints an error message.
Remove the duplicate.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index b94b0486421873a4afa41949d956e0bb5dafdb9d..c354ebaba11c86c24ebe2dbc2b20c11f18015151 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -584,17 +584,14 @@ static int ak8975_setup_irq(struct ak8975_data *data)
 	rc = devm_request_irq(&client->dev, irq, ak8975_irq_handler,
 			      IRQF_TRIGGER_RISING,
 			      dev_name(&client->dev), data);
-	if (rc < 0) {
-		dev_err(&client->dev, "irq %d request failed: %d\n", irq, rc);
+	if (rc < 0)
 		return rc;
-	}
 
 	data->eoc_irq = irq;
 
 	return rc;
 }
 
-
 /*
  * Perform some start-of-day setup, including reading the asa calibration
  * values and caching them.

-- 
2.47.3

