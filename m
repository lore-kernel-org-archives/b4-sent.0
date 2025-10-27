From: Zhentao Guo <zhentao.guo@amlogic.com>
Date: Mon, 27 Oct 2025 13:42:38 +0800
Subject: [PATCH 2/3] dts: decoder: Support V4L2 stateless decoder dt node
 for S4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-b4-s4-vdec-upstream-v1-2-620401813b5d@amlogic.com>
References: <20251027-b4-s4-vdec-upstream-v1-0-620401813b5d@amlogic.com>
In-Reply-To: <20251027-b4-s4-vdec-upstream-v1-0-620401813b5d@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Zhentao Guo <zhentao.guo@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761543762; l=1381;
 i=zhentao.guo@amlogic.com; s=20251024; h=from:subject:message-id;
 bh=LcY8cMBMKErZcyqsCWF2LS5nXjw5kG0pKkyeU/UPzbo=;
 b=Mr7z0YtZ2hQe/xIjZV57FO+a0pPguCGABpUUZmWIzYTlQHlNNnTTjWDxX3NM5t959kyXml7Zj
 HUjLajdPhxRD5iOtdXalisob0ScsnctG2q660clLZY8xN6O2Cy/XbKq
X-Developer-Key: i=zhentao.guo@amlogic.com; a=ed25519;
 pk=5yfDKrjreXwcAoEUsdtWafy6YN500upXp/CgtnXjLVU=
X-Endpoint-Received: by B4 Relay for zhentao.guo@amlogic.com/20251024 with auth_id=555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add vcodec_dec to the s4 dtsi for the V4L2 stateless decoder driver

Signed-off-by: Zhentao Guo <zhentao.guo@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
index 9d99ed2994df..028566f7423d 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
@@ -853,5 +853,29 @@ emmc: mmc@fe08c000 {
 			no-sd;
 			status = "disabled";
 		};
+
+		video-codec@fe320000 {
+			compatible = "amlogic,s4-vcodec-dec";
+			reg = <0x0 0xfe320000 0x0 0x10000>,
+			      <0x0 0xfe036000 0x0 0x2000>;
+			reg-names = "dosbus",
+				    "dmcbus";
+			interrupts = <GIC_SPI 91 IRQ_TYPE_EDGE_RISING>,
+				     <GIC_SPI 92 IRQ_TYPE_EDGE_RISING>,
+				     <GIC_SPI 93 IRQ_TYPE_EDGE_RISING>;
+			interrupt-names = "mailbox_0",
+					  "mailbox_1",
+					  "mailbox_2";
+			clocks = <&clkc_periphs CLKID_DOS>,
+				 <&clkc_periphs CLKID_VDEC_SEL>,
+				 <&clkc_periphs CLKID_HEVCF_SEL>;
+			clock-names = "vdec",
+				      "clk_vdec_mux",
+				      "clk_hevcf_mux";
+			power-domains = <&pwrc PWRC_S4_DOS_VDEC_ID>,
+					<&pwrc PWRC_S4_DOS_HEVC_ID>;
+			power-domain-names = "pwrc-vdec",
+					     "pwrc-hevc";
+		};
 	};
 };

-- 
2.42.0

