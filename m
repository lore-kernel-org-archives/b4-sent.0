From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 16:54:41 +0100
Subject: [PATCH] arm64: dts: rockchip: Fix PCIe v3 pinctrl for BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-rk3568-bri-r2-pro-fix-pcie-v1-1-b9ed318b4a77@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAEBhpGkC/x3MQQqAMAwAwa9IzgZipEX8inhQGzUIWlIQofh3i
 8dhYTMkMZUEfZXB5Nak11nQ1BUs+3RughqKgYk9MTPa0Trf4WyKxhjtwlUfjIsKts7NxBQCBYY
 yiCal/fNhfN8POnPaC2wAAAA=
X-Change-ID: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Filla <freebsd@sysctl.cz>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1564; i=david@ixit.cz;
 h=from:subject:message-id; bh=hKBdwEW8s0wqw58AWppcp4beoynxrSnUvu08wYJII6o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppGFF+OKscrXtUKPDUFx1VkK4u15AJq+eTA10S
 HKh+d13akmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaRhRQAKCRBgAj/E00kg
 crgaD/0VyX+botSQ88NN25oGRqXJmjFf1KShvyRNvpP5FgOhaNsL4szbYoAHmGY+XZ6rpYSDH3g
 4kwvPSHs7tZOACQoo1BhoF1l13hSbwD5ChdL2OKLKbHX/aJHzU2YK//zIqG5MyfoyMZ4XGWVrvd
 3DQdQyHQP7NWWBai8F0IJaiumCNiF7PzbfHCXv81RL+mbREWsSFtNecbhzr46Vb3ezFXlYOyveX
 /7e+gHe16CmitpIEsLPAk3fIOQl2rPBjR/nXWL8HwQYiaz7pZsN/2oC9EltxfjY9TipRzxSLL2k
 CLC1p3pOFZHBaLJO3AAv1ubptvG3hoYhvFOKutvFW2Vn5ZpVHTZhYsZ/vxieBB8k7UN7p0sdeeU
 JXOOeDQd5E4zDESzi98nciwYVgN/wq3IaeqvR9hxc71gSNaY1pefyU+iXAMX8X92iXGApDOUCyQ
 veRuSw/m6r8mpoFfhp2+FKBARLPUFhgZ7Sf1Uzr8Q+HIBAy7mfkBs5EGGUxKfEotEH2DSTdy5By
 06dol0CN9ASQt7KoS39noEQ0cKHOC8g87uv7giI5fG8sfF9p4C/oFrfCUhFW+g32lwzG0kpjDRg
 Eqn16bX/KavbXYJOUvy25/guZaOLH7iNwLxgIopkigoUATTdQS6D6VQsImsSvzRMHShkhAmyxfh
 +YOn0Y08lnSV1xg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missing pinctrl for PD4 (PI6C PCIe clock enable,
PCIE_CLKEN_H_GPIO0_D4) and set output high.

This does fix freeze at initialization due pinctrl being in input
state.

Reported-by: Martin Filla <freebsd@sysctl.cz> # reported by private message
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
index 4d3ebe50b90ba..b4c8abe37d1f3 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
@@ -121,6 +121,8 @@ vcc3v3_pi6c_05: regulator-vcc3v3-pi6c-05 {
 		regulator-max-microvolt = <3300000>;
 		enable-active-high;
 		gpios = <&gpio0 RK_PD4 GPIO_ACTIVE_HIGH>;
+		pinctrl-0 = <&pi6cpcie_enable_h>;
+		pinctrl-names = "default";
 		startup-delay-us = <200000>;
 		vin-supply = <&vcc5v0_sys>;
 	};
@@ -635,6 +637,10 @@ ngffpcie_enable_h: ngffpcie-enable-h {
 			rockchip,pins = <0 RK_PB7 RK_FUNC_GPIO &pcfg_pull_none_drv_level_5>;
 		};
 
+		pi6cpcie_enable_h: pi6cpcie-enable-h {
+			rockchip,pins = <0 RK_PD4 RK_FUNC_GPIO &pcfg_output_high>;
+		};
+
 		minipcie_reset_h: minipcie-reset-h {
 			rockchip,pins = <2 RK_PD6 RK_FUNC_GPIO &pcfg_pull_none_drv_level_5>;
 		};

---
base-commit: 3fa5e5702a82d259897bd7e209469bc06368bf31
change-id: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2

Best regards,
-- 
David Heidelberg <david@ixit.cz>

