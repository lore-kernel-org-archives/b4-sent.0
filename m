From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Tue, 18 Jun 2024 14:08:23 +0200
Subject: [PATCH RESEND v10 12/12] MAINTAINERS: add myself as Marvell
 PXA1908 maintainer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240618-pxa1908-lkml-v10-12-754e5ece9078@skole.hr>
References: <20240618-pxa1908-lkml-v10-0-754e5ece9078@skole.hr>
In-Reply-To: <20240618-pxa1908-lkml-v10-0-754e5ece9078@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Rob Herring <robh@kernel.org>, 
 Kees Cook <kees@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=906;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=60K3FrnypIaQAvLz7O5bioEXx//y4S3+gFksHisDh74=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmcXjSOS2p/8rQZm7yByMQ4Nd1bGlAhS7uPLxlC
 EYrHx1yZ/WJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZnF40gAKCRCaEZ6wQi2W
 4SReD/0R+w8r1SQk27VkYmuF17pC3bOJfVr3ndxV4wp9r/gwPZkmNhSb3DioagOAqfkwsydp/6/
 asykAUecEIC5PFjwlwybZt5cKG6ivRGymWe6/zJSRznLNqrAlde39TfsBVsseaqBk9ACvRzr0Qt
 aikYJ+/ih9dTTooNlMwZZfpkK9pqa0htORPEXED5lsum20iGhZG5crI4QEKa2vaD2AAaMT3rfNH
 XbwXb5dWgYgYTfXcq+qFJ44T3tzdiuPsCAP43qjNSqvNNOfloEaCWm0shSLWIygbI9TAGChrre3
 x4qv6CpDEoX0cy6CTQ3ryolx5sB80VPnfhnC4u1dlhpzH3uQ9bv8UDQ6eVxyPgiuZLGy2Iz9ATb
 cwU2J5fjSYZwq9XOTP6t/e+MmAdaxHZN7OIRtNi2bowpcn2NxTg4McekOoJb0i0KYSAdiuOPqP0
 QGi5/msfk4GuAPTDBBF62/+LvA5LMzEoNETRVDzlWFkHFAhoy59Rx/KGcsWJBwWW0Oia+49nMXV
 fr4VxRq7hWzJgxiz9M0S4/NyZIzFyMlyIKAG9yR5kyqgUWUE8I8az+FTD861xkavzzIDCMm8C6k
 302wJb7EUMzdqWMej10EGXp53jGSbEFjRrQu/KYg/F03DXy4CrbFwFethYGNkbxX47Xxos9ABC0
 TQge00coxSI+qYA==
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=53DF9D4D9C3FE110FB362D789A119EB0422D96E1
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/default with auth_id=112
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add myself as the maintainer for Marvell PXA1908 SoC support.

Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index ebf03f5f0619..5d48ac9801df 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2370,6 +2370,15 @@ F:	drivers/irqchip/irq-mvebu-*
 F:	drivers/pinctrl/mvebu/
 F:	drivers/rtc/rtc-armada38x.c
 
+ARM/Marvell PXA1908 SOC support
+M:	Duje Mihanović <duje.mihanovic@skole.hr>
+L:	linux-arm-kernel@lists.infradead.org (moderated for non-subscribers)
+S:	Maintained
+T:	git https://gitlab.com/LegoLivesMatter/linux
+F:	arch/arm64/boot/dts/marvell/pxa1908*
+F:	drivers/clk/mmp/clk-pxa1908*.c
+F:	include/dt-bindings/clock/marvell,pxa1908.h
+
 ARM/Mediatek RTC DRIVER
 M:	Eddie Huang <eddie.huang@mediatek.com>
 M:	Sean Wang <sean.wang@mediatek.com>

-- 
2.45.2

