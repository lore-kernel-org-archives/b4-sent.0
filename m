From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Thu, 19 Nov 2026 09:57:48 -0800
Subject: [PATCH 6/6] ARM: dts: renesas: r9a06g032: Add resets to mii
 converter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rzn1-miic-resets-v1-6-feee2bb28bb4@reliablecontrols.com>
References: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
In-Reply-To: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795111097; l=858;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=qgvA5VciuFpDDlBloW4+43M1wkddJY2irZpJYObbd+0=;
 b=OhrIO0OOq4envOlQ9SlkMKgZ8zwywCqI1Hl35UHS4W/dakNbGHiHRR1SxMVHYQLVh/LFjgBDm
 5VR8kkDEHxuDewOhaKUuZGCrfzaMxujoY0XpSH2F3UcUugaAkVPUUrP
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add references to the resets in the system driver that the miic needs

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 arch/arm/boot/dts/renesas/r9a06g032.dtsi | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm/boot/dts/renesas/r9a06g032.dtsi b/arch/arm/boot/dts/renesas/r9a06g032.dtsi
index f2bf087f7ad2..0a538d922125 100644
--- a/arch/arm/boot/dts/renesas/r9a06g032.dtsi
+++ b/arch/arm/boot/dts/renesas/r9a06g032.dtsi
@@ -463,6 +463,9 @@ eth_miic: eth-miic@44030000 {
 				 <&sysctrl R9A06G032_CLK_RMII_REF>,
 				 <&sysctrl R9A06G032_HCLK_SWITCH_RG>;
 			clock-names = "mii_ref", "rgmii_ref", "rmii_ref", "hclk";
+			resets = <&sysctrl R9A06G032_RST_TS>,
+				 <&sysctrl R9A06G032_RST_MIIC>;
+			reset-names = "rst_ts", "rst_miic";
 			power-domains = <&sysctrl>;
 			status = "disabled";
 

-- 
2.53.0

