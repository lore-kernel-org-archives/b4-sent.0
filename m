From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Sep 2026 22:59:12 +0200
Subject: [PATCH 1/3] arm64: dts: qcom: sdm845-google: Set i2c3 frequency to
 400 kHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-sdm670-sargo-nfc-v1-1-bed1cbbffc46@ixit.cz>
References: <20260902-sdm670-sargo-nfc-v1-0-bed1cbbffc46@ixit.cz>
In-Reply-To: <20260902-sdm670-sargo-nfc-v1-0-bed1cbbffc46@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Richard Acayan <mailingradian@gmail.com>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=994; i=david@ixit.cz;
 h=from:subject:message-id; bh=T/CRKHYH4PIgdGiSr8q4F541f/u8HxxrZ0dMSKkBtEE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmI4l+pCJ3gAVi1n8xvqjRvyWxHpn+m0A5goCe
 gohhxLxPT+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapiOJQAKCRBgAj/E00kg
 crogEACOYjOXFkXvRhVblWYmN1Qp5NNVlbfikzjXOt1Zxa/KYTRFPlouVMDHBxRSDP0ySBBbvbj
 SJneiCh9dIzQ8thojQKGxgWhnFrs9xaWNWQYJpWp9pilDU5vFb0ptCnpw1tm6NEwroOzRYvsgdn
 a2fTvW986kqbHOtldB+Jn0XT+7pcn+g1wK0Mr2HgSMVjD0KSZw6/yrkAVtH8aC32T7X8K+sFjzz
 7PFHzDJ7PCzdHYAK+17qaIUNbX09J7aAh7LDnCid7uYL5raycbd5k6Fb8acYXrFW93rOYlqSaPB
 IbOSkn9AnSUCslfAW6jBDdszYDidQj+AxWFOzctXJfVRnnDXWhocCk7nOLJWoQhgWrncMlP424p
 P1rneMsrVaqb+oBY+Cj1AbsSvDVxEQkcu6Bt47ZJJkz/rarAgVEexU4BMPPDulFOM8IsF4gffiq
 RnlPYbgSAmo5EFjdjl+QMCwI7CuWs+Wp6tZHc0C+tC5mCj9epeZ2Yp43yac10gbhMcwdb5VUzzT
 T7+RnYIxe3BSq2rleumRUeld80bJIoy/VEnI0JJJtyYfuxRIsU4B0GfZDiGMCMv6S4+B04lhVF4
 K5m3Aj8mCbicU+ygIVPMHbQzWgK+IuvFvKJ0j1lAFq8+vlGxeQX0PPcaux2ITgboaV4Jj5oraE5
 S8A3249GzIx5XPg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When downstream value is undefined, it fallback to 400 kHz. Set it in
mainline too.

Cc: stable@vger.kernel.org
Fixes: 10f91b0dfaf6 ("arm64: dts: qcom: sdm845-google-common: Enable NFC")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 9e952f9862f24..f73d4ea57705f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -387,16 +387,18 @@ &gpu {
 	status = "okay";
 };
 
 &gpu_zap_shader {
 	firmware-name = "qcom/sdm845/Google/blueline/a630_zap.mbn";
 };
 
 &i2c3 {
+	clock-frequency = <400000>;
+
 	status = "okay";
 
 	nfc@28 {
 		compatible = "nxp,pn557", "nxp,nxp-nci-i2c";
 		reg = <0x28>;
 
 		interrupts-extended = <&tlmm 63 IRQ_TYPE_EDGE_RISING>;
 

-- 
2.55.0

