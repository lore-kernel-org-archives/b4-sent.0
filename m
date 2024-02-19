From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Feb 2024 05:27:59 +0800
Subject: [PATCH RFC v3 2/5] arm64: dts: hi3798cv200: add
 hisilicon,inno-usb2-phy to compatible list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-inno-phy-v3-2-893cdf8633b4@outlook.com>
References: <20240220-inno-phy-v3-0-893cdf8633b4@outlook.com>
In-Reply-To: <20240220-inno-phy-v3-0-893cdf8633b4@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, 
 Shawn Guo <shawn.guo@linaro.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kishon Vijay Abraham I <kishon@ti.com>, 
 David Yang <mmyangfl@gmail.com>, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708378078; l=1213;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=9vJGt8Ea6nDd4110Luo3uNaofm3Nie+YLh4/3aqzgKY=;
 b=G6dwipOzO7tIAyQn4WvhzD9c9rqV9ps0/6dGeA76lSMJBMrT0dJH/JkirMdy8SIQDVSc+ggtB
 y70Sgiw1jlyAAwqIqcwJKTAco24oWGn7DDyAwaasUOTGA/spqPteT2+
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is required due to recent binding changes.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
index ed1b5a7a6067..268d57eabce7 100644
--- a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
+++ b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
@@ -114,7 +114,8 @@ perictrl: peripheral-controller@8a20000 {
 			ranges = <0x0 0x8a20000 0x1000>;
 
 			usb2_phy1: usb2_phy@120 {
-				compatible = "hisilicon,hi3798cv200-usb2-phy";
+				compatible = "hisilicon,hi3798cv200-usb2-phy",
+					     "hisilicon,inno-usb2-phy";
 				reg = <0x120 0x4>;
 				clocks = <&crg HISTB_USB2_PHY1_REF_CLK>;
 				resets = <&crg 0xbc 4>;
@@ -135,7 +136,8 @@ usb2_phy1_port1: phy@1 {
 			};
 
 			usb2_phy2: usb2_phy@124 {
-				compatible = "hisilicon,hi3798cv200-usb2-phy";
+				compatible = "hisilicon,hi3798cv200-usb2-phy",
+					     "hisilicon,inno-usb2-phy";
 				reg = <0x124 0x4>;
 				clocks = <&crg HISTB_USB2_PHY2_REF_CLK>;
 				resets = <&crg 0xbc 6>;

-- 
2.43.0

