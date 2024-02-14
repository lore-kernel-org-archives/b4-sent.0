From: Zachary Goldstein <zachary.goldstein@concurrent-rt.com>
Date: Wed, 14 Feb 2024 17:21:54 -0500
Subject: [PATCH] arm64: ls1046ardb: Replace XGMII with 10GBASE-R phy mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240214-ls1046-dts-use-10gbase-r-v1-1-8c2d68547393@concurrent-rt.com>
X-B4-Tracking: v=1; b=H4sIAAE9zWUC/x2MQQqDMBAAvyJ77sJuiIH0K+IhrZt0oVjJWhHEv
 xs8DXOYOcCkqhg8uwOqbGr6m5vwo4P3J81FUKfm4Mh5cuzxa0w+4LQa/k2QqbxSY0USipFzCn2
 O0PKlStb9Xg/jeV6yi7OvagAAAA==
To: Shawn Guo <shawnguo@kernel.org>, Madalin Bucur <madalin.bucur@nxp.com>, 
 Li Yang <leoyang.li@nxp.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Zachary Goldstein <zachary.goldstein@concurrent-rt.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707949330; l=1035;
 i=zachary.goldstein@concurrent-rt.com; s=20230809; h=from:subject:message-id;
 bh=BGRIPx+hnBEVvcJ92A45ST1Vx+ijHTH7otOABNKiaNE=;
 b=cnJjLYsULO9fgq8vCh9rD+0wuwb3Lt2hZFgIo9bcbpGw2f8YVDH07WSZL9LCktQlciB1AD9P7
 cU7g9eKBOCODnYsM5p+LfRiwjSZ2jE5iP2/N7RZAjkgqZx0LJiboJjh
X-Developer-Key: i=zachary.goldstein@concurrent-rt.com; a=ed25519;
 pk=GLF18lQ96tRolyWMpDtJzDQ9bi7+1+rMHript5TFdSg=
X-Endpoint-Received: by B4 Relay for zachary.goldstein@concurrent-rt.com/20230809 with auth_id=74
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AQR107 family does not support XGMII, but USXGMII and
10GBASE-R instead. Since ce64c1f77a9d ("net: phy: aquantia: add USXGMII
support and warn if XGMII mode is set") the kernel warns about XGMII
being used. The LS1046A SoC does not support USXGMII, so use 10GBASE-R
instead.

Signed-off-by: Zachary Goldstein <zachary.goldstein@concurrent-rt.com>
---
 arch/arm64/boot/dts/freescale/fsl-ls1046a-rdb.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/freescale/fsl-ls1046a-rdb.dts b/arch/arm64/boot/dts/freescale/fsl-ls1046a-rdb.dts
index 07f6cc6e354a..d2066f733dc5 100644
--- a/arch/arm64/boot/dts/freescale/fsl-ls1046a-rdb.dts
+++ b/arch/arm64/boot/dts/freescale/fsl-ls1046a-rdb.dts
@@ -149,7 +149,7 @@ ethernet@ea000 {
 
 	ethernet@f0000 { /* 10GEC1 */
 		phy-handle = <&aqr106_phy>;
-		phy-connection-type = "xgmii";
+		phy-connection-type = "10gbase-r";
 	};
 
 	ethernet@f2000 { /* 10GEC2 */

---
2.40.1
base-commit: 841c35169323cd833294798e58b9bf63fa4fa1de

