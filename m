From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Mon, 17 Feb 2025 12:18:03 +0100
Subject: [PATCH] gpio: 74x146: depend on DM_SPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250217-dmspi-v1-1-58d2a71dc9f6@posteo.net>
X-B4-Tracking: v=1; b=H4sIAOoas2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0Nz3ZTc4oJMXSMz81Rzc/NEE0vjRCWg2oKi1LTMCrA50bG1tQD05F3
 9VwAAAA==
X-Change-ID: 20250217-dmspi-267e777a493a
To: Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739791099; l=1167;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=25ZfUZoVl66vrXVOeP0VBOYoBI6N1iF4HWWpjTXnQtc=;
 b=CEkdF4YsCvw+erpQVrar3184FI4TXa+1gdfy+htXtJpt4fC+1eWsMFQirmgKCxmrdrBtr0mkL
 sbPSy4FfpZvCoK6HG6YorW50rIkmauoT1kbMur4VHLqMCl27IkO8dsO
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, Kconfig allows building CONFIG_DM_74X164 without
CONFIG_DM_SPI, which results in linker errors because this driver
actually uses dm_spi_* functions:

drivers/gpio/74x164_gpio.o: in function `gen_74x164_write_conf':
  undefined reference to `dm_spi_claim_bus'
  undefined reference to `dm_spi_xfer'
  undefined reference to `dm_spi_release_bus'

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/gpio/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index f4a453e1cdd57702eb3944a23b92ab0b6dfbcc71..21361f56e69c829ca87bddba77e8b2201407bafb 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -516,7 +516,7 @@ config ZYNQ_GPIO
 
 config DM_74X164
 	bool "74x164 serial-in/parallel-out 8-bits shift register"
-	depends on DM_GPIO
+	depends on DM_GPIO && DM_SPI
 	help
 	  Driver for 74x164 compatible serial-in/parallel-out 8-outputs
 	  shift registers, such as 74lv165, 74hc595.

---
base-commit: e62df6169eded226d02240eac54d60be8e9da960
change-id: 20250217-dmspi-267e777a493a

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

