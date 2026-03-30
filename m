From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 30 Mar 2026 16:34:39 +0300
Subject: [PATCH] iio: adc: ad4695: Fix call ordering in offload buffer
 postenable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260330-ad4696-fix-v1-1-e841e96451b2@analog.com>
X-B4-Tracking: v=1; b=H4sIAO57ymkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY2MD3cQUEzNLM920zApdQwszS1PTRItkU0NDJaCGgqJUoDDYsOjY2lo
 AT7Db+VwAAAA=
X-Change-ID: 20260330-ad4696-fix-186955a8c511
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Jonathan Cameron <jic23@kernel.org>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774877680; l=4358;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=GM0JOsIHqe/8oe/7PJ7wlNGk2Snp/S1plgcJytEICEo=;
 b=XTv6Sx52i4yNrIdf1YbxHQIfZeeUSNC1hebM5aVJTH2u23WpIYYv0nhETby7nZwh+FZ/61ITY
 VbVHVrP+2fEDKSxeYNuGaN9m2VOtVgZWiobVsG0mDb2OLrEwsznZ75k
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ad4695_enter_advanced_sequencer_mode() was called after
spi_offload_trigger_enable(), meaning a regular SPI transfer could be in
flight while the offload was already active. When the offload fires its
completion interrupt concurrently with the regular transfer, the SPI
engine interrupt handler is not designed to handle both at once, leading
to a kernel panic.

Fix this by calling ad4695_enter_advanced_sequencer_mode() before
spi_offload_trigger_enable(), ensuring all SPI bus accesses are complete
before the offload becomes active. This is consistent with the same
constraint that already applies to the BUSY_GP_EN write above it.

Update the error unwind labels accordingly: add err_exit_conversion_mode
so that a failure of spi_offload_trigger_enable() correctly exits
conversion mode before clearing BUSY_GP_EN.

Fixes: f09f140e3ea8 ("iio: adc: ad4695: Add support for SPI offload")
Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
When enabling the IIO buffer for SPI offload operation on AD4695/AD4696,
ad4695_enter_advanced_sequencer_mode() was called after
spi_offload_trigger_enable(), resulting in a regular SPI transfer being
in flight while the offload was already active. This caused a kernel
panic in the SPI engine interrupt handler.

This series fixes the call ordering so all SPI bus accesses complete
before the offload becomes active, consistent with the constraint that
was already documented for the BUSY_GP_EN write in the same function.
---
 drivers/iio/adc/ad4695.c | 31 ++++++++++++++-----------------
 1 file changed, 14 insertions(+), 17 deletions(-)

diff --git a/drivers/iio/adc/ad4695.c b/drivers/iio/adc/ad4695.c
index cda419638d9a..c6721f5ac8af 100644
--- a/drivers/iio/adc/ad4695.c
+++ b/drivers/iio/adc/ad4695.c
@@ -866,24 +866,24 @@ static int ad4695_offload_buffer_postenable(struct iio_dev *indio_dev)
 		return ret;
 
 	/*
-	 * NB: technically, this is part the SPI offload trigger enable, but it
-	 * doesn't work to call it from the offload trigger enable callback
-	 * because it requires accessing the SPI bus. Calling it from the
-	 * trigger enable callback could cause a deadlock.
+	 * NB: these are technically part of the SPI offload trigger enable, but
+	 * they can't be called from the offload trigger enable callback because
+	 * they require accessing the SPI bus. Calling them from the trigger
+	 * enable callback could cause a deadlock.
 	 */
 	ret = regmap_set_bits(st->regmap, AD4695_REG_GP_MODE,
 			      AD4695_REG_GP_MODE_BUSY_GP_EN);
 	if (ret)
 		goto err_unoptimize_message;
 
-	ret = spi_offload_trigger_enable(st->offload, st->offload_trigger,
-					 &config);
+	ret = ad4695_enter_advanced_sequencer_mode(st, num_slots);
 	if (ret)
 		goto err_disable_busy_output;
 
-	ret = ad4695_enter_advanced_sequencer_mode(st, num_slots);
+	ret = spi_offload_trigger_enable(st->offload, st->offload_trigger,
+					 &config);
 	if (ret)
-		goto err_offload_trigger_disable;
+		goto err_exit_conversion_mode;
 
 	mutex_lock(&st->cnv_pwm_lock);
 	pwm_get_state(st->cnv_pwm, &state);
@@ -895,22 +895,19 @@ static int ad4695_offload_buffer_postenable(struct iio_dev *indio_dev)
 	ret = pwm_apply_might_sleep(st->cnv_pwm, &state);
 	mutex_unlock(&st->cnv_pwm_lock);
 	if (ret)
-		goto err_offload_exit_conversion_mode;
+		goto err_trigger_disable;
 
 	return 0;
 
-err_offload_exit_conversion_mode:
+err_trigger_disable:
 	/*
-	 * We have to unwind in a different order to avoid triggering offload.
-	 * ad4695_exit_conversion_mode() triggers a conversion, so it has to be
-	 * done after spi_offload_trigger_disable().
+	 * ad4695_exit_conversion_mode() triggers a conversion, so the offload
+	 * must be disabled first to avoid capturing a spurious sample.
 	 */
 	spi_offload_trigger_disable(st->offload, st->offload_trigger);
-	ad4695_exit_conversion_mode(st);
-	goto err_disable_busy_output;
 
-err_offload_trigger_disable:
-	spi_offload_trigger_disable(st->offload, st->offload_trigger);
+err_exit_conversion_mode:
+	ad4695_exit_conversion_mode(st);
 
 err_disable_busy_output:
 	regmap_clear_bits(st->regmap, AD4695_REG_GP_MODE,

---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20260330-ad4696-fix-186955a8c511

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

