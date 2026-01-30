From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 30 Jan 2026 10:06:49 +0000
Subject: [PATCH v6 8/8] Documentation: ABI: testing: add common ABI file
 for iio/frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260130-adf41513-iio-driver-v6-8-cf46239026bc@analog.com>
References: <20260130-adf41513-iio-driver-v6-0-cf46239026bc@analog.com>
In-Reply-To: <20260130-adf41513-iio-driver-v6-0-cf46239026bc@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769767615; l=1731;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Oj2k9JgE/uUfO2+nYhc3ewqTCjVw0I0URGflu7fT+uM=;
 b=a84rk33IDvCU2RI1CyAHPceczS4wBg2aO6wVlKT6rKa0sOT/sPiFVFLJ1e5X3CH06Ga4+pNzI
 OQJb3x/LXQYDpqqpyzE40lc85DMZdCwMhIHA5eye78J70VjmHj1fsjE
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ABI documentation file for PLL/DDS devices with frequency_resolution
sysfs entry attribute used by ADF4350 and ADF41513.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/ABI/testing/sysfs-bus-iio-frequency | 11 +++++++++++
 MAINTAINERS                                       |  1 +
 2 files changed, 12 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio-frequency b/Documentation/ABI/testing/sysfs-bus-iio-frequency
new file mode 100644
index 000000000000..1ce8ae578fd6
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-iio-frequency
@@ -0,0 +1,11 @@
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_resolution
+KernelVersion:	6.20
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Stores channel Y frequency resolution/channel spacing in Hz for PLL
+		devices. The given value directly influences the operating mode when
+		fractional-N synthesis is required, as it derives values for
+		configurable modulus parameters used in the calculation of the output
+		frequency. It is assumed that the algorithm that is used to compute
+		the various dividers, is able to generate proper values for multiples
+		of channel spacing.
diff --git a/MAINTAINERS b/MAINTAINERS
index 0d9b7cf86aec..748eeb6f5bd2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1639,6 +1639,7 @@ M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/ABI/testing/sysfs-bus-iio-frequency
 F:	Documentation/devicetree/bindings/iio/frequency/adi,adf41513.yaml
 F:	Documentation/iio/adf41513.rst
 F:	drivers/iio/frequency/adf41513.c

-- 
2.43.0

