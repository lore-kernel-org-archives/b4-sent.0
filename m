From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 07 Jul 2026 15:04:37 +0100
Subject: [PATCH v7 16/17] iio: ABI: add docs for ad9910 sysfs and debugfs
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260707-ad9910-iio-driver-v7-16-a4ec30f63700@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783433065; l=5856;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=GoKs9b4hkGJ5w4ngpHKHYorbZQWdlUxM8I/vrc/m5Xo=;
 b=aT7kPRtMTJQodmnsWVjaEnPoH1fr1hTCmeqNsCOMF8I0p3xm9pr52eNpLGbnDSCHY/CBTUHAt
 4vcZyAGfM3vDKis2fzU7kWpT4egZBvBtmpJSmPVKn0almsaOZFTrpYG
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
 Documentation/ABI/testing/debugfs-iio-ad9910       | 60 ++++++++++++++++++++++
 .../ABI/testing/sysfs-bus-iio-frequency-ad9910     | 31 +++++++++++
 MAINTAINERS                                        |  2 +
 3 files changed, 93 insertions(+)

diff --git a/Documentation/ABI/testing/debugfs-iio-ad9910 b/Documentation/ABI/testing/debugfs-iio-ad9910
new file mode 100644
index 000000000000..b4a125bc1007
--- /dev/null
+++ b/Documentation/ABI/testing/debugfs-iio-ad9910
@@ -0,0 +1,60 @@
+What:		/sys/kernel/debug/iio/iio:deviceX/frequency_source
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read-only. Reports the channel label that corresponds to which of the
+		on-chip signal generators is currently driving the output frequency.
+
+		Resolution order (first match wins):
+
+		- ``ram`` — RAM playback is enabled and its destination is
+		  frequency, phase (polar), amplitude, or polar.
+		- ``drg_frequency`` — the Digital Ramp Generator is enabled
+		  and its destination is frequency.
+		- ``parallel_frequency`` — the parallel data port is enabled
+		  and the frequency scan element is active.
+		- ``profileN`` (N = 0..7) — none of the above modulation
+		  sources are driving frequency, so the currently selected
+		  single-tone profile register is in effect.
+
+What:		/sys/kernel/debug/iio/iio:deviceX/phase_source
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read-only. Reports the channel label that corresponds to which of the
+		on-chip signal generators is currently driving the output phase.
+
+		Resolution order (first match wins):
+
+		- ``ram`` — RAM playback is enabled and its destination is
+		  phase or polar.
+		- ``drg_phase`` — the Digital Ramp Generator is enabled and
+		  its destination is phase.
+		- ``parallel_phase`` / ``parallel_polar_phase`` — the parallel
+		  data port is enabled and the corresponding phase scan
+		  element is active.
+		- ``profileN`` (N = 0..7) — none of the above modulation
+		  sources are driving phase, so the currently selected
+		  single-tone profile register is in effect.
+
+What:		/sys/kernel/debug/iio/iio:deviceX/amplitude_source
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read-only. Reports the channel label that corresponds to which of the
+		on-chip signal generators is currently driving the output amplitude.
+
+		Resolution order (first match wins):
+
+		- ``osk`` — the Output Shift Keying block is enabled and
+		  overrides other amplitude sources.
+		- ``ram`` — RAM playback is enabled and its destination is
+		  amplitude or polar.
+		- ``drg_amplitude`` — the Digital Ramp Generator is enabled
+		  and its destination is amplitude.
+		- ``parallel_amplitude`` / ``parallel_polar_amplitude`` — the
+		  parallel data port is enabled and the corresponding
+		  amplitude scan element is active.
+		- ``profileN`` (N = 0..7) — none of the above modulation
+		  sources are driving amplitude, so the currently selected
+		  single-tone profile register is in effect.
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
index cca4304195cb..fd6119aaad8c 100644
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

