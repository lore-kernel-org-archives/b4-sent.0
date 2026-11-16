From: Ishu Brar <patches@brar.si>
Subject: [PATCH RESEND v3 0/2] clk: qcom: Add SM7250 graphics clock
 controller
Date: Mon, 16 Nov 2026 11:51:31 +0530
Message-Id: <20261116-gpucc-sm7250-v3-0-df68449f0e36@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22QS0/DMBCE/0rkM47s9aupEOqBXjnAEXHwY9MaS
 FPsJAJV+e+4aQ8V4jir/WZm90QypoiZrKsTSTjFHPtDEeKuIn5vDzukMRRNgIHmDATdHUfvae4
 MKEY1BxuU0My0SApyTNjG78XulTxvX7ZPj+TtMs+je0c/nL2umwm/xpI3XNc7zNkueevq/hLHN
 ZMgBdQrkJTTnBBzKfVhE2s42+w6Gz9r33cPZ0dnM9Iiujisq1ZpA1aEtmXQ8KCtVOiYB7VyTQB
 n0cnglTFLu33MQ59+lh9MfCnz/7kTp4yGhsvGo8eVw41LNtU5LjYT3KLmDwoFNUYwpVEyKW7Qe
 Z5/AQ4NbiCHAQAA
X-Change-ID: 20261023-gpucc-sm7250-612ad53607fe
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Taniya Das <taniya.das@oss.qualcomm.com>, 
 Imran Shaik <quic_imrashai@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794810107; l=4051;
 i=patches@brar.si; h=from:subject:message-id;
 bh=ic5XdO1AeDrgCu2w9+lfdrzstjc+aLj8SGbXgvtd4Bo=;
 b=Ls1XolrLfUy5tvbN6P1zkARSElvjuS7Mk6vnbbnGIyo+//9rwZuBLcHVd6Kf8vp7S9ENndmKJ
 TM7KxpNrdqxCoe70Be5y02pfL3pOP1qyRozAoag/pHETcn/fIbRc6lg
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the graphics clock controller (GPU_CC) of the Qualcomm SM7250 SoC
(Snapdragon 765/765G/768G): a binding patch with the header, and the
driver. It provides the GMU clock with its Lucid PLL, the GPU CX and GX
power domains and the GPU SMMU vote clock. The driver is written in the
current style of the qcom gpucc drivers; the PLL settings, frequency table,
register offsets and GDSC data come from the downstream driver of the
platform.

This series depends on the SM7250 GCC series from Shreeshankar [1] (the
Kconfig symbol SM_GCC_7250 and the parent clocks come from it). The
Adreno 620 series [2] needs this controller for the GMU clock and the GPU
power domains. The SoC devicetree nodes are not part of this series.

Tested on a OnePlus Nord (a 7.3 based tree): the controller probes, and
the Adreno 620 powers up its CX and GX domains and runs Vulkan work with
these clocks.

[1] https://lore.kernel.org/r/20261016042432.824-1-sreeshankar0910@gmail.com
[2] https://lore.kernel.org/r/20261023-adreno-a620-v3-0-2d1d566e5e13@brar.si

---
Changes in v3 RESEND:
- No changes; resending after the merge window.

Changes in v3:
- Use GENMASK() and FIELD_PREP() for the GMU CBCR wake/sleep fields; the
  mask and value written to 0x1098 are unchanged (0xff0 and 0xff0)
  (Konrad Dybcio)
- Set .use_rpm in the qcom_cc_desc, as the newer GPU clock controller
  drivers do (Taniya Das, Konrad Dybcio)
- Keep BRANCH_HALT_VOTED for gpu_cc_hlos1_vote_gpu_smmu_clk instead of
  BRANCH_VOTED as in the SM8250 driver (Abel Vesa): the clock is a
  voted branch and the newer drivers (SM8350, SM8450, SM8550, SM8650,
  SM8750, X1E80100 and others) all use BRANCH_HALT_VOTED, so the status
  is polled on enable; this was changed in v2 on purpose
- Link to v2: https://patch.msgid.link/20261027-gpucc-sm7250-v2-0-773056e4043e@brar.si

Changes in v2:
- Renamed the header to qcom,sm7250-gpucc.h to match the compatible (Krzysztof)
- Converted the driver to the current qcom_cc_driver_data style: the PLL is
  configured by the common code and the GMU CBCR settings by the
  clk_regs_configure callback, with const clk_init_data and DT parent
  indices (Krzysztof)
- Use BRANCH_HALT_VOTED for the GPU SMMU vote clock, so its status is
  polled on enable, as in the newer GPU clock controller drivers
- Link to v1: https://patch.msgid.link/20261023-gpucc-sm7250-v1-0-d9149cece8be@brar.si

To: Bjorn Andersson <andersson@kernel.org>
To: Abel Vesa <abelvesa@kernel.org>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney+clk@redhat.com>
To: Jerome Brunet <jbrunet+clk@baylibre.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Taniya Das <taniya.das@oss.qualcomm.com>
To: Imran Shaik <quic_imrashai@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Ishu Brar (2):
      dt-bindings: clock: qcom: Add SM7250 graphics clock controller
      clk: qcom: Add SM7250 graphics clock controller driver

 .../devicetree/bindings/clock/qcom,gpucc.yaml      |   2 +
 drivers/clk/qcom/Kconfig                           |  10 +
 drivers/clk/qcom/Makefile                          |   1 +
 drivers/clk/qcom/gpucc-sm7250.c                    | 379 +++++++++++++++++++++
 include/dt-bindings/clock/qcom,sm7250-gpucc.h      |  36 ++
 5 files changed, 428 insertions(+)
---
base-commit: f5672a3dff0291d6a45eb0c258b9d2baeb4dc577
change-id: 20261023-gpucc-sm7250-612ad53607fe
prerequisite-message-id: <20261016042432.824-1-sreeshankar0910@gmail.com>
prerequisite-patch-id: 73b48e3c0861782784c45684336c1cb2c8b37852
prerequisite-patch-id: fb97b00b62996e3d3634185a803a33eb545522dd
prerequisite-patch-id: 8190bf61e50dbe2e09859505e8e4d8cb4ab02ddb
prerequisite-patch-id: 8c34692012f724a93c58e1df02338acec497344d
prerequisite-patch-id: 983ca91f160cca12047d9b0829c8cbbf4cc32e98

Best regards,
--  
Ishu Brar <patches@brar.si>

