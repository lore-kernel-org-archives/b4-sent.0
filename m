From: David Heidelberg <david@ixit.cz>
Date: Wed, 04 Mar 2026 12:05:30 +0100
Subject: [PATCH v4 4/4] arm64: dts: rockchip: Define PCIe clock pinctrl for
 BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260304-rk3568-bri-r2-pro-fix-pcie-v4-4-37abd7ba29d0@ixit.cz>
References: <20260304-rk3568-bri-r2-pro-fix-pcie-v4-0-37abd7ba29d0@ixit.cz>
In-Reply-To: <20260304-rk3568-bri-r2-pro-fix-pcie-v4-0-37abd7ba29d0@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpqBH5PO9/6ue5v3vMfwoqhAKzbGkWb5HOukqEv
 PUg0fESJGqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaagR+QAKCRBgAj/E00kg
 crOAD/9ASb2JoxmVej5rj1mI/ep6xH9GgV09wCCinkiCPRPN01eYn5FqLFzwKkg0f26RrlnLZtv
 K7u9wfqXcUimhp36PY+v4WY8QY79h5zCTNT6teP6U1M6QVSnGs+bRjR92WT8nOuSEAY6XGzB8Rm
 1h4PkXpYjI2YlUJcpHfeQOZrFN5FjkGsPXVJzXjTQ3b3FEJiQCdpYvFzrWIifTFzCfirfOCFWtz
 ajx0i1Ch5CmrpLEqnXPDnH0LgGiMDC7u7So2bn6IZBSeZL1M+u7c+0kSE1WRllq0CivYTXVfqWP
 0p9CJ+LO3uBdISZtHkIn92QjFgQ7do8NHfrW5xxxVIqIbCioDYMcusDEznazLL5AkfF8OnKyQTD
 ItPvpLGbiOggufGmQ008s5GG6AQN2DhuvPteF5taxQu2bae9JHd4Cyb81fItzMNUujL6eWW6Xrc
 HrktZuGYACmEXX5k1R3aEFjEZHyvzfVlSe2vFQ4sITivvwrMRIltEvpBPDgPKndoL7g5oZyBH0s
 +NGGzDCEK+lZoFJV8HXEhVtfn+RaMi2U1sZncUZ7UFuDuQyZKviBRBLNpiRuMqi5RfXBLREvj+F
 6c+slrev30iiFaBH0UhZTKCBK/ES44VJ4tH1z5TzZNJtvefqttrOnkxhw3KzZ2j0dV2ww7OWkcp
 xTn5goOXjzRjlOw==
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

