From: Fabricio Akio <fabricioakio@gmail.com>
Date: Wed, 25 Nov 2026 23:20:35 -0300
Subject: [PATCH 2/2] arm64: dts: qcom: sdm630: Power the ADSP from the SSC
 CX rail
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-sdm660-adsp-proxy-rail-v1-2-b91784c69623@gmail.com>
References: <20261125-sdm660-adsp-proxy-rail-v1-0-b91784c69623@gmail.com>
In-Reply-To: <20261125-sdm660-adsp-proxy-rail-v1-0-b91784c69623@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <lumag@kernel.org>, Martin Botka <martin.botka1@gmail.com>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795659634; l=1000;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=vvfBXxukbqq5MzPAqDR7snLRrnKmtOIK0SM+DFfx3eA=;
 b=u3Y2Dg68BstIxRMFXbdZlmBYQ3q3sTD2+AUVxj2nF8Tsw+O8m0+wKMHZEWJEvLrnHQm0SIl4T
 D/zyfT2Z6msCcuxCSF2o6847kL75znTjoLpGQtnpppgGZAAcJ0ZcwZX
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADSP node names RPMPD_VDDCX as its power domain. The rail the ADSP
needs to boot is the RPM's "rwlc" resource, PM660L LDO9, which is
RPMPD_SSCCX: with it voted the DSP starts again after a stop, and with
VDDCX voted it does not.

Fixes: 7ca2ebc90a46 ("arm64: dts: qcom: sdm630: Add ADSP remoteproc configuration")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 arch/arm64/boot/dts/qcom/sdm630.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm630.dtsi b/arch/arm64/boot/dts/qcom/sdm630.dtsi
index 20225732e4a8..90990dc36b01 100644
--- a/arch/arm64/boot/dts/qcom/sdm630.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm630.dtsi
@@ -2414,7 +2414,7 @@ adsp_pil: remoteproc@15700000 {
 			clock-names = "xo";
 
 			memory-region = <&adsp_region>;
-			power-domains = <&rpmpd RPMPD_VDDCX>;
+			power-domains = <&rpmpd RPMPD_SSCCX>;
 			power-domain-names = "cx";
 
 			qcom,smem-states = <&adsp_smp2p_out 0>;

-- 
2.56.1

