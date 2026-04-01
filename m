From: David Heidelberg <david@ixit.cz>
Date: Thu, 02 Apr 2026 00:39:35 +0200
Subject: [PATCH v4 1/4] arm64: dts: qcom: sdm845-xiaomi-beryllium:
 Introduce framebuffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-beryllium-fb-v4-1-46170004da28@ixit.cz>
References: <20260402-beryllium-fb-v4-0-46170004da28@ixit.cz>
In-Reply-To: <20260402-beryllium-fb-v4-0-46170004da28@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, Dzmitry Sankouski <dsankouski@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1031; i=david@ixit.cz;
 h=from:subject:message-id; bh=SnKFfm4qN/M+jaL16XHBrfpNpLQrOoZvc5aNlTISLv4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzZ6pIQWxrYrx/NFNb6Ln1S8wIwupaP7AXCxrN
 imqOq1XikCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2eqQAKCRBgAj/E00kg
 cr7RD/4qyNhIDXzRJORhXEp9rhsDhjnSGS88/9xAYH/3SLvFwqFIJJpF6Pd2dJfdYkG6UKQdtmd
 iBct7yMSbcOAMYUazlMz7OphojQGU3bdn3JtO1ILgmRYLbYSqVyorr1FgfZ4oyFgy69lfDbkfcQ
 1BsfZ07m+i3UBjeyzCKd30V3ys7fsXbDsXWvACSMCa1VeZP2newDGm0mITUB1mHm/srr9lAlPSl
 BKl+zKgANgEp31V0tC7JUAfr3CeC9sdhMOc3/DX7p2bffElqGwIPUduAz4wSU2zGsUwwnLJYhad
 CygeZueZTo9PonudTbZUil9rgn7FYRjUdNRDu1qPAse+rHLQcK2Sm28f8DsZrGII5mJRR3OiBKS
 RH9hM9tQCFC2Z5tvJV+WR05MQx57noemZlWwjxZY7KIhy9tZlMhXuUcTH9dLgA0MKY29uR47/XQ
 BsTI1+lBa8398HhUeC+d3eBH+E0tSZa7HeA5rxqjJHF9QbNwZM1+KZC5pdp5pIHBKpLREymCmTV
 3NGoz2apyj3pTFN1rRqju3nVoE2gb4ARPcdj32Zum6C+uOLz6qEt8bsMQSdVPXzEJLaL/MJ4SNh
 xCdwc9/mr6b3w79LvLvM4nCdzFQzUyLfZd9fnXRGGeiqe1gND1e879OkBq0IjpTxKDOV/zOY9KY
 Yn6rRGOuMDQgzUw==
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
index 1298485c42142..a6ee3dd171def 100644
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
+		framebuffer {
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

