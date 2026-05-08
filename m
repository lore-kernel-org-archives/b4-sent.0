From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 08 May 2026 18:00:25 +0100
Subject: [PATCH RFC v4 09/10] Documentation: ABI: testing: add docs for
 ad9910 sysfs entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-ad9910-iio-driver-v4-9-d26bfd20ee3d@analog.com>
References: <20260508-ad9910-iio-driver-v4-0-d26bfd20ee3d@analog.com>
In-Reply-To: <20260508-ad9910-iio-driver-v4-0-d26bfd20ee3d@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778259632; l=4185;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=dE4RjDJ3jXYz/rWtGJ4gRTQISFMbwtkVtOgifyBJx3Y=;
 b=Gn0rPCIlonlfYr1Xkw5LmC1wDnq4KqUWvtJG7BfXNEiXnU+G1GR5/iVvKM9+kiUf4qOaNVMAG
 tJ0RkiKfT/XCFxMpnqlIw/z49llpyZX07mT481ogIrTNGKlMDY0HLGJ
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add custom ABI documentation file for the DDS AD9910 with sysfs entries to
control Parallel Port, Digital Ramp Generator and OSK parameters.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../ABI/testing/sysfs-bus-iio-frequency-ad9910     | 73 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 74 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910 b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
new file mode 100644
index 000000000000..eb0ff96a6e10
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
@@ -0,0 +1,73 @@
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_offset
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For a channel that allows frequency control through buffers, this
+		represents the base frequency value in Hz. The actual output frequency
+		is a result with the sum of this value.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_scale
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For a channel that allows frequency control through buffers, this
+		represents the frequency modulation gain. This value multiplies the
+		buffer input sample value before it is added to a frequency offset.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_phase_offset
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For a channel that allows phase control through buffers, this
+		represents the base phase value in radians. The actual output phase
+		is a result with the sum of this value.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale_offset
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For a channel that allows amplitude control through buffers, this
+		represents the value for a base amplitude scale. The actual output
+		amplitude scale is a result with the sum of this value.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_dwell_en
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For a channel that produces parametric sweeps, this attribute controls
+		the sweep behavior at the configured limits. It enables dwell mode at a
+		sweep limit when set to 1. Otherwise, the sweep may stop at the initial
+		position or restart from that initial position or continue by reversing
+		its direction.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_roc
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Frequency rate of change in Hz/s for channels that produce linear
+		frequency sweeps. This value may be influenced by the channel's
+		sampling_frequency setting.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_phase_roc
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Phase rate of change in rad/s for channels that produce linear
+		phase sweeps. This value may be influenced by the channel's
+		sampling_frequency setting.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale_roc
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Amplitude scale rate of change in 1/s for channels that ramp
+		amplitude. This value may be influenced by the channel's
+		sampling_frequency setting.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale_roc_available
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Lists the available scale_roc values for the channel based on
+		the current sampling_frequency. Values are space-separated in
+		ascending order.
diff --git a/MAINTAINERS b/MAINTAINERS
index 6a53b202a84d..b52c0aae96b7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1643,6 +1643,7 @@ M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
 F:	drivers/iio/frequency/ad9910.c
 

-- 
2.43.0

