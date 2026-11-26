From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: jic23@kernel.org, dlechner@baylibre.com, nuno.sa@analog.com, 
 andy@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-iio@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH v2 0/3] iio: adc: mt6359: fix scale divisor, request bits,
 and MT6358 VBAT ratio
Date: Thu, 26 Nov 2026 03:10:13 +0000
Message-Id: <20261126031013.27701-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662614; l=1327;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=OJBJnrsWEBcdIqX9tTDRPWz8dYrgSAiAenBKdUU78aQ=;
 b=WjH7t30eM0qc/rABAntiZN6AkXBDKMP1DypfOyz3kKvoHJnBeV7WfvVDnaztz6JLw8Wl9L81M
 lpDermSM0wVC9VeAKu3VZYFgBy4p3AeKsBXrMKi84/6ToDqn/mByunj
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This short series fixes three bugs in drivers/iio/adc/mt6359-auxadc.c
introduced in commit 3587914bf61d ("iio: adc: Add support for MediaTek
MT6357/8/9 Auxiliary ADC"):

1. IIO_CHAN_INFO_SCALE omits dividing by (1 << chan->scan_type.realbits),
   causing processed readings and sysfs scales to be 4096x or 32768x too
   large. Use IIO_VAL_FRACTIONAL with shifted denominator when
   denominator > 1, and IIO_VAL_FRACTIONAL_LOG2 otherwise (avoiding
   division by zero on unpopulated descriptors such as MT6357 VDCXO).
2. MT6357 ISENSE/VCDT and MT6358 VCDT use PMIC_AUXADC_RQST0 bit 0
   (BATADC) instead of their hardware request bits (1 and 2).
3. MT6358 VBAT impedance uses r_ratio 7/2 (MT6359) instead of 3/1
   (MT6358/MT6366, matching MT6358 BATADC).

Changes in v2:
- Move the AI coding assistant note below the --- separator in all three
  patches (per Jonathan Cameron's feedback on v1). No code changes.

Found and drafted with an AI coding assistant.

Ilia Snezhkov (3):
  iio: adc: mt6359: divide scale by ADC resolution
  iio: adc: mt6359: fix MT6357 ISENSE/VCDT and MT6358 VCDT request bits
  iio: adc: mt6359: fix MT6358 VBAT impedance resistance ratio

 drivers/iio/adc/mt6359-auxadc.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

-- 
2.54.0 (Apple Git-157)

