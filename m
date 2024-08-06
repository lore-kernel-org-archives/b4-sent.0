From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 06 Aug 2024 15:10:40 +0200
Subject: [PATCH 2/2] ABI: debugfs-iio-ad9467: document the debugfs
 interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240806-dev-ad-debugfs-doc-v1-2-153b882a3f01@analog.com>
References: <20240806-dev-ad-debugfs-doc-v1-0-153b882a3f01@analog.com>
In-Reply-To: <20240806-dev-ad-debugfs-doc-v1-0-153b882a3f01@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722949842; l=2199;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=aJKe8f0BemREu/qLk6HbULLoyWom7koS7AvKrSH6W5s=;
 b=n8a62MGDGOgydg//SkXZSt9dVk+ZFTiotI05PbndAky6+X3cngiM0ztzIVmwL1L/0jIc7a8Li
 pD4NghPo1emCXtggD3Wa40NhWDQsI5r7QhMkpb/YHLFiRHPVqA0pK/I
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the debugfs interface for the IIO ad9467 high speed ADC.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/ABI/testing/debugfs-iio-ad9467 | 39 ++++++++++++++++++++++++++++
 MAINTAINERS                                  |  1 +
 2 files changed, 40 insertions(+)

diff --git a/Documentation/ABI/testing/debugfs-iio-ad9467 b/Documentation/ABI/testing/debugfs-iio-ad9467
new file mode 100644
index 000000000000..0352fca1f7f2
--- /dev/null
+++ b/Documentation/ABI/testing/debugfs-iio-ad9467
@@ -0,0 +1,39 @@
+What:		/sys/kernel/debug/iio/iio:deviceX/calibration_table_dump
+KernelVersion:	6.11
+Contact:	linux-iio@vger.kernel.org
+Description:
+		This dumps the calibration table that was filled during the
+		digital interface tuning process.
+
+What:		/sys/kernel/debug/iio/iio:deviceX/in_voltage_test_mode_available
+KernelVersion:	6.11
+Contact:	linux-iio@vger.kernel.org
+Description:
+		List all the available test tones:
+		- off
+		- midscale_short
+		- pos_fullscale
+		- neg_fullscale
+		- checkerboard
+		- prbs23
+		- prbs9
+		- one_zero_toggle
+		- user
+		- bit_toggle
+		- sync
+		- one_bit_high
+		- mixed_bit_frequency
+		- ramp
+
+		Note that depending on the actual device being used, some of the
+		above might not be available (and they won't be listed when
+		reading the file).
+
+What:		/sys/kernel/debug/iio/iio:deviceX/in_voltageY_test_mode
+KernelVersion:	6.11
+Contact:	linux-iio@vger.kernel.org
+Description:
+		Writing to this file will initiate one of available test tone on
+		channel Y. Reading it, shows which test is running. In cases
+		where an IIO backend is available and supports the test tone,
+		additional information about the data correctness is given.
diff --git a/MAINTAINERS b/MAINTAINERS
index ff62a4c2ce9e..417c6751c0dc 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1316,6 +1316,7 @@ M:	Nuno Sa <nuno.sa@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/ABI/testing/debugfs-iio-ad9467
 F:	Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
 F:	drivers/iio/adc/ad9467.c
 

-- 
2.45.2

