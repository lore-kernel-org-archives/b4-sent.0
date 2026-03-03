From: David Heidelberg <david@ixit.cz>
Date: Tue, 03 Mar 2026 20:52:30 +0100
Subject: [PATCH v3 4/4] arm64: dts: rockchip: Define PCIe clock pinctrl for
 BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-4-af5a5207b0a1@ixit.cz>
References: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-0-af5a5207b0a1@ixit.cz>
In-Reply-To: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-0-af5a5207b0a1@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Frank Wunderlich <frank-w@public-files.de>
Cc: Martin Filla <freebsd@sysctl.cz>, 
 Charalampos Mitrodimas <charmitro@posteo.net>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1430; i=david@ixit.cz;
 h=from:subject:message-id; bh=phK8+ZRwh/J/YxkbsoLpGT+s0IxKqlf1J/b5vaUdLh0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppzv89u4mY2XaGjePhEcixdqoOdxzszV8SB3R0
 FfjESfkvsKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaac7/AAKCRBgAj/E00kg
 coMXEACr5SqodWnv0uSX0UNjzeDCfbfs618RVV3qPpmjTPFdWVY04Hf7dpBI8Ppe5G+OBshoplz
 lkG9U96qRUaz+oBdp3K6fD6+qIXteppjcOriPweKextma05UdkQt0HDLrQ2xgStuAXrpAh03Akf
 C1ATF6a9StzQU9WvoDnypBPnRD1Vziv17ZbEasNMzld4n7Sn5WDmcgTYtvSEJK3GKdO2uXdkbnG
 mqeVfhP9g36uJu//KJUWvBo1VhKiB7T69pV/2m9/lfpEfpSp6iPfmHU8gAcMRoIZOMryNKwZII3
 Lag4iSA0TFe5yNIIOU3bCMppDGSwTYSpmYrSVZVsh+XIw/E8o6R/KvTlq0xbC/ujNotYdpWmslM
 0oXxDOkkbJcw6NbyANWpJ+Rj76QnpXhVTYDrLdKg1CXh4x/Zx+bQKw7u4hw6OfoLAHWgayY1AN4
 Bw1Ef3LrdKwSziAr1rNfgJcLIg8TcMcqOaCHyn8/9Omhk1yu3WuCCgbw8HT7UrrP2LNvhq7H2OW
 K1vDpVO7Tm54yNXpB0kN8Jfb500Bv3pyixxK4r6cBKTgiR2x1CRYrP1g1RjJDyVu4nVpMPhkaP6
 1Fd1AAqpyusWuhbrCrsbtxYQn3jyQ5cB7nX9uiP1v4tHwKUYOxOV4+q0+ux1HRsWqHn3TIxXpAl
 iTMqCSASa/ixdYw==
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
index 3cdea9456a28c..95cf4a6236048 100644
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
@@ -652,6 +654,10 @@ ir_receiver_pin: ir-receiver-pin {
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

