From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 07 Jul 2026 15:04:23 +0100
Subject: [PATCH v7 02/17] iio: ABI: scale and offset for frequency/phase
 channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-ad9910-iio-driver-v7-2-a4ec30f63700@analog.com>
References: <20260707-ad9910-iio-driver-v7-0-a4ec30f63700@analog.com>
In-Reply-To: <20260707-ad9910-iio-driver-v7-0-a4ec30f63700@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783433065; l=1948;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=8xExd6agkDMe+77PvtFtEYbRMP/CGdlrMgrnXQ9j6/Q=;
 b=5ebKX9Zt54oqzja6RHNp7QRS0zk19Ewbji7kOFkqV+8UXS6yg1NzSANJAfOwst1QEXpZN+fdR
 A4VCR3Zu4TDAQBnm4mZy+/mS53QMTYY1kCTNPUNi/Qn1KWdvFCZxMgv
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Consider scale and offset attributes for frequency and phase channels.
Those attributes are going to be used by a DDS device to be introduced
shortly.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/ABI/testing/sysfs-bus-iio | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio b/Documentation/ABI/testing/sysfs-bus-iio
index 90047189c3eb..3037b8b79fba 100644
--- a/Documentation/ABI/testing/sysfs-bus-iio
+++ b/Documentation/ABI/testing/sysfs-bus-iio
@@ -441,6 +441,10 @@ What:		/sys/bus/iio/devices/iio:deviceX/in_voltageY_i_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_voltageY_q_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_current_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_phaseY_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_phase_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_offset
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequency_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_tempY_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_temp_offset
 What:		/sys/bus/iio/devices/iio:deviceX/in_pressureY_offset
@@ -474,6 +478,10 @@ What:		/sys/bus/iio/devices/iio:deviceX/in_voltage_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_voltage-voltage_scale
 What:		/sys/bus/iio/devices/iio:deviceX/out_voltageY_scale
 What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_phaseY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_phase_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_scale
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequency_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_supply_scale
 What:		/sys/bus/iio/devices/iio:deviceX/in_current_scale

-- 
2.43.0

