From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:38:55 +0000
Subject: [PATCH 9/9] arm64: dts: rockchip: Enable the RK3588 PHP SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-mmu600-php-v1-9-231196049a3b@gmail.com>
References: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
In-Reply-To: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Serge Semin <fancer.lancer@gmail.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 Pranjal Shrivastava <praan@google.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, iommu@lists.linux.dev, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587927; l=915;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=4ZmzBM5N9jnNuYTiHIYDASnKZmkuELiFGEfiQed/VEM=;
 b=9nRVvarFiIbiga3zvvB8t4RnRG95GwOLtsETdu1rIreww2yx1869NX4XiuZ4gNhq3OMMnZUwR
 k6gzh4xD/bGCyX8cwf/QisIjRmWfOWJBKa8+I4+NG5xwYSODUKSGQpz
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Its masters now have StreamIDs and iommus, and the SMMU has its clock.

PD_PHP is powered off in deep suspend and the SMMU resumes from reset
in bypass, so this needs arm-smmu-v3 system sleep support [1].

Link: https://lore.kernel.org/r/20260929034510.2023173-1-praan@google.com [1]
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index cb0a39f63788..0c3d59a39182 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -574,7 +574,6 @@ mmu600_php: iommu@fcb00000 {
 		clocks = <&cru ACLK_MMU_PHP>;
 		resets = <&cru SRST_A_MMU_PHP>;
 		#iommu-cells = <1>;
-		status = "disabled";
 	};
 
 	pmu1grf: syscon@fd58a000 {

-- 
2.55.0

