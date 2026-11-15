From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH 0/2] clk: qcom: Add the Molokai GPU clock controller
Date: Mon, 16 Nov 2026 01:49:26 +0530
Message-Id: <20261116-molokai-gpucc-v1-0-07cb3bf37c78@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMOQqAMBBA0avI1AZMwAWvIhZZRh23SGJEEO9u1
 PIV/1/g0RF6qJMLHB7kya4RPE1AD3LtkZGJBpGJgnNesMXOdpLE+i1ozYxEZUSZVyo3EJvNYUf
 n92va3z6oEfX+TuC+H7asA8pxAAAA
X-Change-ID: 20261116-molokai-gpucc-daebd2758b5d
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Taniya Das <taniya.das@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794773966; l=1228;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=7bCsfM7c1Cgrcs1XC/fQ/iOLDVlgSCphsmSr/082ak4=;
 b=MaAwnUUSajp+ZCWlFfSL3p07s8gH2w1ka58g1gXrOVAkwJRoAjIFe5keenY83dNY1bdCNhcjM
 DGFQz/BJBO9AHGXsZXntiSpVOp8rHPXwnXvANTsKjmlIK5WX6E06CCA
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The graphics clock controller of the Qualcomm Molokai (SM8845) SoC is the
Kaanapali one, except for the PLL0 CONFIG_CTL_HI value and three branch
clocks that sit one register further. This documents a compatible for it
and handles it in the Kaanapali driver.

The SoC devicetree that uses it is sent separately in "Add support for
the Qualcomm Molokai (SM8845) and the Motorola Signature".

Tested on the Motorola Signature: the GPU clocks come up and the Adreno
829 runs.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Venkat Yadlapati (2):
      dt-bindings: clock: qcom: sm8450-gpucc: Add Molokai GPU clock controller
      clk: qcom: gpucc-kaanapali: Add support for Molokai

 .../bindings/clock/qcom,sm8450-gpucc.yaml          |  1 +
 drivers/clk/qcom/Kconfig                           |  3 ++-
 drivers/clk/qcom/gpucc-kaanapali.c                 | 25 ++++++++++++++++++++++
 3 files changed, 28 insertions(+), 1 deletion(-)
---
base-commit: 6a876df4686788cd39128b62d7fcbff62f39278f
change-id: 20261116-molokai-gpucc-daebd2758b5d

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

