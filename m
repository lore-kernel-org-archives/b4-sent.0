From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 11 Oct 2026 21:35:50 +0200
Subject: [PATCH v2 8/9] configs: pinephone-pro-rk3399: Update defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-pinephone-pro-defconfig-v2-8-6b7be35fbee7@protonmail.com>
References: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
In-Reply-To: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Ondrej Jirman <megi@xff.cz>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Lukasz Majewski <lukma@denx.de>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791747347; l=2042;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=rQ4wSUTjR+TG1pW9NQEigFLQuEmPwsgkU+YttSHkCC8=;
 b=gwl9Hg2zf8oX+YIAngmqmQJ3MPnnabS4/vwuOodJ2lg1h/8xRD9QMzuXg6n04b8dO9RixugHv
 pBilg2gHCLjDmsnUVgpuZGNB59dhYzCOF1/VLP27QR73DpDNWunBQv2
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable:
- the ADC volume keys and the keyboard glue with phone key remap
- the USB gadget stack with DFU (SF/MMC/RAM) and mass storage
- the watchdog
- the clk/pause commands
- replace the eDP display driver with the DW MIPI DSI one which the
  Himax HX8394 panel needs
- enable the D-PHY helpers and the video bridge uclass

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 configs/pinephone-pro-rk3399_defconfig | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/configs/pinephone-pro-rk3399_defconfig b/configs/pinephone-pro-rk3399_defconfig
index 81bc6d5400d..54f155abefd 100644
--- a/configs/pinephone-pro-rk3399_defconfig
+++ b/configs/pinephone-pro-rk3399_defconfig
@@ -29,21 +29,31 @@ CONFIG_SYS_SPI_U_BOOT_OFFS=0xE0000
 CONFIG_SPL_ATF_NO_PLATFORM_PARAM=y
 CONFIG_TPL=y
 CONFIG_CMD_BOOTZ=y
+CONFIG_CMD_CLK=y
+CONFIG_CMD_DFU=y
 CONFIG_CMD_GPIO=y
 CONFIG_CMD_GPT=y
 CONFIG_CMD_I2C=y
 CONFIG_CMD_MMC=y
 CONFIG_CMD_USB=y
+CONFIG_CMD_USB_MASS_STORAGE=y
 # CONFIG_CMD_SETEXPR is not set
 CONFIG_CMD_TIME=y
+CONFIG_CMD_PAUSE=y
 CONFIG_CMD_PMIC=y
 CONFIG_CMD_REGULATOR=y
 CONFIG_SPL_OF_CONTROL=y
 CONFIG_OF_SPL_REMOVE_PROPS="clock-names interrupt-parent assigned-clocks assigned-clock-rates assigned-clock-parents"
 CONFIG_ENV_IS_IN_SPI_FLASH=y
 CONFIG_ENV_RELOC_GD_ENV_ADDR=y
+CONFIG_BUTTON_REMAP_PHONE_KEYS=y
+CONFIG_BUTTON_ADC=y
+CONFIG_DFU_MMC=y
+CONFIG_DFU_RAM=y
+CONFIG_DFU_SF=y
 CONFIG_ROCKCHIP_GPIO=y
 CONFIG_SYS_I2C_ROCKCHIP=y
+CONFIG_BUTTON_KEYBOARD=y
 CONFIG_LED=y
 CONFIG_LED_GPIO=y
 CONFIG_MMC_DW=y
@@ -80,8 +90,13 @@ CONFIG_SYS_USB_EVENT_POLL_VIA_INT_QUEUE=y
 CONFIG_USB_HOST_ETHER=y
 CONFIG_USB_ETHER_ASIX=y
 CONFIG_USB_ETHER_RTL8152=y
+CONFIG_USB_GADGET=y
 CONFIG_VIDEO=y
 CONFIG_DISPLAY=y
 CONFIG_VIDEO_ROCKCHIP=y
-CONFIG_DISPLAY_ROCKCHIP_EDP=y
+CONFIG_DISPLAY_ROCKCHIP_DW_MIPI=y
+CONFIG_VIDEO_LCD_HIMAX_HX8394=y
+CONFIG_MIPI_DPHY_HELPERS=y
+CONFIG_VIDEO_BRIDGE=y
+CONFIG_WDT=y
 CONFIG_ERRNO_STR=y

-- 
2.55.0

