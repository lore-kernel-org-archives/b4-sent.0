From: Ishu Brar <patches@brar.si>
Subject: [PATCH 0/2] clk: qcom: Add SM7250 graphics clock controller
Date: Fri, 23 Oct 2026 15:40:07 +0530
Message-Id: <20261023-gpucc-sm7250-v1-0-d9149cece8be@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2O2W7CMBBFfyXyc43siRcSVRX/UfHgZRzc1iyep
 EJC/DuG8HikO+fMjRHWjMTG7sYq/mfKp2MD+dGxcHDHCXmOjRkIMFJAz6fzEgKnYkELbiS4qHs
 jbELWTs4VU76+dN/7lWnxPxjmp+O9qHhZWmdeZ6wgkXt1xu5zzUgjFKgeNltQXHKqiNSe+XVVD
 FLspuLy3yacytfT6B0hb1DyPHZJGwuujykJGGQ0Tmn0IoDe+iGCd+hVDNpatr/fHyBHHdz8AAA
 A
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
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792750212; l=2244;
 i=patches@brar.si; h=from:subject:message-id;
 bh=csQC91w2xnFUlZjbWTApHmZ5Uas0bD/vSn5E/fO39W4=;
 b=eoO5HEEjzPQcGmT63wRlGxDPu6REpgOtQxbetg3n/SEXmy874oxqpn3A+/SAmh1TCsEuINkpy
 19GMUOwlu6XCEQkc5wQ7/tT37XoQ6N0a4Ab0cVj90VkRljn55+wmc0d
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the graphics clock controller (GPU_CC) of the Qualcomm SM7250 SoC
(Snapdragon 765/765G/768G): a binding patch with the header, and the
driver. It provides the GMU clock with its Lucid PLL, the GPU CX and GX
power domains and the GPU SMMU vote clock. The driver follows gpucc-sm8250;
the PLL settings, frequency table, register offsets and GDSC data come from
the downstream driver of the platform.

This series depends on the SM7250 GCC series from Shreeshankar [1] (the
Kconfig symbol SM_GCC_7250 and the parent clocks come from it). The
Adreno 620 series [2] needs this controller for the GMU clock and the GPU
power domains. The SoC devicetree nodes are not part of this series.

Tested on a OnePlus Nord (a 7.3-rc7 based tree with the GCC series
applied): the controller probes and provides the clocks and power domains
for the Adreno 620 GPU. I have not tested the GPU at full load on this
combination, and have no other SM7250 hardware.

[1] https://lore.kernel.org/r/20261016042432.824-1-sreeshankar0910@gmail.com
[2] https://lore.kernel.org/r/20261023-adreno-a620-v3-0-2d1d566e5e13@brar.si

Signed-off-by: Ishu Brar <patches@brar.si>
---
Ishu Brar (2):
      dt-bindings: clock: qcom: Add SM7250 graphics clock controller
      clk: qcom: Add SM7250 graphics clock controller driver

 .../devicetree/bindings/clock/qcom,gpucc.yaml      |   2 +
 drivers/clk/qcom/Kconfig                           |  10 +
 drivers/clk/qcom/Makefile                          |   1 +
 drivers/clk/qcom/gpucc-sm7250.c                    | 366 +++++++++++++++++++++
 include/dt-bindings/clock/qcom,gpucc-sm7250.h      |  36 ++
 5 files changed, 415 insertions(+)
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

