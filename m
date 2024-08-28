From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:20 +0100
Subject: [PATCH 12/20] arm: mach-sc5xx: clean up Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-12-44d9adfdf327@analog.com>
References: <20240828-sc5xx-upstreaming-patches-v1-0-44d9adfdf327@analog.com>
In-Reply-To: <20240828-sc5xx-upstreaming-patches-v1-0-44d9adfdf327@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=2293;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=GqAzHP3KosVfnR2WvoYCrPLMox90jgqaH+gfLsq7l78=;
 b=Dbqrde6b/peWVFsuWwr3sOp/ItUmKtntqaVhWuK5gupytt4s/kXNAXJqJglWA65I5anIO2sNj
 H2w6WPw5153B5PiI0BMxMUHy6jb2pkFhqW5AAttf55dx85ZwQaLMINj
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
 arch/arm/mach-sc5xx/Kconfig | 31 +++++++++++--------------------
 2 files changed, 19 insertions(+), 20 deletions(-)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index ba0359fed5..69decaa591 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1868,6 +1868,14 @@ config TARGET_LS1046AFRWY
 
 config ARCH_SC5XX
 	bool "Analog Devices SC5XX-processor family"
+	select SPL
+	select SUPPORT_SPL
+	select PANIC_HANG
+	select DM
+	select SPL_DM
+	select DM_SERIAL
+	select TIMER
+	select ADI_SC5XX_TIMER
 
 config TARGET_SL28
 	bool "Support sl28"
diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index 3846b4fd5b..d99b02b574 100644
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
+	bool "SC57x series"
 	select CPU_V7A
-	select PANIC_HANG
 	select COMMON_CLK_ADI_SC57X
-	select TIMER
-	select ADI_SC5XX_TIMER
 
 config SC58X
-	bool
-	select SUPPORT_SPL
+	bool "SC58x series"
 	select CPU_V7A
-	select PANIC_HANG
 	select COMMON_CLK_ADI_SC58X
-	select TIMER
-	select ADI_SC5XX_TIMER
 
 config SC59X
-	bool
-	select SUPPORT_SPL
+	bool "SC59x 32-bit series"
 	select CPU_V7A
-	select PANIC_HANG
 	select COMMON_CLK_ADI_SC594
-	select TIMER
-	select ADI_SC5XX_TIMER
 	select NOP_PHY
 
 config SC59X_64
-	bool
-	select SUPPORT_SPL
-	select PANIC_HANG
+	bool "SC59x 64-bit series"
 	select MMC_SDHCI_ADMA_FORCE_32BIT
 	select ARM64
-	select DM
-	select DM_SERIAL
 	select COMMON_CLK_ADI_SC598
 	select GICV3
 	select GIC_600_CLEAR_RDPD
 	select NOP_PHY
 
+endchoice
+
 config SC_BOOT_MODE
 	int "SC5XX boot mode select"
 	default 1

-- 
2.34.1

