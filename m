From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Date: Thu, 12 Sep 2024 19:24:51 +0100
Subject: [PATCH 06/21] include: dt-binding: clock: add adi clock header
 file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-test-v1-6-458fa57c8ccf@analog.com>
References: <20240912-test-v1-0-458fa57c8ccf@analog.com>
In-Reply-To: <20240912-test-v1-0-458fa57c8ccf@analog.com>
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Greg Malysa <greg.malysa@timesys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Utsav Agarwal <Utsav.Agarwal@analog.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Thomas Gleixner <tglx@linutronix.de>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, adsp-linux@analog.com, 
 Arturs Artamonovs <Arturs.Artamonovs@analog.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=4153;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=tPiF/DaY6UORa5f5iyBwG+k45QdAa3ZySrbsiRLF6Cc=;
 b=r71K9MzY6ONZnGXOuRJSwoTdhK0WXTFZ4S0T+uvezlfMOqM9MA/kGKSJMD86VcBBnyFCLjBBD
 JduICltZI6lA9QAIMLZjzW9gVzn4gOIYm0i3WCY9uEggXoVCd8M7dTZ
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add adi clock driver header file

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 include/dt-bindings/clock/adi-sc5xx-clock.h | 93 +++++++++++++++++++++++++++++
 1 file changed, 93 insertions(+)

