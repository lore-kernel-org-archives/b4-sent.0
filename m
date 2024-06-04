From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 04 Jun 2024 11:19:56 +0200
Subject: [PATCH] iio: dac: adi-axi-dac: add platform dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240604-dev-axi-dac-kconfig-v1-1-99ccd03938d1@analog.com>
X-B4-Tracking: v=1; b=H4sIADvcXmYC/x3MQQqAIBBA0avErBswMYOuEi3MmWoILBREkO6et
 HyL/yskjsIJ5q5C5CxJ7tAw9B3404WDUagZtNJGWWWQOKMrguQ8Xv4OuxzoJkPGjpo3stDKJ/I
 u5b8u6/t+hN+Q62UAAAA=
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717492796; l=920;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=YrLqkABgojPI+8MFdEvEB5gbhTdxylKp34cyFJzLkSc=;
 b=N6SOgsSjzOXyztzd5wceCvQ8whG1LF4QV7wA9wELh3NAx+3KH4SDulmfwMmmutLhE9wWlzizh
 lnqlmDHkChtCpF9BHan+g2/kw///GvQt3fZZZTY+cNf3u8ktq54EkbV
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Being this device a soft core, it's only supported on some/specific
platforms. Hence add proper dependencies for the supported platforms.
Also add COMPILE_TEST to increase the build coverage.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/dac/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iio/dac/Kconfig b/drivers/iio/dac/Kconfig
index ee0d9798d8b44..a2596c2d3de31 100644
--- a/drivers/iio/dac/Kconfig
+++ b/drivers/iio/dac/Kconfig
@@ -149,6 +149,7 @@ config AD9739A
 
 config ADI_AXI_DAC
 	tristate "Analog Devices Generic AXI DAC IP core driver"
+	depends on MICROBLAZE || NIOS2 || ARCH_ZYNQ || ARCH_ZYNQMP || ARCH_INTEL_SOCFPGA || COMPILE_TEST
 	select IIO_BUFFER
 	select IIO_BUFFER_DMAENGINE
 	select REGMAP_MMIO

---
base-commit: b3019fcdeb286b2cfe45e44bccb44dbcd8ff66dd
change-id: 20240604-dev-axi-dac-kconfig-a74d4652ebd6
--

Thanks!
- Nuno Sá

