From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Fri, 07 Jun 2024 17:53:14 +0300
Subject: [PATCH v7 8/9] iio: adc: ad7173: document sampling frequency
 behaviour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240607-ad4111-v7-8-97e3855900a0@analog.com>
References: <20240607-ad4111-v7-0-97e3855900a0@analog.com>
In-Reply-To: <20240607-ad4111-v7-0-97e3855900a0@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717771987; l=1661;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=mdKO2dnGlcZH90ri/TM/oMJLgoJ91RNSOsEvtEgKDAE=;
 b=ssITTpfL4Seggrz3KWXnnpHuG9ukbS4R2iLyMYPBuup1yGCnywGRhUXkj/E6iFDtX5Kj6l+gM
 kol/veezwmSDnCgal8fTjSB7b95rqbYhId/OvQiL7fgoiHv3wejYv9B
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADCs supported by this driver feature a sequencer that read in a
loop all the enabled chanels. When setting the individual sampling
frequency for each channel and enabling multiple channels, the effective
of each channel will be lower than the actual set value. Document this
behaviour in a comment.

Reviewed-by: Nuno Sa <nuno.sa@analog.com>
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 6ed5b8fed8c0..22dcf89ef3ef 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -732,6 +732,21 @@ static int ad7173_write_raw(struct iio_dev *indio_dev,
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

