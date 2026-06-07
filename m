From: David Heidelberg <david@ixit.cz>
Date: Sun, 07 Jun 2026 16:12:19 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: qcm6490-fairphone-fp5: Convert fb to
 use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260607-shift8-fb-v1-2-72b9dac25f4a@ixit.cz>
References: <20260607-shift8-fb-v1-0-72b9dac25f4a@ixit.cz>
In-Reply-To: <20260607-shift8-fb-v1-0-72b9dac25f4a@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1149; i=david@ixit.cz;
 h=from:subject:message-id; bh=KULJnC5wByyrnpV9Tcy4pepjm2js9OMamuzNs1jvFiw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqJXxHV05wOdRcHomRxte6SsEwkVlVexm3L1A3r
 K41sA2c14WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaiV8RwAKCRBgAj/E00kg
 ci1aD/9FAbrqqMFNKChm/jOstmzz0OHZbfhSVn68fHxoG0vfQW23HyiIMl2uT2gGhcmnznposgG
 zhH+dq3v5Ff1vWMxMAjPpDoUONsHn/+bYcq/vzx73DFPXVt3nTrB78DGu8sbu79VSniIzfh+2zh
 8aig2qI+KEzZ+ibNgEYNdIHaGaYwBnaMwkEVWnRjkfdJuK1ZOH/DIp8aHnBnEdFvTKudbXvahyf
 iX60Cq71rdVEinMTlCltmcEZwmv3NYtYJR78ZSTzOetHJ6Hy7+r0+EcOarUV4rUpnt24vad6xTz
 AkJ0+DqnYxsSJFf4ltfDSbeelHNjCnYg78GmFpnp+RNU8yIC6oxO2MkzMVRCAmymBaKyrpra1Rl
 PUW7WnMUQni+oQD/BcWj21SE7Rwa1KkoNxmKKIbm3fDI4wZykfKouWG35FgnxhWhPJv8vCORuet
 LsAHnFsJpiZDF+GB8o2AvPODYysoJ12Z6pwZRiMfcQQxHRy7y89nF+Hmmy1B/PMSLlJTGczpLa0
 zU5vUi61aTuphxyrXMuDOeREBYIhm2btiW2jHiEXqDB7HvWnoT+9r9KDkbhpit12HtvhLmI+wfO
 zuDmxXUmiyXZmeLHLmawyDXXmK1LzC1KYMeYsGiG8VorqUKrDle2UD+h86Qo0xynOcf5MYqHFdV
 urBtunVbbFjGECQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of manually specifying reg, reuse the memory region.

This fixed mismatch of the node naming (0xe1000000 X framebuffer@a000000)

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/qcm6490-fairphone-fp5.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/qcm6490-fairphone-fp5.dts b/arch/arm64/boot/dts/qcom/qcm6490-fairphone-fp5.dts
index 04cb9230d29fd..4ca0e93ed63ee 100644
--- a/arch/arm64/boot/dts/qcom/qcm6490-fairphone-fp5.dts
+++ b/arch/arm64/boot/dts/qcom/qcm6490-fairphone-fp5.dts
@@ -35,19 +35,19 @@ aliases {
 		serial1 = &uart7;
 	};
 
 	chosen {
 		#address-cells = <2>;
 		#size-cells = <2>;
 		ranges;
 
-		framebuffer0: framebuffer@a000000 {
+		framebuffer {
 			compatible = "simple-framebuffer";
-			reg = <0x0 0xe1000000 0x0 (2700 * 1224 * 4)>;
+			memory-region = <&cont_splash_mem>;
 			width = <1224>;
 			height = <2700>;
 			stride = <(1224 * 4)>;
 			format = "a8r8g8b8";
 			clocks = <&gcc GCC_DISP_HF_AXI_CLK>;
 			vci-supply = <&vreg_oled_vci>;
 			dvdd-supply = <&vreg_oled_dvdd>;
 		};

-- 
2.53.0

