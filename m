From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 14 Jul 2026 12:02:43 +0100
Subject: [PATCH v8 03/17] iio: ABI: add parent entry for iio channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-ad9910-iio-driver-v8-3-36939c3c07d2@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784026971; l=2431;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=5nFgyUfllJljSZOQwdty2yaZdYRSoVEDNbvhxaPGuQ4=;
 b=+sZGmCIyOZ0XlZx02qZz/e0hX2dfkibia59XxSpalI66NtGBbE8Kqp09EbtgURJnYp7HljDjb
 sF1J7XnEFkxDTAIRHrl8w04kp4anSARdWCsoE71DSQsJHJWZd+5yXlW
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for a read-only sysfs attribute that allows to expose
parent-child relationships between IIO channels.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/ABI/testing/sysfs-bus-iio | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio b/Documentation/ABI/testing/sysfs-bus-iio
index 7ef0db8dad40..96a7991c0723 100644
--- a/Documentation/ABI/testing/sysfs-bus-iio
+++ b/Documentation/ABI/testing/sysfs-bus-iio
@@ -2155,6 +2155,34 @@ Description:
 		specific attributes. This is useful for userspace to be able to
 		better identify an individual channel.
 
+What:		/sys/bus/iio/devices/iio:deviceX/in_voltageY_parent
+What:		/sys/bus/iio/devices/iio:deviceX/out_voltageY_parent
+What:		/sys/bus/iio/devices/iio:deviceX/in_altvoltageY_parent
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_parent
+What:		/sys/bus/iio/devices/iio:deviceX/in_currentY_parent
+What:		/sys/bus/iio/devices/iio:deviceX/out_currentY_parent
+What:		/sys/bus/iio/devices/iio:deviceX/in_altcurrentY_parent
+What:		/sys/bus/iio/devices/iio:deviceX/out_altcurrentY_parent
+KernelVersion:	7.3
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Read-only attribute containing the sysfs name prefix of the parent
+		channel for hierarchical channel relationships (e.g. "out_altvoltage0").
+		The prefix uniquely identifies the parent channel and can be used by
+		userspace to organize channels in tree-like structures that reflects
+		virtual or logical relationships between them.
+
+		For example, an IIO device may expose a primary output channel as
+		"out_voltage0" together with a set of profile-based or mode-based
+		subchannels used to configure or compose the output signal. These
+		subchannels may carry common attributes such as frequency, phase, etc.
+		They do not represent physical outputs, but rather logical/virtual
+		channels grouping configurations that affect the primary output.
+		Each subchannel exposes a <dir>_<type>[Y]_parent attribute reading
+		"out_voltage0", allowing userspace to group controls under the output
+		channel they belong to rather than treating them as unrelated top-level
+		channels.
+
 What:		/sys/bus/iio/devices/iio:deviceX/in_frequencyY_raw
 What:		/sys/bus/iio/devices/iio:deviceX/out_frequencyY_raw
 KernelVersion:	7.3

-- 
2.43.0

