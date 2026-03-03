From: David Heidelberg <david@ixit.cz>
Date: Tue, 03 Mar 2026 16:47:16 +0100
Subject: [PATCH v2 3/3] arm64: dts: rockchip: Define PCIe clock pinctrl for
 BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v2-3-04665e55d5a8@ixit.cz>
References: <20260303-rk3568-bri-r2-pro-fix-pcie-v2-0-04665e55d5a8@ixit.cz>
In-Reply-To: <20260303-rk3568-bri-r2-pro-fix-pcie-v2-0-04665e55d5a8@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Martin Filla <freebsd@sysctl.cz>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1430; i=david@ixit.cz;
 h=from:subject:message-id; bh=YlHCb0F1jScc81vTO0QX1ebEtLSzHBVXADDaJRK3w/o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppwKCO+kcSHyvVYUFDqdVlS/FKdg2A2uzn7r7i
 14m2Hb9WmOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaacCggAKCRBgAj/E00kg
 chSTD/0aqo0VrgY7y3pu2xg/5Hs9RLsyUQ9RMPw9nhqZxI+GaxgPgHw4Q4qmQCCxDun/wkv2zj9
 t6lZor6QRNaLMQ5UHuajfEsz1MH1Jg0wV1jXWdKuYn8KCd0542qPxl0cDDf9AzfafT9FsfafkCn
 VkL8Oz61MvzWpTbGcOLOJzFmEB3aCdxesPiKCMhAV0ueuckNtqWn/nA7rKnLPrqMpBpYspqbjSJ
 YeG5QIIj19+KIaOzhOjGgTh+tTXVpSesYCshI+c2ZaC8BRTmCQXwiZUodXIkd5dApKHPMeRLyIo
 fDTr+E7EUkXyMURwc+QaxIQYHJBhwATi3wRB58uok4wdnn77e+ZGfN63yv7BkSiQqdqnxcr8k/b
 Op1+1evuQWP+HK5AXtiAx98FQOp9OAeepOhHqS5u3g9UuT/gzuNmEzBCobDxybJMq/pOpj0DpzF
 errUiIHL8zg4bS+BEfkZvVMcjkYFZgmsNZl/y9646A1CjQ75sr4um8tSdWSaPHkkbq1Jao4JE2q
 Asi0jh/mJYzPaU2F77cy5Ahy1bWkuHKQVSMQu4O3ol5oCuy6H4KQ62OwKFDE+kCbnVWHxTuroEX
 fxwFpjhJ6YCDV1GF7wc72VBToyedtEFBweezk2XZ+RG88BUGJOQ60aEpWMdyO3q8MzXIzcdeOp5
 SjoHILyGCxzcoTw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without configuring the PCIe clock enable pin as an output, it
remains floating in input state. Some operating systems that rely
on correct pin settings may fail to boot as a result.

Fixes: 86973ae0355b ("arm64: dts: rockchip: Add PCIe v3 nodes to BPI-R2-Pro")
Reported-by: Martin Filla <freebsd@sysctl.cz> # reported by private message
Tested-by: Martin Filla <freebsd@sysctl.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
index a071cb67579c4..0616d9a065605 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
@@ -125,6 +125,8 @@ pcie_refclk: pcie-refclk-clock {
 		clocks = <&pcie_refclk_gen>;
 		#clock-cells = <0>;
 		enable-gpios = <&gpio0 RK_PD4 GPIO_ACTIVE_HIGH>;
+		pinctrl-0 = <&pcie_clkreq_h>;
+		pinctrl-names = "default";
 	};
 
 	vcc3v3_minipcie: regulator-vcc3v3-minipcie {
@@ -650,6 +652,10 @@ ir_receiver_pin: ir-receiver-pin {
 	};
 
 	pcie {
+		pcie_clkreq_h: pcie-clkreq-h {
+			rockchip,pins = <0 RK_PD4 RK_FUNC_GPIO &pcfg_output_high>;
+		};
+
 		minipcie_enable_h: minipcie-enable-h {
 			rockchip,pins = <0 RK_PC6 RK_FUNC_GPIO &pcfg_pull_none_drv_level_5>;
 		};

-- 
2.53.0

