From: David Heidelberg <david@ixit.cz>
Date: Tue, 03 Mar 2026 20:52:28 +0100
Subject: [PATCH v3 2/4] arm64: dts: rockchip: Introduce the reference PCIe
 clk generator for BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-2-af5a5207b0a1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1075; i=david@ixit.cz;
 h=from:subject:message-id; bh=DLgTWxKRH1XYO2l0p6yOj+4it8sVM+ozZghYVlPNXHU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppzv8N65m4KM+BMvXiPpSJgaTZWNY2Muclcn91
 khL9eN7veqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaac7/AAKCRBgAj/E00kg
 cu8QD/9k6zAchv5KkQTmT60ebjQDKVdinv5JqUf5iK+2cu9Sl4SXliBMpJHVw1FR0laqnEK7Ggd
 RAWnqQu1vRyNIkQZMuAmdJIrmaV99O4YnywJW8XagrpTxdJ/7zHtSW+4+INMzuPpQvbyNA4LsKo
 yBdc42Ges8gQh5FR58W4WtcIWED0tyIeKfwZuBV0KtrstxqxMjN+WEaUNvDT7m0CNNEkLF0b3OU
 p8OYyB4rubv65JubFPVZUNFUjEL5/GNDDyL844IXQINmEWmridmqY6VGO00tSlg6Y/GK13LmiN6
 ANrs1QokScTAjnYiXvtjd0e4S0cCPj5PIJtKNk8ULDR7YfHq8WBr9Ob+4bF03Tab+MovJqponLI
 P+DXHgEWUgOThX9JZBpMK+TdICT7qCaH2PlLQ8uztVC887rRVQjNhA6qFFFaHOFiUvQ4AoHCP44
 tmtx26nURA74eXnV4vik3HfQJOd05eDfTP8TOfw16UngipG6NnNqEExTAJe3xre9pNQ/lrCLPwJ
 OE4kRKk8KRBNWO4xR3bvo61IYDcDwnCihLH5eCdX5ysg3sd07XFQxm8FG9AohWWE2yqbRhCdRXO
 L0Rf68zAk0Vx2rZ52q4Hfxw3RTLoWPMnIKoq3FZcdq5J/ydT61l5JKdm6Rp3Q/MNu9cCUhYo+ku
 EboV8kd1A+poCwQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This clocks provides for both PCIe lanes. In following commit will be
utilized by PCIe clock.

Most likely PI6CG33602C or some variant of it.

Suggested-by: Heiko Stuebner <heiko@sntech.de>
Tested-by: Martin Filla <freebsd@sysctl.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
index 4d3ebe50b90ba..d02b82c5f979a 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts
@@ -114,6 +114,12 @@ pcie30_avdd1v8: regulator-pcie30-avdd1v8 {
 	};
 
 	/* pi6c pcie clock generator feeds both ports */
+	pcie_refclk_gen: pcie-refclk-gen-clock {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <100000000>;
+	};
+
 	vcc3v3_pi6c_05: regulator-vcc3v3-pi6c-05 {
 		compatible = "regulator-fixed";
 		regulator-name = "vcc3v3_pcie";

-- 
2.53.0

