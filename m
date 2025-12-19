From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 19 Dec 2025 12:34:53 +0000
Subject: [PATCH v2 6/6] Documentation: ABI: testing: add support for
 ADF41513
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251219-adf41513-iio-driver-v2-6-be29a83d5793@analog.com>
References: <20251219-adf41513-iio-driver-v2-0-be29a83d5793@analog.com>
In-Reply-To: <20251219-adf41513-iio-driver-v2-0-be29a83d5793@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766147692; l=2353;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=1MCQTuBKOvCkCb1guQDYrrs5FOybrR5OguIAEADSstQ=;
 b=zX4QIZP0+UKrF3EhmsaEgvJ+ku29ecs1Afhul5WA+1NSVinSR8fzUk+v/JjcoiJWKOrnVn10h
 x3AsagCyzkNB0F8aWFXZOghVDX6URAaVvjHkzeqnoL/fsMbTRi/X1/7
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ABI documentation for ADF41513 PLL sysfs interfaces

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../ABI/testing/sysfs-bus-iio-frequency-adf41513   | 27 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 28 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-iio-frequency-adf41513 b/Documentation/ABI/testing/sysfs-bus-iio-frequency-adf41513
new file mode 100644
index 000000000000..11ffd248eedb
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-iio-frequency-adf41513
@@ -0,0 +1,27 @@
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_frequency_resolution
+KernelVersion:	6.20
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Stores channel Y frequency resolution/channel spacing in Hz.
+		The value given directly influences the choice of operation:
+
+		- integer-N: requested frequency is a multiple of the Phase Detector
+		frequency.
+		- fixed modulus: fractional-N mode with fixed modulus.
+		- variable modulus: dual-modulus fractional-N mode with extra variable
+		modulus added on top of the fixed one.
+
+		It is assumed that the algorithm that is used to compute the various
+		dividers, is able to generate proper values for multiples of channel
+		spacing.
+
+What:		/sys/bus/iio/devices/iio:deviceX/out_altvoltageY_refin_frequency
+KernelVersion:	6.20
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Sets channel Y REFin frequency in Hz. In some clock chained
+		applications, the reference frequency used by the PLL may change during
+		runtime. This attribute allows the user to adjust the reference
+		frequency accordingly.
+		To avoid glitches in the RF output, consider using out_altvoltageY_powerdown
+		to power down the PLL and its RFOut buffers during REFin changes.
diff --git a/MAINTAINERS b/MAINTAINERS
index c536c3afc1ae..48fa1011b797 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1606,6 +1606,7 @@ M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/ABI/testing/sysfs-bus-iio-frequency-adf41513
 F:	Documentation/devicetree/bindings/iio/frequency/adi,adf41513.yaml
 F:	Documentation/iio/adf41513.rst
 F:	drivers/iio/frequency/adf41513.c

-- 
2.43.0

