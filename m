From: David Heidelberg <david@ixit.cz>
Date: Wed, 04 Mar 2026 12:05:28 +0100
Subject: [PATCH v4 2/4] arm64: dts: rockchip: Introduce the reference PCIe
 clk generator for BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260304-rk3568-bri-r2-pro-fix-pcie-v4-2-37abd7ba29d0@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1075; i=david@ixit.cz;
 h=from:subject:message-id; bh=DLgTWxKRH1XYO2l0p6yOj+4it8sVM+ozZghYVlPNXHU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpqBH5gdm8kJ6PRji07y1AoVW4weyCqyiqcXhyz
 CrdW/QqddWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaagR+QAKCRBgAj/E00kg
 cnTIEACNOBUR/FhB3Qhvx1ArPFV1jEbJ5Mkhq+52FBSzE/5xAhZolPSB4qwnxofKAUBCiqTAcCO
 RwL4DZJkDuo24vdIRvou7pIS0+tdAJwEcUUg+sK6TZV6if26D3nrG/b++oPQ2TkYFFcSfXlerXd
 MvBPs2QnBe9vZRrOIS+VkXyz3Dca1G0UY3KingyIp0ZSaIO224a6gKXtNxfC1VbD6Th1k6LKgK+
 qEk757LAspf1PJpLpfnesR1/mZ0yiZt8LU593uPEHDv1YuKW64Imnm+OIDjBoPzFqd/8c16o7I1
 fpQFy/cUT3rO8LP0YVlgnRNQKqJDpbJLOD7jwVHS0iMptNgvddV1/xYmEUAIFnCITA5Ao1vM/bL
 F5Q0epZXr7bWvvTwWF9EYad1eaVtgRRU411xkjYgO965wIS62cM9rOdTEn5+FcI3mNHW3IwYmTs
 2TeoaIu9VNpBR04FlwrhR36AkGkaRnSRjkokJDFbASTKyatIKjnhdnINdzMIVpq7NN59d1JPxQy
 i5YHy+rM8M++0tsz/cqnSMm+o6ZcfHvCtjSo+8CzmBwyl4I9QukITdnBs6JCLiwc+LUd0dT+FN3
 8qSPGhpchHPRI2WThVWQzLDVE2wxD9bDMK2ClB3lO/8g4d818CorlmbgzWxNaw1STgNCnhsjIRW
 VLphnSOIxGjgO0w==
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

