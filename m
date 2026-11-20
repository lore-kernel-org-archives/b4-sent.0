From: Ivan Pfarher <ipfarher@gmail.com>
Date: Fri, 20 Nov 2026 12:40:48 +0100
Subject: [PATCH 4/4] arm64: dts: allwinner: h5: orangepi-zero-plus2: Add
 MMC aliases
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-orangepi-zero-plus2-fixes-v1-4-ecd792189f27@gmail.com>
References: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
In-Reply-To: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, Ivan Pfarher <ipfarher@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174845; l=1496;
 i=ipfarher@gmail.com; s=20261120; h=from:subject:message-id;
 bh=9aWwwAzsx9U2iQUbLdf6klaNBeIN6Kxth853YqVu9o0=;
 b=8oBh1A0f4Jl18/rO4qnX4tVCjQH3AZVUPMYNPiUjNYReBhlAIRtNGVpHJ47ipRRd4WcRtZa/D
 j/DnSy61jIoBYnN+mht9zy/OcJhtwYXLYuVLWog2LE+kyyHdAotZk8L
X-Developer-Key: i=ipfarher@gmail.com; a=ed25519;
 pk=3DMYyz/xl+KRAx2TNGJpheG+5QUm7lqHhKXFqVu2TmY=
X-Endpoint-Received: by B4 Relay for ipfarher@gmail.com/20261120 with auth_id=1582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sunxi-mmc probes asynchronously, so without aliases the microSD card,
the SDIO WiFi and the eMMC get their mmc numbers in probe order. A boot
script using root=/dev/mmcblk0p2 for the microSD card can then end up
on the eMMC instead.

Add aliases so that the microSD card is always mmc0 and the eMMC mmc1,
matching the numbering U-Boot uses on this board, with the SDIO WiFi
as mmc2.

Tested on an Orange Pi Zero Plus2 (H5) running Linux 6.6.160 with this
change applied: the microSD card is mmcblk0 and the eMMC mmcblk1,
booting from either. Build-tested only against current mainline.

This problem was investigated, and the patch drafted, in an interactive
session with an AI coding assistant (Claude by Anthropic). The submitter
reviewed the change and ran the tests described above.

Signed-off-by: Ivan Pfarher <ipfarher@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
index 892723b46..4a26863e8 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
@@ -13,6 +13,9 @@
 	compatible = "xunlong,orangepi-zero-plus2", "allwinner,sun50i-h5";
 
 	aliases {
+		mmc0 = &mmc0;
+		mmc1 = &mmc2;
+		mmc2 = &mmc1;
 		serial0 = &uart0;
 	};
 

-- 
2.43.0

