From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/6] Add CMN PLL clock controller support for IPQ5018
Date: Fri, 02 May 2025 14:15:42 +0400
Message-Id: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE6bFGgC/02OXQqDMBAGryL73EB+jK5epYikyaYNqNVopSDev
 VFf+rTMwjfMBjPFQDPU2QaR1jCH95BA3DKwLzM8iQWXGCSXmmsuWBindJDZfmBj1zEkLUpHWCq
 PkFZjJB++p/HeXBxp+iTxcj3hYWZi9t33YakzNNJpZUlZ7VEWqIxTzlemMlqjlCgKT0VOJfwH1
 dmZkwvBpiRqj6Zc5m1qOpKqghv0uiq5UvUqodn3H/kC1FroAAAA
X-Change-ID: 20250501-ipq5018-cmn-pll-8e517de873f8
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746180945; l=1972;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=3c3+5z27CJFct2aKCPDEIOAcWESjT7K/nmpBVR7j1XA=;
 b=4vvd5Svjyxb5OLpkhk7VVUVphoiGh7arQX79G3tzygL39SN53iPp0e+3DY/IKAX/+oN2XMX94
 tommmv5sfSDB2awRhaeCYC55VYwNSQN/DLfIO8IgljvxL9sa5tfb7Di
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CMN PLL block of IPQ5018 supplies output clocks for XO at 24 MHZ,
sleep at 32KHZ, and the ethernet block at 50MHZ.

This patch series extends the CMN PLL driver to support IPQ5018.
It also adds the SoC specific header file to export the CMN PLL
output clock specifiers for IPQ5018. The new table of output
clocks is added for the CMN PLL of IPQ5018, which is acquired
from the device according to the compatible.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (6):
      dt-bindings: clock: qcom: Add CMN PLL support for IPQ5018 SoC
      clk: qcom: ipq5018: mark XO clock as critical
      clk: qcom: ipq-cmn-pll: Add IPQ5018 SoC support
      dt-bindings: mfd: qcom,tcsr: Add compatible for IPQ5018
      arm64: dts: ipq5018: Add CMN PLL node
      arm64: dts: qcom: Update IPQ5018 xo_board_clk to use fixed factor clock

 .../bindings/clock/qcom,ipq9574-cmn-pll.yaml       | 11 +++-
 .../devicetree/bindings/mfd/qcom,tcsr.yaml         |  1 +
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts     |  3 +-
 .../dts/qcom/ipq5018-tplink-archer-ax55-v1.dts     |  3 +-
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              | 40 +++++++++++-
 drivers/clk/qcom/gcc-ipq5018.c                     |  2 +-
 drivers/clk/qcom/ipq-cmn-pll.c                     | 72 ++++++++++++++++++----
 include/dt-bindings/clock/qcom,ipq5018-cmn-pll.h   | 16 +++++
 8 files changed, 129 insertions(+), 19 deletions(-)
---
base-commit: 8a2d53ce3c5f82683ad3df9a9a55822816fe64e7
change-id: 20250501-ipq5018-cmn-pll-8e517de873f8
prerequisite-change-id: 20250411-qcom_ipq5424_cmnpll-960a8f597033:v2
prerequisite-patch-id: dc3949e10baf58f8c28d24bb3ffd347a78a1a2ee
prerequisite-patch-id: da645619780de3186a3cccf25beedd4fefab36df
prerequisite-patch-id: 4b5d81954f1f43d450a775bcabc1a18429933aaa
prerequisite-patch-id: 541f835fb279f83e6eb2405c531bd7da9aacf4bd

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

