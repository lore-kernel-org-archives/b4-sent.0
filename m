From: Radu Sabau <radu.sabau@analog.com>
Date: Wed, 01 Apr 2026 13:56:48 +0300
Subject: [PATCH v2] iio: adc: ad4695: Fix call ordering in offload buffer
 postenable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260401-ad4696-fix-v2-1-2480b9a30749@analog.com>
X-B4-Tracking: v=1; b=H4sIAO/5zGkC/22MQQ7CIBAAv9LsWQxLgYAn/2F6QLq2JAoGDNE0/
 F3s2eNMMrNBoRyowGnYIFMNJaTYQRwG8KuLC7EwdwbBhebjyJmbpbaa3cKbodFWKWe8QoQePDN
 1vc8uU+c1lFfKn/1d8Wf/bioyZGQkktVS4VWcXXT3tBx9esDUWvsCCtavFqUAAAA=
X-Change-ID: 20260330-ad4696-fix-186955a8c511
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Jonathan Cameron <jic23@kernel.org>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775041007; l=3768;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=pmd7DXpg+W48mt7EX681vGeYH0zmSrEeahfH1uvhrOc=;
 b=AteRS/37NSqfXWYdQ/bHxM0GXDUoX1o68LnrWkoPfyhEW5kiCIZiBEqLzy+SlufivqtxrVX5M
 N0eGcccUp1EABrUGgcT0IoExqjy5Unu+qZ7DRmnYVJjn9EGhGIB0nyR
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ad4695_enter_advanced_sequencer_mode() was called after
spi_offload_trigger_enable(). That is wrong because
ad4695_enter_advanced_sequencer_mode() issues regular SPI transfers to
put the ADC into advanced sequencer mode, and spi_offload_trigger_enable()
enables the PWM trigger that drives CNV. Once the PWM is running, CNV
pulses start arriving and the offload engine owns the SPI bus; any
concurrent regular SPI transfer produces undefined behaviour.

Fix this by calling ad4695_enter_advanced_sequencer_mode() before
spi_offload_trigger_enable(), so the ADC is fully configured before the
first CNV pulse can occur. This is consistent with the same constraint
that already applies to the BUSY_GP_EN write above it.

Update the error unwind labels accordingly: add err_exit_conversion_mode
so that a failure of spi_offload_trigger_enable() correctly exits
conversion mode before clearing BUSY_GP_EN.

Fixes: f09f140e3ea8 ("iio: adc: ad4695: Add support for SPI offload")
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
ad4695_enter_advanced_sequencer_mode() issues regular SPI transfers to
configure the ADC. These must complete before spi_offload_trigger_enable()
enables the PWM/CNV trigger, because once CNV pulses are live the offload
engine owns the SPI bus.

This fixes the call ordering and updates the error unwind path accordingly.
---
Changes in v2:
- Reword commit message to explain the correct bus-ownership
  invariant directly, without reference to the HDL bug that
  exposed it.
- Remove unnecessary comment since the error path changed.
- Link to v1: https://lore.kernel.org/r/20260330-ad4696-fix-v1-1-e841e96451b2@analog.com
---
 drivers/iio/adc/ad4695.c | 23 ++++++++---------------
 1 file changed, 8 insertions(+), 15 deletions(-)

diff --git a/drivers/iio/adc/ad4695.c b/drivers/iio/adc/ad4695.c
index cda419638d9a..4471acd6fd5f 100644
--- a/drivers/iio/adc/ad4695.c
+++ b/drivers/iio/adc/ad4695.c
@@ -876,14 +876,14 @@ static int ad4695_offload_buffer_postenable(struct iio_dev *indio_dev)
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
@@ -895,22 +895,15 @@ static int ad4695_offload_buffer_postenable(struct iio_dev *indio_dev)
 	ret = pwm_apply_might_sleep(st->cnv_pwm, &state);
 	mutex_unlock(&st->cnv_pwm_lock);
 	if (ret)
-		goto err_offload_exit_conversion_mode;
+		goto err_trigger_disable;
 
 	return 0;
 
-err_offload_exit_conversion_mode:
-	/*
-	 * We have to unwind in a different order to avoid triggering offload.
-	 * ad4695_exit_conversion_mode() triggers a conversion, so it has to be
-	 * done after spi_offload_trigger_disable().
-	 */
+err_trigger_disable:
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

