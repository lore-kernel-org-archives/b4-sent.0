From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 15:15:14 +0200
Subject: [PATCH] configs: pinephone-pro-rk3399: Update defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-pinephone-pro-defconfig-v1-1-55487e8c269e@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6DIBAAwK+YPXcTsBWafqXxgLjoelgIqDEx/
 r20Pc5lTiiUmQq8mhMy7Vw4SoW+NeBnJxMhj9XQqtZopRUOD0wslOYohClHHCn4KIEnDM+7M8r
 ZzhoLNUiZAh+//N3/XbZhIb9+R7iuD+Z3G2t+AAAA
X-Change-ID: 20261010-b4-pinephone-pro-defconfig-f83a60a75767
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Tom Rini <trini@konsulko.com>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791638121; l=2291;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=LGxoUieiAALYyI9o4TtIl9xB4kxfL8qBhBu/xVpPm4M=;
 b=6tiyaHfqjo8EP5Z5RghI+dHK957so7j/+EBtoIqDEAw5TpuJ8XoFwujbLm4fQY9yqFIPjaMj9
 j7HMBWbvTm9ABNgq1p217giOEO6brnDyryfkIBP8WuP1wRy7hOsS/IN
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable:
- the ADC volume keys and the keyboard glue with phone key remap
- the USB gadget stack with DFU (SF/MMC/RAM) and mass storage
- the watchdog
- the clk/pause commands

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Enable the pieces needed to drive the Pinephone Pro without a serial
console:
- the ADC and GPIO buttons with the keyboard glue and phone key
remap
- the USB gadget stack with DFU (RAM/MMC/SF) and mass storage,
- the watchdog 
- the clk/pause commands.

The volume keys depend on the separate "button: adc: implement
get_code()" patch to produce key codes.
---
 configs/pinephone-pro-rk3399_defconfig | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/configs/pinephone-pro-rk3399_defconfig b/configs/pinephone-pro-rk3399_defconfig
index 81bc6d5400d..492b188f904 100644
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
@@ -80,8 +90,10 @@ CONFIG_SYS_USB_EVENT_POLL_VIA_INT_QUEUE=y
 CONFIG_USB_HOST_ETHER=y
 CONFIG_USB_ETHER_ASIX=y
 CONFIG_USB_ETHER_RTL8152=y
+CONFIG_USB_GADGET=y
 CONFIG_VIDEO=y
 CONFIG_DISPLAY=y
 CONFIG_VIDEO_ROCKCHIP=y
 CONFIG_DISPLAY_ROCKCHIP_EDP=y
+CONFIG_WDT=y
 CONFIG_ERRNO_STR=y

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261010-b4-pinephone-pro-defconfig-f83a60a75767

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

