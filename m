From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Wed, 24 Apr 2024 20:42:39 +0200
Subject: [PATCH v10 12/12] MAINTAINERS: add myself as Marvell PXA1908
 maintainer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240424-pxa1908-lkml-v10-12-36cdfb5841f9@skole.hr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=906;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=IAO2s2H9eu3z+8543Qj+Twu7btrO5EN1Y9FniKrdIpI=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmKVKVE2n5S7pMEvJ2dz5c5NHiJUcq66HbNB47N
 dzaKjRup7+JAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZilSlQAKCRCaEZ6wQi2W
 4WZCD/0e6BPwFLQgizdDY83IxSn9oXdBBmvVOC8UrCDlq+RZqV20ZPSC/Fwa2WvlgS3KujswLP4
 Ic9DKe9rZkIIUzr+QzaL3Z94bgSVXDxfs2W/rHMRlD2v/EH/A5k6ciR5cou9lcRkl68SYwevmVj
 qzaxs5gh5OG27pKWbunNHSHMhmDWhbawbWz5KFEfkcYe4FcsaYqigw3JPpiKVFGGNfKJ5w0x/xb
 pyDhPqrE96Irc77j37PGHeNJhmHX6dPgnEP7w997pE0d3kwNwlfW7IC2huzz+WHiZBq1p5lZcpA
 bwqEbB65dA7F6PhfErDC8Ohp3jWgvDDEU2z2OVEBL7fX3MLC0W1s0QrVm8xhEPKDwrh3GnrJPBO
 q79TUoZZTAD1oryVw/CBdRbl1ee1nGRxNWdByJekEBSWDYkGXk7qeqorzBQYFEP/uHEbn0Ck5EW
 HlPjUn4MOdn184Ngh4Y/hYwkXH11GQo7jgysCLviH0RVOi/SZwxh9Hlzv2uxMZ7j82JCxtDAdN3
 ph7B+fWWz9WM6+jC40qrOWsPSPj75Z8Z9tIuykacvdZasIdGRN9M9WDrqyZCcR9Qz3pp8ME2faJ
 jCU3+2ERgJOpCD0Nmp4IzLZqa7cLY4i6KACiJ5e0dg36zY+Ley0m9nxNBUS3g+HhOwgHi+5Vb24
 r9I3U9sMvziOoyA==
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
2.44.0