diff --git a/include/dt-bindings/clock/adi-sc5xx-clock.h b/include/dt-bindings/clock/adi-sc5xx-clock.h
new file mode 100644
index 0000000000000000000000000000000000000000..723c11dc44f9741cff49dc2cb6c5232022abf00c
--- /dev/null
+++ b/include/dt-bindings/clock/adi-sc5xx-clock.h
@@ -0,0 +1,93 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * ADSP SC5xx clock device tree bindings
+ *
+ * Copyright 2022-2024 - Analog Devices Inc.
+ */
+
+#ifndef DT_BINDINGS_CLOCK_ADI_SC5XX_CLOCK_H
+#define DT_BINDINGS_CLOCK_ADI_SC5XX_CLOCK_H
+
+#define ADSP_SC598_CLK_DUMMY 0
+#define ADSP_SC598_CLK_SYS_CLKIN0 1
+#define ADSP_SC598_CLK_SYS_CLKIN1 2
+#define ADSP_SC598_CLK_CGU0_PLL_IN 3
+#define ADSP_SC598_CLK_CGU0_VCO_OUT 4
+#define ADSP_SC598_CLK_CGU0_PLLCLK 5
+#define ADSP_SC598_CLK_CGU1_IN 6
+#define ADSP_SC598_CLK_CGU1_PLL_IN 7
+#define ADSP_SC598_CLK_CGU1_VCO_OUT 8
+#define ADSP_SC598_CLK_CGU1_PLLCLK 9
+#define ADSP_SC598_CLK_CGU0_CDIV 10
+#define ADSP_SC598_CLK_CGU0_SYSCLK 11
+#define ADSP_SC598_CLK_CGU0_DDIV 12
+#define ADSP_SC598_CLK_CGU0_ODIV 13
+#define ADSP_SC598_CLK_CGU0_S0SELDIV 14
+#define ADSP_SC598_CLK_CGU0_S1SELDIV 15
+#define ADSP_SC598_CLK_CGU0_S1SELEXDIV 16
+#define ADSP_SC598_CLK_CGU0_S1SEL 17
+#define ADSP_SC598_CLK_CGU1_CDIV 18
+#define ADSP_SC598_CLK_CGU1_SYSCLK 19
+#define ADSP_SC598_CLK_CGU1_DDIV 20
+#define ADSP_SC598_CLK_CGU1_ODIV 21
+#define ADSP_SC598_CLK_CGU1_S0SELDIV 22
+#define ADSP_SC598_CLK_CGU1_S1SELDIV 23
+#define ADSP_SC598_CLK_CGU1_S0SELEXDIV 24
+#define ADSP_SC598_CLK_CGU1_S1SELEXDIV 25
+#define ADSP_SC598_CLK_CGU1_S0SEL 26
+#define ADSP_SC598_CLK_CGU1_S1SEL 27
+#define ADSP_SC598_CLK_CGU0_CCLK2 28
+#define ADSP_SC598_CLK_CGU0_CCLK0 29
+#define ADSP_SC598_CLK_CGU0_OCLK 30
+#define ADSP_SC598_CLK_CGU0_DCLK 31
+#define ADSP_SC598_CLK_CGU0_SCLK1 32
+#define ADSP_SC598_CLK_CGU0_SCLK0 33
+#define ADSP_SC598_CLK_CGU1_CCLK0 34
+#define ADSP_SC598_CLK_CGU1_OCLK 35
+#define ADSP_SC598_CLK_CGU1_DCLK 36
+#define ADSP_SC598_CLK_CGU1_SCLK1 37
+#define ADSP_SC598_CLK_CGU1_SCLK0 38
+#define ADSP_SC598_CLK_CGU1_CCLK2 39
+#define ADSP_SC598_CLK_DCLK0_HALF 40
+#define ADSP_SC598_CLK_DCLK1_HALF 41
+#define ADSP_SC598_CLK_CGU1_SCLK1_HALF 42
+#define ADSP_SC598_CLK_SHARC0_SEL 43
+#define ADSP_SC598_CLK_SHARC1_SEL 44
+#define ADSP_SC598_CLK_ARM_SEL 45
+#define ADSP_SC598_CLK_CDU_DDR_SEL 46
+#define ADSP_SC598_CLK_CAN_SEL 47
+#define ADSP_SC598_CLK_SPDIF_SEL 48
+#define ADSP_SC598_CLK_SPI_SEL 49
+#define ADSP_SC598_CLK_GIGE_SEL 50
+#define ADSP_SC598_CLK_LP_SEL 51
+#define ADSP_SC598_CLK_LP_DDR_SEL 52
+#define ADSP_SC598_CLK_OSPI_REFCLK_SEL 53
+#define ADSP_SC598_CLK_TRACE_SEL 54
+#define ADSP_SC598_CLK_EMMC_SEL 55
+#define ADSP_SC598_CLK_EMMC_TIMER_QMC_SEL 56
+#define ADSP_SC598_CLK_SHARC0 57
+#define ADSP_SC598_CLK_SHARC1 58
+#define ADSP_SC598_CLK_ARM 59
+#define ADSP_SC598_CLK_CDU_DDR 60
+#define ADSP_SC598_CLK_CAN 61
+#define ADSP_SC598_CLK_SPDIF 62
+#define ADSP_SC598_CLK_SPI 63
+#define ADSP_SC598_CLK_GIGE 64
+#define ADSP_SC598_CLK_LP 65
+#define ADSP_SC598_CLK_LP_DDR 66
+#define ADSP_SC598_CLK_OSPI_REFCLK 67
+#define ADSP_SC598_CLK_TRACE 68
+#define ADSP_SC598_CLK_EMMC 69
+#define ADSP_SC598_CLK_EMMC_TIMER_QMC 70
+#define ADSP_SC598_CLK_3PLL_PLL_IN 71
+#define ADSP_SC598_CLK_3PLL_VCO_OUT 72
+#define ADSP_SC598_CLK_3PLL_PLLCLK 73
+#define ADSP_SC598_CLK_3PLL_DDIV 74
+#define ADSP_SC598_CLK_DDR_SEL 75
+#define ADSP_SC598_CLK_DDR 76
+#define ADSP_SC598_CLK_CGU0_VCO_2_OUT 77
+#define ADSP_SC598_CLK_CGU1_VCO_2_OUT 78
+#define ADSP_SC598_CLK_3PLL_VCO_2_OUT 79
+#define ADSP_SC598_CLK_END 80
+
+#endif

-- 
2.25.1

