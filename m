From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Wed, 24 Apr 2024 20:42:37 +0200
Subject: [PATCH v10 10/12] arm64: Kconfig.platforms: Add config for Marvell
 PXA1908 platform
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240424-pxa1908-lkml-v10-10-36cdfb5841f9@skole.hr>
References: <20240424-pxa1908-lkml-v10-0-36cdfb5841f9@skole.hr>
In-Reply-To: <20240424-pxa1908-lkml-v10-0-36cdfb5841f9@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Rob Herring <robh@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=855;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=rBtIaMX/S+mXR29Z1GK6jtLfsrLvd3qrx2yb5nOvyjo=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmKVKVNt92SFDaPgTEWzHx72+qUm3NYr8Z9zD8o
 8yQBGJGx6iJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZilSlQAKCRCaEZ6wQi2W
 4ZctD/oDQ5OlhApU7EoZW19q2bjbafF+P/NCUzFD+2S2yom+WEQK1WpfZ1dj0KG7cbuhxc3hE+2
 lYY439xTg9snFnmDEQZ09IeEJh+uJpMO1xWRSWHeFK5w2FqGauqewnCTaZZIOkPyA96qf+C2OF5
 3YQl3CAweeeTnoRTzNuF7FnoCc7gedZoN2nEGoC5NF9puhypeLf0Y0rb9HHawO8Lf5X1JIVe8uU
 Hi2xSp3rjCQN+VCP4fAwXT61+NQ0H86MFEJVThhNw0qq2u/Gs8OkSKNh+KK0vNvAKtJo98q6G4I
 Oo8dfrs7wiIRD0PXUUgGXnMdeN1JKN9ko4lLfNJksHJBTDP6vlQRIAI4laggQylOKff0nhZMDVq
 CTpDWg8FBlcmSOk+BobS1BeD3tg6U52xMl+hWFruwm/VMYps7ELVCFK63Luln6ilCXt5Eip28at
 QFwpEUro9CuBP8ZjSXGIXUlOK9mSM3D5tUtB3oQp2W60rBxnPlTaZWD1utNRfOHQq8RE0TEblBO
 u6VkNNmKyj636CcLXzZz1r0XM4cRMUP7giLxMdHQkaQPOWU8M486z/nc7lASivLSk0Z8kLQjjdl
 qU7+sjWZzRuoWPWL9W5cAf5zjJ27wBypYREME8k3XnlpfuPXXG0p2IP9r4AVkzFOD9PrSb3cqhp
 flToYKOCMTXfUmA==
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=53DF9D4D9C3FE110FB362D789A119EB0422D96E1
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/default with auth_id=112
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ARCH_MMP configuration option for Marvell PXA1908 SoC.

Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 arch/arm64/Kconfig.platforms | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/Kconfig.platforms b/arch/arm64/Kconfig.platforms
index 24335565bad5..d71b0b6e75aa 100644
--- a/arch/arm64/Kconfig.platforms
+++ b/arch/arm64/Kconfig.platforms
@@ -168,6 +168,14 @@ config ARCH_MESON
 	  This enables support for the arm64 based Amlogic SoCs
 	  such as the s905, S905X/D, S912, A113X/D or S905X/D2
 
+config ARCH_MMP
+	bool "Marvell MMP SoC Family"
+	select PINCTRL
+	select PINCTRL_SINGLE
+	help
+	  This enables support for Marvell MMP SoC family, currently
+	  supporting PXA1908 aka IAP140.
+
 config ARCH_MVEBU
 	bool "Marvell EBU SoC Family"
 	select ARMADA_AP806_SYSCON

-- 
2.44.0

