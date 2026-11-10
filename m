From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:19:37 +0000
Subject: [PATCH 2/2] sunxi: configs: OrangePi Zero2: talk to the AXP305
 over RSB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h616-rsb-spl-v1-2-bf91cc26507e@gmail.com>
References: <20261110-h616-rsb-spl-v1-0-bf91cc26507e@gmail.com>
In-Reply-To: <20261110-h616-rsb-spl-v1-0-bf91cc26507e@gmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Heiko Schocher <hs@nabladev.com>, Arun Iyengar <aiyengar1990@gmail.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794291575; l=1611;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Sm82lPYxuOnv7tZpazlI8lKhm1309USyRmkrQQsHfic=;
 b=biMMnyS/UxsM1i2pruGtOwcJoUclia474RqNm9ujXwIJXq2dAKydTP4WLhGkAsrFLtj4MdB2r
 eLREDXBHZx8Bfg9hCIt5cf8At7kZbJzbb4Y3ay8J8h5HQbETXsgGbih
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The OrangePi Zero2 device tree puts the AXP305 on r_rsb (pmic@745).
TF-A and Linux use RSB, and the PMIC stays in RSB mode across warm
reboots, so the SPL's R_I2C access fails on every reboot ("Failed to set
core voltage! Can't set CPU frequency", CPU left at 408 MHz until Linux
cpufreq takes over).

Use the RSB controller in the SPL instead and drop the now unused legacy
mvtwsi R_I2C setup. CONFIG_SPL_I2C stays: it builds drivers/i2c, and so
the RSB driver, into the SPL.

Tested on an OrangePi Zero2: before this change a cold boot was clean
and every warm reboot printed the error; with it neither does. U-Boot
proper still finds the PMIC on RSB through the DM driver.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 configs/orangepi_zero2_defconfig | 6 +-----
 1 file changed, 1 insertion(+), 5 deletions(-)

diff --git a/configs/orangepi_zero2_defconfig b/configs/orangepi_zero2_defconfig
index 371398fb70f..a45402e5ba8 100644
--- a/configs/orangepi_zero2_defconfig
+++ b/configs/orangepi_zero2_defconfig
@@ -9,16 +9,12 @@ CONFIG_DRAM_SUNXI_TPR6=0x33808080
 CONFIG_DRAM_SUNXI_TPR10=0xf83438
 CONFIG_MACH_SUN50I_H616=y
 CONFIG_SUNXI_DRAM_H616_DDR3_1333=y
-CONFIG_R_I2C_ENABLE=y
 CONFIG_SPL_SPI_SUNXI=y
 CONFIG_SPL_SUNXI_LED_STATUS=y
 CONFIG_SPL_SUNXI_LED_STATUS_GPIO=76
 # CONFIG_SYS_MALLOC_CLEAR_ON_INIT is not set
 CONFIG_SPL_I2C=y
-CONFIG_SPL_SYS_I2C_LEGACY=y
-CONFIG_SYS_I2C_MVTWSI=y
-CONFIG_SYS_I2C_SLAVE=0x7f
-CONFIG_SYS_I2C_SPEED=400000
+CONFIG_SYS_I2C_SUN8I_RSB=y
 CONFIG_MTD=y
 CONFIG_SPI_FLASH_MACRONIX=y
 CONFIG_SUN8I_EMAC=y

-- 
2.55.0

