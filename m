From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 04 Jun 2024 11:16:58 +0200
Subject: [PATCH] iio: adc: adi-axi-adc: add platform dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240604-dev-axi-adc-kconfig-v1-1-cfb725606b8e@analog.com>
X-B4-Tracking: v=1; b=H4sIAInbXmYC/x3MTQqAIBBA4avIrBswtR+6SrQwnWoINBQiCO+et
 PwW772QKTFlmMQLiW7OHENF2whwhw07IftqUFIZ2UuDnm60D6P1Dk8Xw8Y7trIbB63cqkcDtbw
 Sbfz813kp5QO8lt1BZQAAAA==
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717492622; l=928;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=JrPT4YLeShRtu2BHWrN15sqGoA0Wm9+sv1TlaVGLUxk=;
 b=BcGneg9uohBTvTH5tRj9XtAjtgGIjfgHskjmXccgEIfUE9aaa9JSECdBoU2tFqa3Xe3Q7esJz
 Y4+amWOGW/kBBO4wKUDM8eSMctFeVeB00Q8FKJpFSUaz2uRs8Issey5
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Being this device a soft core, it's only supported on some/specific
platforms. Hence add proper dependencies for the supported platforms.
Also add COMPILE_TEST to increase the build coverage.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iio/adc/Kconfig b/drivers/iio/adc/Kconfig
index 5030319249c5..3d91015af6ea 100644
--- a/drivers/iio/adc/Kconfig
+++ b/drivers/iio/adc/Kconfig
@@ -353,6 +353,7 @@ config AD9467
 
 config ADI_AXI_ADC
 	tristate "Analog Devices Generic AXI ADC IP core driver"
+	depends on MICROBLAZE || NIOS2 || ARCH_ZYNQ || ARCH_ZYNQMP || ARCH_INTEL_SOCFPGA || COMPILE_TEST
 	select IIO_BUFFER
 	select IIO_BUFFER_HW_CONSUMER
 	select IIO_BUFFER_DMAENGINE

---
base-commit: b3019fcdeb286b2cfe45e44bccb44dbcd8ff66dd
change-id: 20240604-dev-axi-adc-kconfig-1058732cb384
--

Thanks!
- Nuno Sá

