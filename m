From: David Heidelberg <david@ixit.cz>
Date: Tue, 03 Mar 2026 20:52:27 +0100
Subject: [PATCH v3 1/4] arm64: dts: rockchip: assign pipe clock to rk3568
 PCIe lanes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-1-af5a5207b0a1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1684; i=david@ixit.cz;
 h=from:subject:message-id; bh=kBL8DfIbMEZId/mS9aT/ZMrXznRqWhpDEYin4PccSE4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppzv7Wv3xTTAHuxiN/ZqvtT/LDbQ8kHANgL2gf
 2gYzFH1ituJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaac7+wAKCRBgAj/E00kg
 cg18EAC4Hcmjx5yPY78MeXIWdgDG5ds2l3Pxnhjtmy7lALsL4hCfW4aX9rahnv14dF8xPR2D0pP
 z2m+aVGb7e4fwBBn5TCtS6+TxuZSFbyw9/TTI3te5JcoGtrs8GSAQOl4WtWVRNfOqOVrRqUJk/x
 feoSjS/zLrcpaBAr5dtw24bdps8H1k+5g/kLV0z9PZd8XHTq1YZwo2Ms5uzYRAVR9qrNEH8TC2J
 /mJQWinn76+YtotO9QUukpg45y2UzvUtxnA2EoyMQ85SLSiFRYKgmFZDzZZHXj/GIBteQh30MS8
 1kXUuGMWpx23ADPgCOESGsEv+VCQ+6plKjSKpMoQhUkpz0zdsH5eDKjw4VX3Ex/24+l42sVDRvc
 GNgLYWRkJvt6Z2p2Vt+ijJqglH0VZQrkv6MkTrpw7fTo8CgdyRVo0h5zJPPtHoc5I4GB2nUFef/
 gvtHFPRERqnXJEhz3P7xoHhgUtZO4H4ALZi+/GbjQb9mAOER2onws7ZtLyveHBR6Ww/jrre7ALG
 cgMP6BsOTDaYOA2v5gX+gX4JYv/0fVBfbAZT1qLcLEfbFjwh/irNWPlhwQRyri4IaqNKpFjobi2
 LwMBnOkWQKQzfUrZ9T0iJEv4zyntNxY5NMPMKg+chORgsV7j51PJIJ/5eswvCyU42dngK5iyaQk
 FM32cyvEh/DnvrQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These clocks are used by PCIe lanes, but we're missing from the
definition.

Suggested-by: Charalampos Mitrodimas <charmitro@posteo.net>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3568.dtsi | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

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

-- 
2.53.0

