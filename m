From: David Heidelberg <david@ixit.cz>
Date: Sat, 01 Aug 2026 02:35:22 +0200
Subject: [PATCH 3/4] arm64: dts: rockchip: rk3566-pinetab2: DW9714 coil
 requires higher voltage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260801-pp-pro-camera-v1-3-7b4d90788f9f@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1171; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZHRJuCpp9diTbSoK/fprSuePRcEV0i0y0Y263b51eL0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbT9RrWeOzQofKRUF0yXALcXjL6uK++hWoGvII
 zYHZFYlEOSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0/UQAKCRBgAj/E00kg
 cidMD/4olIUWt4Eo80Icz+MSRhbI2hBudu+Q6K2z5p1g4t02GHyJffBgWUluc3uMD3vkezQH/pj
 64jT96zE0/Rfo0Hju0ey0K1tl2qEHw2+JbmJwWhZUu4XLrAdVUG1TjwY4SvxS/05GHdfEkHzzqX
 vg/fjM328bqC51TAB8PxoTB1VjFd/VzVfSI8KYKmZCAY6KNhtb2VlB3DfmdmEoNjI2qJlqVQ94+
 sEkbty+eERY4OW207ZjWDhmiOp9aZycdZyGJaByTjd6JwRx0Focb6b6txJ6NhE1HUplkyVoRb7a
 j8pvTpfBuKEp/dXYnsNKW/KYz+QqOF8OlxB5vylpcmAfHjpCJT4CFNqrdkXBnAnAwJCJezsRGYL
 2VAZyFxn6AzoDc8h4ow4MgrkxXxjPOKs7it6rth0wdDiREcTWfQQAPsRhI0hTkw2q36Xytxsk7r
 C1xI61i3r/VsYwdn6cr1TfEm6kbJlg+nAgJk/GNXT3MhpyE7dwsnPJkeWVt+eSUlxqZ4CiHouSC
 j7T7ahrM/65s2MFuEp0HJBFishxK8gurEpEajNSVcv02+Sxho+qdtzzDmjT1lgPw7d/Z3HMYNN4
 yil+aJf3vLU8Z3OllCwX7JwALEDajOvEtZGxYhu5I3JolK6uhRKF6urLZHaSX6wKOGbPq+O7+ow
 9sT3/on8FxojQaA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By datasheet the VDD (in-kernel named vcc) range is between 2.3 to 4.3 V.
Usually it's around 2.8 V. Here it matches the vcc2v8_dvp.

1.8 V here is likely used for i2c level shifter.

Fixes: 1b7e19448f8f ("arm64: dts: rockchip: Add devicetree for Pine64 PineTab2")
Cc: stable@vger.kernel.org
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/rockchip/rk3566-pinetab2.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3566-pinetab2.dtsi b/arch/arm64/boot/dts/rockchip/rk3566-pinetab2.dtsi
index 08bf40de17ead..96511f1bb51d6 100644
--- a/arch/arm64/boot/dts/rockchip/rk3566-pinetab2.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3566-pinetab2.dtsi
@@ -581,17 +581,17 @@ touchscreen@5d {
 &i2c2 {
 	clock-frequency = <400000>;
 	pinctrl-0 = <&i2c2m1_xfer>;
 	status = "okay";
 
 	vcm@c {
 		compatible = "dongwoon,dw9714";
 		reg = <0x0c>;
-		vcc-supply = <&vcc1v8_dvp>;
+		vcc-supply = <&vcc2v8_dvp>;
 	};
 
 	camera@36 {
 		compatible = "ovti,ov5648";
 		reg = <0x36>;
 		pinctrl-names = "default";
 		pinctrl-0 = <&camerab_pdn_l &camerab_rst_l>;
 

-- 
2.53.0

