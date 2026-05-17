From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 17 May 2026 10:14:04 +0100
Subject: [PATCH v13 09/12] iio: frequency: adf41513: handle LE
 synchronization feature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-adf41513-iio-driver-v13-9-bb6e134a360f@analog.com>
References: <20260517-adf41513-iio-driver-v13-0-bb6e134a360f@analog.com>
In-Reply-To: <20260517-adf41513-iio-driver-v13-0-bb6e134a360f@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Andrew Morton <akpm@linux-foundation.org>, Petr Mladek <pmladek@suse.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779009279; l=2690;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=tOv38rA11NbIZx5lp52HI0oGhixhW/eDvxs2dHQxbGw=;
 b=rLsvbPXnMKT65kAxUDLJtOteX9/PXzD3b5s58/Vu69qUtTBXEqzsUItQZhzS0A9nXI/G+mhgW
 af3v14kyrn1Bq7OxuNdKwJdh0GvLu85yl0+1YPLumr2o+wm5nY1/6lw
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When LE sync is enabled, it must be set after powering up and it must be
disabled when powering down. It is recommended when using the PLL as
a frequency synthesizer, where reference signal will always be present
while the device is being configured.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/adf41513.c | 33 +++++++++++++++++++++++++++++++--
 1 file changed, 31 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/frequency/adf41513.c b/drivers/iio/frequency/adf41513.c
index 20ea7e82818f..be29a0f6ede9 100644
--- a/drivers/iio/frequency/adf41513.c
+++ b/drivers/iio/frequency/adf41513.c
@@ -218,6 +218,7 @@ struct adf41513_data {
 	bool phase_detector_polarity;
 
 	bool logic_lvl_1v8_en;
+	bool le_sync_en;
 };
 
 struct adf41513_pll_settings {
@@ -635,13 +636,28 @@ static int adf41513_set_frequency(struct adf41513_state *st, u64 freq_uhz, u16 s
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
-	return adf41513_sync_config(st, ADF41513_SYNC_ALL);
+	st->regs[ADF41513_REG12] &= ~ADF41513_REG12_LE_SELECT_MSK;
+	ret = adf41513_sync_config(st, ADF41513_SYNC_ALL);
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
 
 static ssize_t adf41513_read_resolution(struct iio_dev *indio_dev,
@@ -911,6 +927,8 @@ static int adf41513_parse_fw(struct adf41513_state *st)
 				     "invalid lock detect count: %u\n", tmp);
 	st->data.lock_detect_count = tmp;
 
+	/* load enable sync */
+	st->data.le_sync_en = device_property_read_bool(dev, "adi,le-sync-enable");
 	st->data.freq_resolution_uhz = MICROHZ_PER_HZ;
 
 	return 0;
@@ -967,7 +985,18 @@ static int adf41513_setup(struct device *dev, struct adf41513_state *st)
 	if (ret)
 		return ret;
 
-	return devm_add_action_or_reset(dev, adf41513_close, st);
+	ret = devm_add_action_or_reset(dev, adf41513_close, st);
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
 
 static int adf41513_pm_suspend(struct device *dev)

-- 
2.43.0

