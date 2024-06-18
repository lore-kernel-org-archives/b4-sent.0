From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Tue, 18 Jun 2024 14:08:21 +0200
Subject: [PATCH RESEND v10 10/12] arm64: Kconfig.platforms: Add config for
 Marvell PXA1908 platform
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240618-pxa1908-lkml-v10-10-754e5ece9078@skole.hr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=855;
 i=duje.mihanovic@skole.hr; h=from:subject:message-id;
 bh=/weGD6zZ+XyXeVQbi6D5jQYi2yqAzdUWcmbRjG7aBy0=;
 b=owEBbQKS/ZANAwAIAZoRnrBCLZbhAcsmYgBmcXjSx3UgRFn9yAkD1C8zTieIUAZnV7ogVifaT
 jRBrokHInqJAjMEAAEIAB0WIQRT351NnD/hEPs2LXiaEZ6wQi2W4QUCZnF40gAKCRCaEZ6wQi2W
 4cmfEACF2iqUZQtq/7/WYuCyPTliDob26KKmFjZVICvZd1pdhaW+nf+c8v55PFq2NnGM7sLsNMr
 9DhfWySt28bkVoQDvkquiieGyC9VcPobDdXAzEMt36+LSfXi8MP0dn6oAbUkBOMVETnusCnn2tA
 Q6BDWr8w/3KoXM4dSvAI4FXt6lLXp6hKyknghZIdTLwogRWaKHP1PTE23iNd/WSn/PjgrZk/WwB
 kQVOZtvmetpJnQEtuwWjlMWLZ9on1RZ9BUDBwccn5jalQPpI3LSRDKII9Bfj1s1gAbq21DwDdFx
 DwIrfJ5zTmD9EvKmFlvEtx2t/QtHrsHs7Tgs2rf045XHECEUZCSKCKcP/rscWFJRz3mVQ9d7sJ9
 gaLJzqJlTVmkVFrMdcFL0KSCm4nUjIUcgSw+3gnMc+6HzQfqHLKrwPdDa7ZdlaHLZ75/z+W97H2
 VZR9B/pPj7MahsMrmXPqt1NsZfOC8H9IIUy59tb74GJQDHhzMCzMelZOLqWJvduDeIcT+wQwN3Q
 QzBdbk96kh3Bmlr8W0ALNtOEHiFsNyg4McLhttpHI6+gR2/xzsvSW6nlqlm6aQMuO0Usuvk5S35
 Qb3+oojydj3CwWEHGo0DH4QTC2hY+ujK6cPWvJ1SjC6wXeAd9qWaDNMdw5g5o/iEGleD8AwlBIr
 BB0Mk7csaRROsIw==
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
2.45.2

