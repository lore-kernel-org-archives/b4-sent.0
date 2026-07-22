From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Jul 2026 16:50:11 +0100
Subject: [PATCH v9 02/17] iio: ABI: raw, scale and offset for
 frequency/phase channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-ad9910-iio-driver-v9-2-459d1df5ac56@analog.com>
References: <20260722-ad9910-iio-driver-v9-0-459d1df5ac56@analog.com>
In-Reply-To: <20260722-ad9910-iio-driver-v9-0-459d1df5ac56@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784735456; l=4117;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=b0wjZEHLLiPjjpYzkara2Qcj+Q0dyqXjAs1Abo131jY=;
 b=7YSSiDWO+6IdTjka1AU23VETB8rsI/ffIvWiy6QG68vMvUQrjOyuJvbrRTH0/CBd6RCa4xUO2
 6YPc6VRwtv5C1vnqcmhx7PJoukFsWw/aL/Rhcy5eu5ozITLS/ZeN5zw
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Consider scale and offset attributes for frequency and phase channels.
Frequency channels are going to be introduced later alongside a DDS device
driver which is going to leverage those new attributes.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/ABI/testing/sysfs-bus-iio | 41 +++++++++++++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio b/Documentation/ABI/testing/sysfs-bus-iio
index 3e75ce1c97c6..24712b5bd110 100644
--- a/Documentation/ABI/testing/sysfs-bus-iio
+++ b/Documentation/ABI/testing/sysfs-bus-iio
@@ -441,6 +441,14 @@ What:		/sys/bus/iio/devices/iio:deviceX/in_voltageY_i_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_voltageY_q_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_current_offset
+What:		/sys/bus/iio/devices/iio:deviceX/in_phaseY_offset
+What:		/sys/bus/iio/devices/iio:deviceX/in_phase_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_phaseY_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_phase_offset
+What:		/sys/bus/iio/devices/iio:deviceX/in_frequencyY_offset
+What:		/sys/bus/iio/devices/iio:deviceX/in_frequency_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequency_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_tempY_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_temp_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_pressureY_offset
@@ -474,6 +482,14 @@ What:		/sys/bus/iio/devices/iio:deviceX/in_voltage_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_voltage-voltage_scale
 What:		/sys/bus/iio/devices/iio:deviceX/out_voltageY_scale
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/in_phaseY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/in_phase_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_phaseY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_phase_scale
+What:		/sys/bus/iio/devices/iio:deviceX/in_frequencyY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/in_frequency_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequency_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_supply_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_current_scale
@@ -2149,6 +2165,22 @@ Description:
 		specific attributes. This is useful for userspace to be able to
 		better identify an individual channel.
 
+What:		/sys/bus/iio/devices/iio:deviceX/in_frequencyY_raw
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Raw (unscaled) frequency reading from channel Y.
+		Units after application of scale and offset are Hz.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_raw
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Raw (unscaled, no bias etc.) output frequency for channel Y.
+		The number must always be specified and unique if the output
+		corresponds to a single channel. Units after application of
+		scale and offset are Hz.
+
 What:		/sys/bus/iio/devices/iio:deviceX/in_phaseY_raw
 KernelVersion:	4.18
 Contact:	linux-iio@vger.kernel.org
@@ -2156,6 +2188,15 @@ Description:
 		Raw (unscaled) phase difference reading from channel Y.
 		Units after application of scale and offset are radians.
 
+What:		/sys/bus/iio/devices/iio:deviceX/out_phaseY_raw
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Raw (unscaled, no bias etc.) output phase for channel Y.
+		The number must always be specified and unique if the output
+		corresponds to a single channel. Units after application of
+		scale and offset are radians.
+
 What:		/sys/bus/iio/devices/iio:deviceX/in_massconcentration_pm1_input
 What:		/sys/bus/iio/devices/iio:deviceX/in_massconcentrationY_pm1_input
 What:		/sys/bus/iio/devices/iio:deviceX/in_massconcentration_pm2p5_input

-- 
2.43.0

