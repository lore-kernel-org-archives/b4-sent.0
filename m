From: David Heidelberg <david@ixit.cz>
Date: Tue, 03 Mar 2026 16:47:14 +0100
Subject: [PATCH v2 1/3] arm64: dts: rockchip: Introduce the reference PCIe
 clk generator for BPI-R2-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v2-1-04665e55d5a8@ixit.cz>
References: <20260303-rk3568-bri-r2-pro-fix-pcie-v2-0-04665e55d5a8@ixit.cz>
In-Reply-To: <20260303-rk3568-bri-r2-pro-fix-pcie-v2-0-04665e55d5a8@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Martin Filla <freebsd@sysctl.cz>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1075; i=david@ixit.cz;
 h=from:subject:message-id; bh=DLgTWxKRH1XYO2l0p6yOj+4it8sVM+ozZghYVlPNXHU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppwKCZCIoFv2sXDzcrPjnXi+tB+ytkrI1/HfhK
 nFqTHD/yYmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaacCggAKCRBgAj/E00kg
 cuZNEACTBZY0Psx6qqiEmOVSoJQGHaeY5kC8cjEpDIJ36SkjWF0Nfkk9uBJYUtgzgvSDKTn/rAq
 9DdfTHNpmLcxvMH7L2CniuVPYtJVomLoqieqOZpP8X4utINyAhpkzQIjzBp3XP/1jwrXCjCsyJL
 Jxi5Ow0z6FsuatqkjfeQgafRY7XgY4lta3fOh6YwniX3ggojxOB14Q4Vidj9kJQEkTXp0PHj17M
 NLcQFNDSWijkrua0hDvpjVueqt5Ut4GyN8ECD0+/XCsGDFd/fiYQxaTFKqM2jetXWzb6LnexXse
 lC7aZZOvYooa6E+ytTM2DIfMF9pVmMmcmN1I6NkxpEX+r1aWKG4nNjH8euT0NmP6OL5Yg94+olp
 IZbQv/NEHPsc9AhcJ8/p9DdoL36MHNqlEFkA9J0vd/I8M85bLj+REC3pkwx/YuAaecGAJB+Fyww
 vZQGgJS4Vd0HkIwQKJcGIDAZvDKXzlBmz53i25FExgw7A3ZLWanUEwBtslNicZaZK8/wc0HJ2pb
 lRi3nJSSoi92TYeXV5575Ou77a5fjQW71YRHkg+12yWFm4D4kbCtmvYwq//VRdxWyh4/muewLm/
 fFrDJDGnMrQ3Y/L+FSUfutRmB6AVSyCWbxMCG6597+bgMhwrm3eLjHeUT/EggKPcAn0e7X6qr2o
 JRl7yOPwhBw1cxg==
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

