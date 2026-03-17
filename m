From: David Heidelberg <david@ixit.cz>
Date: Tue, 17 Mar 2026 23:12:31 +0100
Subject: [PATCH v2 1/5] arm64: dts: qcom: sdm845-xiaomi-beryllium:
 Introduce framebuffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-beryllium-fb-v2-1-36b69dfb760c@ixit.cz>
References: <20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz>
In-Reply-To: <20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1046; i=david@ixit.cz;
 h=from:subject:message-id; bh=aBIkL87wWUcWlDR+ZE8iL72LYcdYRCKY1o3iHR+l8wY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpudHQlvN1ADBZ3DT2mCEvHMpnoid8nzZid/Q86
 7f5RN5azeOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabnR0AAKCRBgAj/E00kg
 coTrEACfP2nwQrJ8aAFTHbRP0sIm0Ptb4P0AoN/M2q1jMe+OO7b9e4+yWmTxikPHzAUzK89tGRf
 2WLJZgoUYX2RlNf46OA6DVhvsbVF9bYnc/hYcFaTbSwCiuXLeCLlOcqks16tmBr6mzGvwZb/Xt1
 mM67QDFtEjk1Fck74RCquk5/gUju9N50D3YiwfmYRlEKkzPd6yrl61n5H1q/jM/YGEjkV9dP1T3
 efVQnFo7q1B4CS/vbIrba0DsbuytQO1iVlDe1bft1DQtHu2n3S2H85n/DJfdHLxkBEbMSiAALPE
 iCT8XKcr0KFmbGN6sY1Xj7JEMO4u8pMemwBuLH9z0Hj4LcPpJpv5vlPamQ46l77RqO0i06xjIo5
 MpDDISb4pPvewwetOgf9UUFwe7gDXaaNbyTKB7Ozcmhjvcwh2I7msR78Isa460lHUZKbmwLHZaJ
 aLc654E0mj6ITPwOMjOh4PQfyc5EPpjVDARutT0c9lXufSeqncXjzi9gjeRAX+gM0V5KK3a10+J
 WVPxGClgtz3ech3KMYACwba6NUEC3SkgPEnyT5QTM1CCYUh4hOhsCzBzahYXVIHusx2jr802PCS
 joT1UAYN0ItwahCRg0KSn5S690e6avReEJI3aBDmAYmbvYyz5Gn0zASero0Whqaj49bu8/VpEgI
 17du+yzG6ppBVcQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Add framebuffer for early console and u-boot support.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi    | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 01b570d0880d6..b928100f6464b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -39,6 +39,22 @@ aliases {
 		serial1 = &uart6;
 	};
 
+	chosen {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		framebuffer: framebuffer-0 {
+			compatible = "simple-framebuffer";
+			memory-region = <&cont_splash_mem>;
+
+			format = "a8r8g8b8";
+			stride = <(1080 * 4)>;
+			height = <2246>;
+			width = <1080>;
+		};
+	};
+
 	gpio-keys {
 		compatible = "gpio-keys";
 		autorepeat;

-- 
2.53.0

