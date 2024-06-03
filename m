From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 03 Jun 2024 19:23:06 +0300
Subject: [PATCH v5 8/9] iio: adc: ad7173: document sampling frequency
 behaviour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240603-ad4111-v5-8-9a9c54d9ac78@analog.com>
References: <20240603-ad4111-v5-0-9a9c54d9ac78@analog.com>
In-Reply-To: <20240603-ad4111-v5-0-9a9c54d9ac78@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717431792; l=1618;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=2nPfloQlqJU5+9wFX+IL8WDN+iCUelg+ZAepCt2X+L0=;
 b=SsK8XFss3iJYziP1y5sS5l3QzebH9uY+AORf8T9s/7lhH8rpA6oEnNUH1DfBCn/Ic65KvcZWb
 jZ+cb59m+lmBUzYSlGSJ9TGhySH/gYyl04gwy6fYROu4F8rXClT5uUx
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADCs supported by this driver feature a sequencer that read in a
loop all the enabled chanels. When setting the individual sampling
frequency for each channel and enabling multiple channels, the effective
of each channel will be lower than the actual set value. Document this
behaviour in a comment.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 5ade166814d7..fb18acc83f39 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -742,6 +742,21 @@ static int ad7173_write_raw(struct iio_dev *indio_dev,
 		return ret;
 
 	switch (info) {
+	/*
+	 * This attribute sets the sampling frequency for each channel individually.
+	 * There are no issues for raw or buffered reads of an individual channel.
+	 *
+	 * When multiple channels are enabled in buffered mode, the effective
+	 * sampling rate of a channel is lowered in correlation to the number
+	 * of channels enabled and the sampling rate of the other channels.
+	 *
+	 * Example: 3 channels enabled with rates CH1:6211sps CH2,CH3:10sps
+	 * While the reading of CH1 takes only 0.16ms, the reading of CH2 and CH3
+	 * will take 100ms each.
+	 *
+	 * This will cause the reading of CH1 to be actually done once every
+	 * 200.16ms, an effective rate of 4.99sps.
+	 */
 	case IIO_CHAN_INFO_SAMP_FREQ:
 		freq = val * MILLI + val2 / MILLI;
 		for (i = st->info->odr_start_value; i < st->info->num_sinc5_data_rates - 1; i++)

-- 
2.43.0

