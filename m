From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 14 Jul 2026 12:02:56 +0100
Subject: [PATCH v8 16/17] iio: ABI: add docs for ad9910 sysfs and debugfs
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-ad9910-iio-driver-v8-16-36939c3c07d2@analog.com>
References: <20260714-ad9910-iio-driver-v8-0-36939c3c07d2@analog.com>
In-Reply-To: <20260714-ad9910-iio-driver-v8-0-36939c3c07d2@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784026971; l=4220;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=GuhwolTQpd8DFn9kJcnMvrj2DfAjx99cqypPcX1I4W8=;
 b=eowpbGlqGpJvQZAyjCD4Yn1yeicDaxc6UKd7Q6RHUnmwFgOKoV20qEeAjp7nQG8p5e/xzyT8u
 +3rbN84CDWnCKpi8ODUKfvxHHc97MWjoy59zGEdkq//SUbd9mXo+htc
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add custom ABI documentation files for the DDS AD9910 with sysfs and
debugfs entries. The sysfs ones control parameters from the Digital Ramp
Generator and OSK engine. The debugfs attributes are read-only and
evalutate into source channel labels for each DDS core parameter.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/ABI/testing/debugfs-iio-ad9910       | 23 ++++++++++++++++
 .../ABI/testing/sysfs-bus-iio-frequency-ad9910     | 31 ++++++++++++++++++++++
 MAINTAINERS                                        |  2 ++
 3 files changed, 56 insertions(+)

diff --git a/Documentation/ABI/testing/debugfs-iio-ad9910 b/Documentation/ABI/testing/debugfs-iio-ad9910
new file mode 100644
index 000000000000..7083a20d5a40
--- /dev/null
+++ b/Documentation/ABI/testing/debugfs-iio-ad9910
@@ -0,0 +1,23 @@
+What:		/sys/kernel/debug/iio/iio:deviceX/frequency_source
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read-only. Reports the channel label that is read from the
+		<dir>_<type>[Y]_label attribute, which corresponds to the on-chip
+		signal generator that is currently driving the output frequency.
+
+What:		/sys/kernel/debug/iio/iio:deviceX/phase_source
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read-only. Reports the channel label that is read from the
+		<dir>_<type>[Y]_label attribute, which corresponds to the on-chip
+		signal generator that is currently driving the output phase.
+
+What:		/sys/kernel/debug/iio/iio:deviceX/amplitude_source
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read-only. Reports the channel label that is read from the
+		<dir>_<type>[Y]_label attribute, which corresponds to the on-chip
+		signal generator that is currently driving the output amplitude.
diff --git a/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910 b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
new file mode 100644
index 000000000000..4e25f538af4a
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
@@ -0,0 +1,31 @@
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_dwell_en
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_dwell_en
+What:		/sys/bus/iio/devices/iio:deviceX/out_phaseY_dwell_en
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For a channel that produces parametric sweeps, this attribute controls
+		the sweep behavior at the configured limit. It enables dwell mode at a
+		sweep limit when set to 1, i.e., after the sweep is complete the output
+		value stays at the limit. Otherwise (setting this value to 0), the sweep
+		may stop or restart from the initial position, or even continue by
+		reversing the sweep direction.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_raw_roc
+What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_raw_roc
+What:		/sys/bus/iio/devices/iio:deviceX/out_phaseY_raw_roc
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		For a channel that produces parametric sweeps, this attribute controls
+		the rate of change of the parameter in raw units per second (slope).
+		This value may be influenced by the channel sampling_frequency attribute
+		if available. Multiplying this value by the scale attribute of the
+		channel yields the rate of change in physical units per second.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_raw_roc_available
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Lists the available roc values for the channel. Values are
+		space-separated in ascending order.
diff --git a/MAINTAINERS b/MAINTAINERS
index f741b799d383..b923e5b25ddc 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1683,6 +1683,8 @@ M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/ABI/testing/debugfs-iio-ad9910
+F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-ad9910
 F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
 F:	drivers/iio/frequency/ad9910.c
 

-- 
2.43.0

