From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 17 Apr 2026 09:17:37 +0100
Subject: [PATCH RFC v3 8/9] Documentation: ABI: testing: add docs for
 ad9910 sysfs entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-ad9910-iio-driver-v3-8-29b93712a228@analog.com>
References: <20260417-ad9910-iio-driver-v3-0-29b93712a228@analog.com>
In-Reply-To: <20260417-ad9910-iio-driver-v3-0-29b93712a228@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776413867; l=3746;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=X/nP5kexLBl62iqsKB8+rasjCa5LGKYgLRPHdgVXK8o=;
 b=Ri7x0ZtAET4VYDGOCLadvZRMUHRyDCLgEFj0SDLWzZaSpaMgZIDZWfckY+movK1xPD0CtpIIZ
 k3g5dInyWwFAWLvVM4xfc+BRLgujbXBCJM2CWFXogiY78HC4mHJ48AN
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add custom ABI documentation file for the DDS AD9910 with sysfs entries to
control Parallel Port, Digital Ramp Generator and OSK parameters.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../ABI/testing/sysfs-bus-iio-frequency-ad9910     | 62 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 63 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910 b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
new file mode 100644
index 000000000000..fabc2a5417d1
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
@@ -0,0 +1,62 @@
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
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_step
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Channels that sweep frequency values at determined rate use this value
+		to set the frequency step size in Hz.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_phase_step
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Channels that sweep phase values at determined rate use this value
+		to set the phase step size in radians.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_scale_step
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Channels that sweep amplitude values at determined rate use this value
+		to set the amplite scale step.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_pinctrl_en
+KernelVersion:
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Channels that supports pin control to enable/disable its output use
+		this attribute to set the pin control mode. When set to 1, the output
+		state is controlled by a physical pin, and the channel is enabled when
+		the pin is active. When set to 0, only software control is used to
+		enable/disable the channel output.
diff --git a/MAINTAINERS b/MAINTAINERS
index 6403439b530d..edd87ee7da5f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1635,6 +1635,7 @@ M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
 F:	drivers/iio/frequency/ad9910.c
 

-- 
2.43.0

