From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:53 +0100
Subject: [PATCH v2 12/20] arm: mach-sc5xx: clean up Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-12-1185a80df79e@analog.com>
References: <20240912-sc5xx-upstreaming-patches-v2-0-1185a80df79e@analog.com>
In-Reply-To: <20240912-sc5xx-upstreaming-patches-v2-0-1185a80df79e@analog.com>
To: Tom Rini <trini@konsulko.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>, 
 Greg Malysa <greg.malysa@timesys.com>, 
 Ian Roberts <ian.roberts@timesys.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Utsav Agarwal <utsav.agarwal@analog.com>, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, adsp-linux@analog.com, 
 Oliver Gaskell <Oliver.Gaskell@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=2392;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=7bnm3vMM/zOKe6FK7GtGt37ws75/PYDFzRyCKZfj0UQ=;
 b=z/biYdkmo15DiI0AB8LkCwPigkYm1lmxiGDBhGrjT5FIc4yuskdQcErtcXpBvzc8/z0GEV5aD
 jEvM1tTT/K4CpMtJWLvRfGLwBIf6cgGeWeBfBy19jo/oyuuqZ55ke0p
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Moves common options between all SC5xx series boards to the ARCH_SC5XX
option instead of duplicating them.

Also, it was possible to select multiple of the SoC support options.
Given a U-Boot binary can only support a single platform, this moves
the SoC selection to a `choice`, making them mutually exclusive.

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/Kconfig            |  8 ++++++++
 arch/arm/mach-sc5xx/Kconfig | 39 +++++++++++++++------------------------
 2 files changed, 23 insertions(+), 24 deletions(-)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index ba0359fed5..72960126ee 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1868,6 +1868,14 @@ config TARGET_LS1046AFRWY
 
 config ARCH_SC5XX
 	bool "Analog Devices SC5XX-processor family"
+	select ADI_SC5XX_TIMER
+	select DM
+	select DM_SERIAL
+	select PANIC_HANG
+	select SPL
+	select SPL_DM
+	select SUPPORT_SPL
+	select TIMER
 
 config TARGET_SL28
 	bool "Support sl28"
diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index 3846b4fd5b..2ec09dbf3e 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -13,47 +13,38 @@
 
 if ARCH_SC5XX
 
+choice
+	prompt "SC5xx SoC Select"
+	help
+	  Selects which series of Analog Devices SC5xx chips to support.
+
 config SC57X
-	bool
-	select SUPPORT_SPL
-	select CPU_V7A
-	select PANIC_HANG
+	bool "SC57x series"
 	select COMMON_CLK_ADI_SC57X
-	select TIMER
-	select ADI_SC5XX_TIMER
+	select CPU_V7A
 
 config SC58X
-	bool
-	select SUPPORT_SPL
-	select CPU_V7A
-	select PANIC_HANG
+	bool "SC58x series"
 	select COMMON_CLK_ADI_SC58X
-	select TIMER
-	select ADI_SC5XX_TIMER
+	select CPU_V7A
 
 config SC59X
-	bool
-	select SUPPORT_SPL
-	select CPU_V7A
-	select PANIC_HANG
+	bool "SC59x 32-bit series"
 	select COMMON_CLK_ADI_SC594
-	select TIMER
-	select ADI_SC5XX_TIMER
+	select CPU_V7A
 	select NOP_PHY
 
 config SC59X_64
-	bool
-	select SUPPORT_SPL
-	select PANIC_HANG
-	select MMC_SDHCI_ADMA_FORCE_32BIT
+	bool "SC59x 64-bit series"
 	select ARM64
-	select DM
-	select DM_SERIAL
 	select COMMON_CLK_ADI_SC598
 	select GICV3
 	select GIC_600_CLEAR_RDPD
+	select MMC_SDHCI_ADMA_FORCE_32BIT
 	select NOP_PHY
 
+endchoice
+
 config SC_BOOT_MODE
 	int "SC5XX boot mode select"
 	default 1

-- 
2.34.1

