From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 15 Jun 2025 22:35:03 +0200
Subject: [PATCH v2 1/4] arm64: dts: qcom: msm8976: Make blsp_dma
 controlled-remotely
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250615-bqx5plus-v2-1-72b45c84237d@apitzsch.eu>
References: <20250615-bqx5plus-v2-0-72b45c84237d@apitzsch.eu>
In-Reply-To: <20250615-bqx5plus-v2-0-72b45c84237d@apitzsch.eu>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750019747; l=1769;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=tou8+NFaKkVAfh9dyXrj9kZqM4iUPndfWaC+WwSYyHc=;
 b=4Xmoe6/myYB3cYhDeLzNJWgowocjQ8LtNC6kZwXhFxmvB1UuR2G5bjZxqiy+Z3DEC2Xbfb00A
 TAvF9S8o3inBADxfUyOLYNniIVRlim3HbM2AMDILVpiMAmZuCTFZnLF
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The blsp_dma controller is shared between the different subsystems,
which is why it is already initialized by the firmware. We should not
reinitialize it from Linux to avoid potential other users of the DMA
engine to misbehave.

In mainline this can be described using the "qcom,controlled-remotely"
property. In the downstream/vendor kernel from Qualcomm there is an
opposite "qcom,managed-locally" property. This property is *not* set
for the qcom,sps-dma@7884000 and qcom,sps-dma@7ac4000 [1] so adding
"qcom,controlled-remotely" upstream matches the behavior of the
downstream/vendor kernel.

Adding this fixes booting Longcheer L9360.

[1]: https://git.codelinaro.org/clo/la/kernel/msm-3.10/-/blob/LA.BR.1.3.7.c26/arch/arm/boot/dts/qcom/msm8976.dtsi#L1149-1163

Fixes: 0484d3ce0902 ("arm64: dts: qcom: Add DTS for MSM8976 and MSM8956 SoCs")
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 arch/arm64/boot/dts/qcom/msm8976.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/msm8976.dtsi b/arch/arm64/boot/dts/qcom/msm8976.dtsi
index e2ac2fd6882fcf47e846a92d45e0fcb9beba633a..2a30246384700dac2ec868c6f371248cfcc643fc 100644
--- a/arch/arm64/boot/dts/qcom/msm8976.dtsi
+++ b/arch/arm64/boot/dts/qcom/msm8976.dtsi
@@ -1331,6 +1331,7 @@ blsp1_dma: dma-controller@7884000 {
 			clock-names = "bam_clk";
 			#dma-cells = <1>;
 			qcom,ee = <0>;
+			qcom,controlled-remotely;
 		};
 
 		blsp1_uart1: serial@78af000 {
@@ -1451,6 +1452,7 @@ blsp2_dma: dma-controller@7ac4000 {
 			clock-names = "bam_clk";
 			#dma-cells = <1>;
 			qcom,ee = <0>;
+			qcom,controlled-remotely;
 		};
 
 		blsp2_uart2: serial@7af0000 {

-- 
2.49.0

