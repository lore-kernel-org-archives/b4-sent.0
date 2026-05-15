From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 15 May 2026 17:40:35 -0400
Subject: [PATCH 4/6] ARM: dts: imx6qdl-tx6: remove undocumented
 karo,imx6qdl-tx6-sgtl5000 and keep only simple-audio-card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-imx25_dts_simple_warning_2-v1-4-b06bff192a05@nxp.com>
References: <20260515-imx25_dts_simple_warning_2-v1-0-b06bff192a05@nxp.com>
In-Reply-To: <20260515-imx25_dts_simple_warning_2-v1-0-b06bff192a05@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778881235; l=1447;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=VqQTiqkhk2bfCYwJMM5wAbMlco3U6+HIbHdkhOxXS8s=;
 b=wOo+Lc+o1+htwVd6+ls5OBNoG3brE6l7hGEvVgNuJ5QVZokIlC4m0jCGB11ULL2G9Y041b34K
 3Gc/YWL8rQDDn2LCwrDgtDKS5jKZVbdjgWVkqt+IbOPQU5R1aLUJTOQ
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the undocumented and unused compatible karo,imx6qdl-tx6-sgtl5000 and
retain only the generic simple-audio-card sound configuration.

The karo,imx6qdl-tx6-sgtl5000 compatible is not documented and is not
referenced by any in-kernel driver. The audio setup is already fully
described using simple-audio-card, which is the standard and supported
binding for this hardware configuration.

No known users (such as uboot) rely on karo,imx6qdl-tx6-sgtl5000.

Fix below CHECK_DTBS warnings:
arch/arm/boot/dts/nxp/imx/imx6dl-tx6dl-comtft.dtb: /sound: failed to match any schema with compatible: ['karo,imx6qdl-tx6-sgtl5000', 'simple-audio-card']

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi b/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi
index 57297d6521cf09f1fd629ae375c9994ebb683375..ec1528ff3ea0146157a56f2ecba500e651f857ff 100644
--- a/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi
+++ b/arch/arm/boot/dts/nxp/imx/imx6qdl-tx6.dtsi
@@ -148,8 +148,7 @@ reg_usbotg_vbus: regulator-usbotg-vbus {
 	};
 
 	sound {
-		compatible = "karo,imx6qdl-tx6-sgtl5000",
-			     "simple-audio-card";
+		compatible = "simple-audio-card";
 		simple-audio-card,name = "imx6qdl-tx6-sgtl5000-audio";
 		pinctrl-names = "default";
 		pinctrl-0 = <&pinctrl_audmux>;

-- 
2.43.0

