From: David Heidelberg <david@ixit.cz>
Date: Wed, 04 Mar 2026 12:05:27 +0100
Subject: [PATCH v4 1/4] arm64: dts: rockchip: assign pipe clock to rk356x
 PCIe lanes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260304-rk3568-bri-r2-pro-fix-pcie-v4-1-37abd7ba29d0@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2523; i=david@ixit.cz;
 h=from:subject:message-id; bh=nJWr1cG55C7TfO8lmuP7iO4pkz7D7P5warAqQ5V7GaM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpqBH5+76cstljDcdJQqO27u9npzazHz0WHktMs
 RATNgGZiVSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaagR+QAKCRBgAj/E00kg
 ctxBD/wIdVOClRo0Xr9QvWclph7PqoDR44+VURYr41+YD/4RlyzAe/948Bu4XS2V4Ujyp+TfGH7
 Jmnd831Htg/1Y/2nOK8Jfd5Dc7QFK+pihhm7IOy3AR9g54sz7ddaAvdRGz/xa6sh2zMO2U4JZQw
 ud8Z6oJsy3xJTeS11PTH8UUTQkjcnalAqsxQQPgtD+BShRVHQEPMvplR8TDyo8VVherlOjt7jdI
 bKI09/HIOLQKDh6hG9cCStcfRZpV6CinHfNMTdPHTtDOb6LdUC0a3SIdOxXcG+nxzRoJajGFkbW
 mBuk1ijJngCropAIITQGS7d1ROhXx4+m6ehxMFrjF2NNyd4tbuSBJ1LlQZdWIrDS5kSPwTfA6Us
 pX3v3XmIe0RLgcVkxzURUWjNA96va95xQnviXhAJwiBW3S3CVJTcXxW2LCxSFQ92d+X2Zdcn0t/
 0liNFDU1E8k2Ght8tBN5DQgB2lQgnRKDBdy7+CgEPwh0SJDtqJgauDNjiH3aQN7Cfg+UAAFl1Tq
 wEh8uNOoGXiLcrjaVjLD80e8BsCxfuXBeylgIcaW8vykJlb7mPtHenVOMUwAgeegFTND9tktZS1
 T+4wQAbotfwUYigrPhhUE7rs+0EQ8IsZnaJOTmkBRFnqyqE3HbInprZNMvOmmyu/Ybw4om9BafU
 fwqmyGml7G0cjtg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These clocks are used by PCIe lanes, but we're missing from the
definition.

Suggested-by: Charalampos Mitrodimas <charmitro@posteo.net>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3568.dtsi      | 12 ++++++++----
 arch/arm64/boot/dts/rockchip/rk356x-base.dtsi |  6 ++++--
 2 files changed, 12 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3568.dtsi b/arch/arm64/boot/dts/rockchip/rk3568.dtsi
index 658097ed69714..3bc653f027f1f 100644
--- a/arch/arm64/boot/dts/rockchip/rk3568.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3568.dtsi
@@ -155,9 +155,11 @@ pcie3x1: pcie@fe270000 {
 		bus-range = <0x10 0x1f>;
 		clocks = <&cru ACLK_PCIE30X1_MST>, <&cru ACLK_PCIE30X1_SLV>,
 			 <&cru ACLK_PCIE30X1_DBI>, <&cru PCLK_PCIE30X1>,
-			 <&cru CLK_PCIE30X1_AUX_NDFT>;
+			 <&cru CLK_PCIE30X1_AUX_NDFT>,
+			 <&cru CLK_PCIE30X1_PIPE_DFT>;
 		clock-names = "aclk_mst", "aclk_slv",
-			      "aclk_dbi", "pclk", "aux";
+			      "aclk_dbi", "pclk", "aux",
+			      "pipe";
 		device_type = "pci";
 		interrupts = <GIC_SPI 160 IRQ_TYPE_LEVEL_HIGH>,
 			     <GIC_SPI 159 IRQ_TYPE_LEVEL_HIGH>,
@@ -208,9 +210,11 @@ pcie3x2: pcie@fe280000 {
 		bus-range = <0x20 0x2f>;
 		clocks = <&cru ACLK_PCIE30X2_MST>, <&cru ACLK_PCIE30X2_SLV>,
 			 <&cru ACLK_PCIE30X2_DBI>, <&cru PCLK_PCIE30X2>,
-			 <&cru CLK_PCIE30X2_AUX_NDFT>;
+			 <&cru CLK_PCIE30X2_AUX_NDFT>,
+			 <&cru CLK_PCIE30X2_PIPE_DFT>;
 		clock-names = "aclk_mst", "aclk_slv",
-			      "aclk_dbi", "pclk", "aux";
+			      "aclk_dbi", "pclk", "aux",
+			      "pipe";
 		device_type = "pci";
 		interrupts = <GIC_SPI 165 IRQ_TYPE_LEVEL_HIGH>,
 			     <GIC_SPI 164 IRQ_TYPE_LEVEL_HIGH>,
diff --git a/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi b/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi
index 68b48606f6010..15741acac6274 100644
--- a/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk356x-base.dtsi
@@ -1020,9 +1020,11 @@ pcie2x1: pcie@fe260000 {
 		bus-range = <0x0 0xf>;
 		clocks = <&cru ACLK_PCIE20_MST>, <&cru ACLK_PCIE20_SLV>,
 			 <&cru ACLK_PCIE20_DBI>, <&cru PCLK_PCIE20>,
-			 <&cru CLK_PCIE20_AUX_NDFT>;
+			 <&cru CLK_PCIE20_AUX_NDFT>,
+			 <&cru CLK_PCIE20_PIPE_DFT>;
 		clock-names = "aclk_mst", "aclk_slv",
-			      "aclk_dbi", "pclk", "aux";
+			      "aclk_dbi", "pclk", "aux",
+			      "pipe";
 		device_type = "pci";
 		#interrupt-cells = <1>;
 		interrupt-map-mask = <0 0 0 7>;

-- 
2.53.0

