From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Mon, 04 Nov 2024 17:37:14 +0100
Subject: [PATCH RESEND v13 12/12] MAINTAINERS: add myself as Marvell
 PXA1908 maintainer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241104-pxa1908-lkml-v13-12-e050609b8d6c@skole.hr>
References: <20241104-pxa1908-lkml-v13-0-e050609b8d6c@skole.hr>
In-Reply-To: <20241104-pxa1908-lkml-v13-0-e050609b8d6c@skole.hr>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Tony Lindgren <tony@atomide.com>, 
 Haojian Zhuang <haojian.zhuang@linaro.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>, 
 Lubomir Rintel <lkundrak@v3.sk>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Karel Balej <balejk@matfyz.cz>, David Wronek <david@mainlining.org>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=962;
 i=duje.mihanovic@skole.hr; s=20240706; h=from:subject:message-id;
 bh=WJM+jdOH+cWyAFZLAoZ/ZBIMQFxb1HLmL8TqRXOMrF0=;
 b=owGbwMvMwCW21nBykGv/WmbG02pJDOkaf0MNPB6lPD7iNKF2s8Rsb+V5SXwSPWseiFx8wBlUV
 96w78GDjlIWBjEuBlkxRZbc/47XeD+LbN2evcwAZg4rE8gQBi5OAZjI1+cM/+z3NQT+mvjB6FRY
 smqTh0/i24+zdqZ+6H19a285Z8N1NUGGfxZSe/q2C+Q/r9+ycP1vvXM1K1a9u3S5fdGCJ86LVwS
 kz+QCAA==
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=6DFF41D60DF314B5B76BA630AD319352458FAD03
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/20240706 with auth_id=191
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add myself as the maintainer for Marvell PXA1908 SoC support.

Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c27f3190737f8b85779bde5489639c8b899f4fd8..8d50cb7457924e3290810eaf7d3c4b145d988ede 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2593,6 +2593,15 @@ F:	drivers/irqchip/irq-mvebu-*
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
2.47.0

