From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 29 Jul 2026 09:25:28 +0100
Subject: [PATCH v10 01/17] iio: ABI: add attributes for altcurrent channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-ad9910-iio-driver-v10-1-aa1f6167729e@analog.com>
References: <20260729-ad9910-iio-driver-v10-0-aa1f6167729e@analog.com>
In-Reply-To: <20260729-ad9910-iio-driver-v10-0-aa1f6167729e@analog.com>
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Johan Hovold <johan@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785313627; l=3588;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=NMyQtwKnhP7ghLAaLd8Vv8Yqv0bWLLVXShCmZ6SK4qg=;
 b=Qxwrjl8ACDFxXM51QGFN44XesPSFtyNyG8BXgOcrSLrWggCkgEZI9r5qo8bYuNawGAklFqpFa
 ZcOPZhGRQCnDZVCj5U7VdbGuhYPBmSCrMm6INNaWiTTafCq/nTduags
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add attributes applicable to altcurrent channels, e.g., frequency, phase,
scale, raw, label and powerdown. Those are going to be used by a DDS
device to be introduced shortly.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/ABI/testing/sysfs-bus-iio | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio b/Documentation/ABI/testing/sysfs-bus-iio
index 5cc2e82c4997..3e75ce1c97c6 100644
--- a/Documentation/ABI/testing/sysfs-bus-iio
+++ b/Documentation/ABI/testing/sysfs-bus-iio
@@ -478,6 +478,10 @@ What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_supply_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_current_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_current_q_scale
+What:		/sys/bus/iio/devices/iio:deviceX/in_altcurrentY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/in_altcurrent_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrent_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_accel_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_accel_peak_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_anglvel_scale
@@ -799,6 +803,8 @@ What:		/sys/bus/iio/devices/iio:deviceX/out_voltageY_powerdown
 What:		/sys/bus/iio/devices/iio:deviceX/out_voltage_powerdown
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_powerdown
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltage_powerdown
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_powerdown
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrent_powerdown
 KernelVersion:	2.6.38
 Contact:	linux-iio@vger.kernel.org
 Description:
@@ -809,6 +815,7 @@ Description:
 		together.
 
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_frequency
 KernelVersion:	3.4.0
 Contact:	linux-iio@vger.kernel.org
 Description:
@@ -835,8 +842,10 @@ Description:
 		all the other channels, since it involves changing the VCO
 		fundamental output frequency.
 
+What:		/sys/bus/iio/devices/iio:deviceX/in_altcurrentY_phase
 What:		/sys/bus/iio/devices/iio:deviceX/in_altvoltageY_i_phase
 What:		/sys/bus/iio/devices/iio:deviceX/in_altvoltageY_q_phase
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_phase
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_phase
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_i_phase
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_q_phase
@@ -850,6 +859,7 @@ Description:
 		channel.
 
 What:		/sys/bus/iio/devices/iio:deviceX/out_currentY_raw
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_raw
 Date:		May 2012
 KernelVersion:	3.5
 Contact:	Johan Hovold <jhovold@gmail.com>
@@ -1736,6 +1746,7 @@ Description:
 
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_raw
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_supply_raw
+What:		/sys/bus/iio/devices/iio:deviceX/in_altcurrentY_raw
 KernelVersion:	3.17
 Contact:	linux-iio@vger.kernel.org
 Description:
@@ -2126,7 +2137,9 @@ Description:
 
 		Raw counter device counters direction for channel Y.
 
+What:		/sys/bus/iio/devices/iio:deviceX/in_altcurrentY_label
 What:		/sys/bus/iio/devices/iio:deviceX/in_voltageY_label
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_label
 What:		/sys/bus/iio/devices/iio:deviceX/out_voltageY_label
 KernelVersion:	5.8
 Contact:	linux-iio@vger.kernel.org

-- 
2.43.0

