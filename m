From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:59 +0100
Subject: [PATCH 18/19] powerpc: mpc83xx_defconfig: Enable NWAPP2 board
 features
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-18-86f78ba2a7af@posteo.net>
References: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
In-Reply-To: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=2040;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=8cjjERboXjwasKowHGhF3NwI7IcXjBOlMpP4+b1yNfY=;
 b=pENUUbNIQp734t9sjGGUCevEG+k3KlEAjIRAbzlvB7faecKhTzZv1xTfwPphoY/E0Xtaqb7jX
 SI7pMQIuWWGCaweTUM4hr3VB+RhS5KSrkYoFXwVlQxu0zFovaY2QLde
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These features are required (or at least helpful) for running Linux on
the LANCOM NWAPP2 board:

- GPIO restart/watchdog are required for operation
- The MPC83xx-internal watchdog is optional
- LEDs are nice to have
- ATH9K is on a removable mini-PCIe card
- ATH803X is the Ethernet PHY installed on the board

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/configs/mpc83xx_defconfig | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/arch/powerpc/configs/mpc83xx_defconfig b/arch/powerpc/configs/mpc83xx_defconfig
index 525a4f6ae1ff7b51e365668b430fa46ce4938f19..40dc455517defd42c7dd8a5414531eced79831f2 100644
--- a/arch/powerpc/configs/mpc83xx_defconfig
+++ b/arch/powerpc/configs/mpc83xx_defconfig
@@ -30,6 +30,9 @@ CONFIG_SYN_COOKIES=y
 CONFIG_INET_ESP=y
 # CONFIG_IPV6 is not set
 CONFIG_PCI=y
+CONFIG_PCIEPORTBUS=y
+CONFIG_PCIEAER=y
+CONFIG_PCI_MSI=y
 CONFIG_DEVTMPFS=y
 CONFIG_DEVTMPFS_MOUNT=y
 # CONFIG_FW_LOADER is not set
@@ -54,6 +57,7 @@ CONFIG_GIANFAR=y
 CONFIG_DAVICOM_PHY=y
 CONFIG_ICPLUS_PHY=y
 CONFIG_MARVELL_PHY=y
+CONFIG_AT803X_PHY=y
 CONFIG_VITESSE_PHY=y
 # CONFIG_INPUT_KEYBOARD is not set
 # CONFIG_INPUT_MOUSE is not set
@@ -64,7 +68,17 @@ CONFIG_SERIAL_8250_CONSOLE=y
 CONFIG_I2C=y
 CONFIG_I2C_CHARDEV=y
 CONFIG_I2C_MPC=y
+CONFIG_SPI=y
+CONFIG_SPI_FSL_SPI=y
+CONFIG_GPIO_MPC8XXX=y
+CONFIG_GPIO_74X164=y
+CONFIG_POWER_RESET=y
+CONFIG_POWER_RESET_GPIO_RESTART=y
 CONFIG_WATCHDOG=y
+CONFIG_GPIO_WATCHDOG=y
+CONFIG_GPIO_WATCHDOG_ARCH_INITCALL=y
+CONFIG_8xxx_WDT=y
+CONFIG_REGULATOR=y
 CONFIG_HID_A4TECH=y
 CONFIG_HID_BELKIN=y
 CONFIG_HID_CHERRY=y
@@ -82,6 +96,13 @@ CONFIG_USB=y
 CONFIG_USB_MON=y
 CONFIG_USB_EHCI_HCD=y
 CONFIG_USB_EHCI_FSL=y
+CONFIG_NEW_LEDS=y
+CONFIG_LEDS_CLASS=y
+CONFIG_LEDS_CLASS_MULTICOLOR=y
+CONFIG_LEDS_GPIO=y
+CONFIG_LEDS_GROUP_MULTICOLOR=y
+CONFIG_LEDS_TRIGGERS=y
+CONFIG_LEDS_TRIGGER_HEARTBEAT=y
 CONFIG_RTC_CLASS=y
 CONFIG_RTC_DRV_DS1307=y
 CONFIG_RTC_DRV_DS1374=y

-- 
2.45.2

