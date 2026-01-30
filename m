From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 30 Jan 2026 10:06:46 +0000
Subject: [PATCH v6 5/8] iio: frequency: adf41513: handle LE synchronization
 feature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260130-adf41513-iio-driver-v6-5-cf46239026bc@analog.com>
References: <20260130-adf41513-iio-driver-v6-0-cf46239026bc@analog.com>
In-Reply-To: <20260130-adf41513-iio-driver-v6-0-cf46239026bc@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769767615; l=2998;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=7PWCc+kWI/VpsoPPUmqky10EYHvCMPsgsZ1c3vbPiko=;
 b=yYxkpd3K/cWnvV/iU3CKeToY5WGaVLgHlEseQM0b4pYBV+Qnc075WEjzLpyPsPhNc9d3+o4A7
 vkCuqBl93qwBQPYIZafGB/Hj0Ri109UpegvS7/rmFNLPweBUrF9GrJ3
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When LE sync is enabled, it is must be set after powering up and must be
disabled when powering down. It is recommended when using the PLL as
a frequency synthesizer, where reference signal will always be present
while the device is being configured.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/adf41513.c | 35 ++++++++++++++++++++++++++++++++---
 1 file changed, 32 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/frequency/adf41513.c b/drivers/iio/frequency/adf41513.c
index b2efd545c885..0741aeb5fa3d 100644
--- a/drivers/iio/frequency/adf41513.c
+++ b/drivers/iio/frequency/adf41513.c
@@ -221,6 +221,7 @@ struct adf41513_data {
 	bool phase_detector_polarity;
 
 	bool logic_lvl_1v8_en;
+	bool le_sync_en;
 };
 
 struct adf41513_pll_settings {
@@ -639,13 +640,27 @@ static int adf41513_set_frequency(struct adf41513_state *st, u64 freq_uhz, u16 s
 static int adf41513_suspend(struct adf41513_state *st)
 {
 	st->regs[ADF41513_REG6] |= FIELD_PREP(ADF41513_REG6_POWER_DOWN_MSK, 1);
+	st->regs[ADF41513_REG12] &= ~ADF41513_REG12_LE_SELECT_MSK;
 	return adf41513_sync_config(st, ADF41513_SYNC_DIFF);
 }
 
 static int adf41513_resume(struct adf41513_state *st)
 {
+	int ret;
+
 	st->regs[ADF41513_REG6] &= ~ADF41513_REG6_POWER_DOWN_MSK;
-	return adf41513_sync_config(st, ADF41513_SYNC_DIFF);
+	ret = adf41513_sync_config(st, ADF41513_SYNC_DIFF);
+	if (ret)
+		return ret;
+
+	if (st->data.le_sync_en) {
+		st->regs[ADF41513_REG12] |= ADF41513_REG12_LE_SELECT_MSK;
+		ret = adf41513_sync_config(st, ADF41513_SYNC_DIFF);
+		if (ret)
+			return ret;
+	}
+
+	return ret;
 }
 
 static ssize_t adf41513_read_uhz(struct iio_dev *indio_dev,
@@ -938,6 +953,8 @@ static int adf41513_parse_fw(struct adf41513_state *st)
 				     "invalid lock detect count: %u\n", tmp);
 	st->data.lock_detect_count = tmp;
 
+	/* load enable sync */
+	st->data.le_sync_en = device_property_read_bool(dev, "adi,le-sync-enable");
 	st->data.freq_resolution_uhz = MICROHZ_PER_HZ;
 
 	return 0;
@@ -945,6 +962,7 @@ static int adf41513_parse_fw(struct adf41513_state *st)
 
 static int adf41513_setup(struct adf41513_state *st)
 {
+	int ret;
 	u32 tmp;
 
 	memset(st->regs_hw, 0xFF, sizeof(st->regs_hw));
@@ -978,8 +996,19 @@ static int adf41513_setup(struct adf41513_state *st)
 					      st->data.logic_lvl_1v8_en ? 0 : 1);
 
 	/* perform initialization sequence with power-up frequency */
-	return adf41513_set_frequency(st, st->data.power_up_frequency_hz * MICRO,
-				      ADF41513_SYNC_ALL);
+	ret = adf41513_set_frequency(st, st->data.power_up_frequency_hz * MICRO,
+				     ADF41513_SYNC_ALL);
+	if (ret)
+		return ret;
+
+	if (st->data.le_sync_en) {
+		st->regs[ADF41513_REG12] |= ADF41513_REG12_LE_SELECT_MSK;
+		ret = adf41513_sync_config(st, ADF41513_SYNC_DIFF);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
 }
 
 static void adf41513_power_down(void *data)

-- 
2.43.0

