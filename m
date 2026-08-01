From: David Heidelberg <david@ixit.cz>
Date: Sat, 01 Aug 2026 02:35:21 +0200
Subject: [PATCH 2/4] arm64: dts: rockchip: rk3399-pinephone-pro: DW9714
 coil requires higher voltage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260801-pp-pro-camera-v1-2-7b4d90788f9f@ixit.cz>
References: <20260801-pp-pro-camera-v1-0-7b4d90788f9f@ixit.cz>
In-Reply-To: <20260801-pp-pro-camera-v1-0-7b4d90788f9f@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ondrej Jirman <megi@xff.cz>, 
 Olivier Benjamin <olivier.benjamin@bootlin.com>, 
 Manuel Traut <manut@mecka.net>, 
 Alexander Warnecke <awarnecke002@hotmail.com>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Martin Kepplinger <martin.kepplinger@puri.sm>, 
 Shawn Guo <shawnguo@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 phone-devel@vger.kernel.org, imx@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1252; i=david@ixit.cz;
 h=from:subject:message-id; bh=CtmW0a2W86bMEcZ0dtSszyADwP8LgbVPYzdrAT7lUhE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbT9REkGT6wYkrnw7vVFzBUUDFM/Z1kzdvuRLM
 Svh7a0sPZ2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0/UQAKCRBgAj/E00kg
 cij8D/9+k7eLtMvAoLHwLgwTcoON+ku4R3r/iZgjbChEXxwwoyY50stWKatXXAP8hQLuLiX/lYh
 YpcbJe1OHhF20GPHkuHDl/ro/Z+/l3/Gr0/25KnGGubWHyiCIyv6YAYx0TkkG71LdPUfzRYNo+r
 mPnyPaw2xjxvwTt+uAp68JurQ0zHeXB+8XeC2boI5uamRdrpBdV0qw3xN8YN7py/kpjh4t4q67E
 M+vkL8Qf8a7W7xT0drcE5qjtPcXQaeSzhw1MwSuxvmy/4t+ZcLiwQsxGwMJiHFmGU7Rt9tmtfGM
 8/OpXLXqE7IMyY0FBMCpbBj0ZASTDfburmVhABNc6Xi4rdVIoNAGttEbEUsF9usaVgQJ4Axazfo
 vzAGopGLCCxwD4wN45a/KLvJAsYg3SdAogiyCTVMJFxc1yKD8bjD9/ihDdCTRgncr/BdB8obpIj
 tigr6xti3ytptoQHrPhQ+nJcdKcL8t8chOvER/cz1717ggmmKHtEVm2ikwA4BQvKxfo1wlphAhc
 SBEDW+L+tqUK1j5dV0xO9uzG+HB+AXAJr9yIOh1H2ibnVB1+OEeZpF/yIiFEW3/p6oQESyxTfhk
 NEu3IE4dfgSg5P4rqERNdiTH2SPPJ2sEI5YJSQRHPkvzP8TbUkCostDgjkE31+AkUY7IIQNn/Lj
 +uteGSYwVzO3MJg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By datasheet the VDD (in-kernel named vcc) range is between 2.3 to 4.3 V.
Usually it's around 2.8 V. Here it matches the avdd2v8_dvp.

Fixes: 9336eb829a18 ("arm64: dts: rockchip: describe I2c Bus 1 and IMX258 world camera on PinePhone Pro")
Cc: stable@vger.kernel.org
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
index d46cdfe3f7849..bde35d9b2263e 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
@@ -473,17 +473,17 @@ wcam_out: endpoint {
 			};
 		};
 	};
 
 	wcam_lens: camera-lens@c {
 		compatible = "dongwoon,dw9714";
 		reg = <0x0c>;
 		/* Same I2c bus as both cameras, depends on vcca1v8_codec for power. */
-		vcc-supply = <&vcc1v8_dvp>;
+		vcc-supply = <&avdd2v8_dvp>;
 	};
 
 	ucam: camera@36 {
 		compatible = "ovti,ov8858";
 		reg = <0x36>;
 		clocks = <&cru SCLK_CIF_OUT>; /* MIPI_MCLK1, derived from CIF_CLK0 */
 		clock-names = "xvclk";
 		dovdd-supply = <&vcc1v8_dvp>;

-- 
2.53.0

