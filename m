From: David Heidelberg <david@ixit.cz>
Date: Sat, 01 Aug 2026 02:35:23 +0200
Subject: [PATCH 4/4] arm64: dts: imx8mq-librem5: Dongwoon DW9714 coil
 requires higher voltage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260801-pp-pro-camera-v1-4-7b4d90788f9f@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1318; i=david@ixit.cz;
 h=from:subject:message-id; bh=ESuNmKUilcBmwkhuW9k8KZuVDiNGOXfVNdzvY5NO83c=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbT9SUDUWs1RjnpAKhNFn6KNoQcgRVwd2qcbcu
 CY9ZsnEs/SJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0/UgAKCRBgAj/E00kg
 crR1EAC31s20oGV+f/ztpNaROw1wIlei9thofJ3Isn/pL2saX+KwwalKn7SezGY9tzifXXjBFPA
 mEito6c2HHrmp45mKDMRJWT8NO9E+IKnu7gO5kXj6fg/AmP2onSNeFRZtInpNDvQCRTs2u1EfK7
 fKlNCy0dAcaPOc021zYB71n5WKK+mtc8ge9ttymu6pEtLGno2lSTfUgrwCcowWCX/UZqfLZWs2Q
 5ljMvkeVrJ3Nx4m8oR5qBo1JETFHfz1hMVmqA9a5BX0hs15rbhjTVrE0BBWfwf5UBx0O7pQ3Zor
 qyRNfrnIhOP2j2wYhscXxtEwhYC8YgJTR9QlAlEcOJT+khdamQz9JPpLGtdt8F9KBD4wbYbfro1
 ePLcDfRQG236Cju7wENdMZkzsIN9ObKSiBhfn7M3Y2wu9qczYsd2oU5ywl94N1CyjQAHZ4B3Mr3
 ZRp+rROZTKLr2bapQFeXPD/7fZzvr0U8Ss2KHDdv6PM0b38TrjgDy2bQTBhx9DxwS9KoERi8anX
 ZrFUORtSQPUNWRd04z/3wu3KwePhUOl2Ea77nTZuY/hp2a1Sxf76VOLbrfU2eluzVaEhihZop9z
 fbR2dPlUKAh80T0EvdWyuhCSIe9idmAkhCrq0TSz4PS6TfAucHZizmIpoamUCnBCoVbzBIsAxgt
 mSYT1tlax9RnfdQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By datasheet the VDD (in-kernel named vcc) range is between 2.3 to 4.3 V.
Usually it's around 2.8 V. Here it matches the reg_vcam_2v8.

1.8 V here is likely used for i2c level shifter.

Fixes: f00df2bdb512 ("arm64: dts: imx8mq-librem5: describe the voice coil motor for focus control")
Cc: stable@vger.kernel.org
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
index f5d529c5baf3e..583cba2d3bebf 100644
--- a/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi
@@ -1167,17 +1167,17 @@ &i2c4 {
 	pinctrl-1 = <&pinctrl_i2c4_gpio>;
 	scl-gpios = <&gpio5 20 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
 	sda-gpios = <&gpio5 21 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
 	status = "okay";
 
 	vcm@c {
 		compatible = "dongwoon,dw9714";
 		reg = <0x0c>;
-		vcc-supply = <&reg_csi_1v8>;
+		vcc-supply = <&reg_vcam_2v8>;
 	};
 
 	bat: fuel-gauge@36 {
 		compatible = "maxim,max17055";
 		reg = <0x36>;
 		interrupt-parent = <&gpio3>;
 		interrupts = <20 IRQ_TYPE_LEVEL_LOW>;
 		pinctrl-names = "default";

-- 
2.53.0

