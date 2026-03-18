From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 18 Mar 2026 17:56:07 +0000
Subject: [PATCH RFC v2 7/9] iio: frequency: ad9910: add channel labels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-ad9910-iio-driver-v2-7-e79f93becf11@analog.com>
References: <20260318-ad9910-iio-driver-v2-0-e79f93becf11@analog.com>
In-Reply-To: <20260318-ad9910-iio-driver-v2-0-e79f93becf11@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773856569; l=1499;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=7/JC2hv0UHTBwwtimWPscFOCNqU87V8BJrjmF2IrHmI=;
 b=lzO8Hpz++30FnD0TKpKX/KV+kVIAsisDAy5FTXCcIJlWxc2zkJ7upl1rlosANvEWjRx3Pklen
 Wa81q2wUIG6BurkmSZ1psKDkgR/K8aE6COtb9N6MZ4ty+wa4/1CCWCI
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add human-readable labels for all AD9910 IIO channels via the read_label
callback.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 35572d60d6d2..8ff2a9d69265 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -1965,10 +1965,29 @@ static const struct fw_upload_ops ad9910_ram_fwu_ops = {
 	.cancel = ad9910_ram_fwu_cancel
 };
 
+static const char * const ad9910_channel_str[] = {
+	[AD9910_CHAN_IDX_PHY] = "phy",
+	[AD9910_CHAN_IDX_SINGLE_TONE] = "single_tone",
+	[AD9910_CHAN_IDX_PARALLEL_PORT] = "parallel_port",
+	[AD9910_CHAN_IDX_DRG] = "digital_ramp_generator",
+	[AD9910_CHAN_IDX_DRG_RAMP_UP] = "digital_ramp_up",
+	[AD9910_CHAN_IDX_DRG_RAMP_DOWN] = "digital_ramp_down",
+	[AD9910_CHAN_IDX_RAM] = "ram_control",
+	[AD9910_CHAN_IDX_OSK] = "output_shift_keying",
+};
+
+static int ad9910_read_label(struct iio_dev *indio_dev,
+			     struct iio_chan_spec const *chan,
+			     char *label)
+{
+	return sysfs_emit(label, "%s\n", ad9910_channel_str[chan->address]);
+}
+
 static const struct iio_info ad9910_info = {
 	.read_raw = ad9910_read_raw,
 	.write_raw = ad9910_write_raw,
 	.write_raw_get_fmt = ad9910_write_raw_get_fmt,
+	.read_label = ad9910_read_label,
 	.debugfs_reg_access = &ad9910_reg_access,
 };
 

-- 
2.43.0

