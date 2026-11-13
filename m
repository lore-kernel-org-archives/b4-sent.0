From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 20:37:56 +0000
Subject: [PATCH] arm64: dts: rockchip: Fix the order of the RK3588 AV1
 decoder resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-rk3588-av1-reset-order-v1-1-d73f60222ff9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqCQBCF4VeRuW6gcTW0VwkvdvVUU6AxYxKI7
 +5Wlx+H86/kMIXTuVjJsKjrNGbIoaD+HscbWIdsKo/lSUQC2zPUTcNxETY4Zp5sgHGq8h7bOqY
 2UD6/DFf9/MKX7m9/pwf6+VujbdsBhO9S/noAAAA=
X-Change-ID: 20261113-rk3588-av1-reset-order-b4261a95ab93
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794602276; l=1508;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=YP+Ju9QjQfuU0YGwfWBljQdLr0V0QHLGHZyAd+cCC3w=;
 b=h2Y6s+lUrSYGVaonyq4DMPUpiqk68iJw40e55HnQ6t7RM1x9PLBQhBMoWYd4m+8wB0YLKqp18
 ZScq/59KbGvCoQqS2b+yERSYY7jGHr4Gf+2ESpKOOVfHH4VqwHLBUul
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The binding lists the AV1 resets as AXI, AXI BIU, APB, APB BIU. Use that
order. The driver gets them as an array, so only the order in which they
are toggled changes.

Fixes: dd6dc0c4c126 ("arm64: dts: rockchip: Add AV1 decoder node to rk3588s")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found while describing the same resets on the AV1 IOMMU (hantro-robust
v3). AV1 fluster on RK3588S (Orange Pi 5) is unchanged (203/242).

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed it.
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index d0f364547ae5..3d1e4369578b 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -1471,7 +1471,8 @@ av1d: video-codec@fdc70000 {
 		clocks = <&cru ACLK_AV1>, <&cru PCLK_AV1>;
 		clock-names = "aclk", "hclk";
 		power-domains = <&power RK3588_PD_AV1>;
-		resets = <&cru SRST_A_AV1>, <&cru SRST_P_AV1>, <&cru SRST_A_AV1_BIU>, <&cru SRST_P_AV1_BIU>;
+		resets = <&cru SRST_A_AV1>, <&cru SRST_A_AV1_BIU>,
+			 <&cru SRST_P_AV1>, <&cru SRST_P_AV1_BIU>;
 		iommus = <&av1d_mmu>;
 	};
 

---
base-commit: c3baae5f1a15645cddadcb2b9abddef5df291f59
change-id: 20261113-rk3588-av1-reset-order-b4261a95ab93

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

