From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Thu, 26 Nov 2026 08:11:07 -0800
Subject: [PATCH v4 3/3] ARM: dts: renesas: r9a06g032: Add #reset-cells to
 system controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-rzn1-miic-resets-v4-3-4f73af81d779@reliablecontrols.com>
References: <20261126-rzn1-miic-resets-v4-0-4f73af81d779@reliablecontrols.com>
In-Reply-To: <20261126-rzn1-miic-resets-v4-0-4f73af81d779@reliablecontrols.com>
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Wolfram Sang <wsa+renesas@sang-engineering.com>, 
 Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795709473; l=804;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=WWyo4QGHfN4nIjzzAN5Okr3IhbwMhhhW3P0Osmvu8I4=;
 b=1XkYumVv41gu/rXPKVLmjuniWX+x9G/DjTFLjPBGDrQXdnP9iZG0juGPy79WISILKfVd+C/Cv
 5EnR/l0ELsNBLpGMhwpq2Pzm/21dXBNGtNrqfTwmB/MjsqmKj8JAtM+
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the rzn1 system controller node with cells for the reset controller

Reviewed-by: Wolfram Sang <wsa+renesas@sang-engineering.com>
Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 arch/arm/boot/dts/renesas/r9a06g032.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/renesas/r9a06g032.dtsi b/arch/arm/boot/dts/renesas/r9a06g032.dtsi
index 5455dccfbdd0..f2bf087f7ad2 100644
--- a/arch/arm/boot/dts/renesas/r9a06g032.dtsi
+++ b/arch/arm/boot/dts/renesas/r9a06g032.dtsi
@@ -146,6 +146,7 @@ sysctrl: system-controller@4000c000 {
 			compatible = "renesas,r9a06g032-sysctrl";
 			reg = <0x4000c000 0x1000>;
 			#clock-cells = <1>;
+			#reset-cells = <1>;
 			#power-domain-cells = <0>;
 
 			clocks = <&ext_mclk>, <&ext_rtc_clk>,

-- 
2.53.0

