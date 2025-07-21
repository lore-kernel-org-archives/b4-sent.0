From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v5 0/2] Add CMN PLL clock controller support for IPQ5018
Date: Mon, 21 Jul 2025 10:04:34 +0400
Message-Id: <20250721-ipq5018-cmn-pll-v5-0-4cbf3479af65@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHLYfWgC/4XOwW7CMAwG4FdBOS/ITpom5cR7TDsU14VopWnTU
 m1CfXcCaBqiSJys35K/32cxcPQ8iM3qLCJPfvChTcF8rAQdynbP0lcpCwXKgAGUvuvTcJKOrey
 aRjo2aCt2VtdOpKsucu1/buLn1z1H7k8JHv+XBz+MIf7eWie8bv8K1KJgQglS2QIUIWVgcRtOY
 xPC95rCUVy1ST0K+VJQSSAoi5qIK8RsKegHAV8IOgm1drklUyqw+VLI3ghZErQrynyngQ08/TD
 P8wWuNuGpiwEAAA==
X-Change-ID: 20250501-ipq5018-cmn-pll-8e517de873f8
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753077887; l=2648;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=GJGKJkD0S9i1I48RnIhVN+NDQEpwg+vdqVOw66GHbhc=;
 b=cKuDzYsoKrIQCumB61hsrkVupRSRJ1IFEeC02V/6gpFapF6av5n4m4+ZRUXJlJB2RpN1ONsD6
 Tr9IGbuRMEpDNl5ykmXmWUBiDSklyJ1DboA0HmvIYB+osCfRP2ms/KV
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CMN PLL block of IPQ5018 supplies output clocks for XO at 24 MHZ,
sleep at 32KHZ, and the ethernet block at 50MHZ.

This patch series extends the CMN PLL driver to support IPQ5018. It also
adds the SoC specific header file to export the CMN PLL output clock
specifiers for IPQ5018. A new table of output clocks is added for the
CMN PLL of IPQ5018, which is acquired from the device according to the
compatible.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Changes in v5:
- Rebased on tip of master for patches to cleanly apply
- Picked up Konrad's RB tag
- Link to v4: https://lore.kernel.org/r/20250516-ipq5018-cmn-pll-v4-0-389a6b30e504@outlook.com

Changes in v4:
- Re-add missing CMN PLL node after git pull and rebase on linux-next
- Link to v3: https://lore.kernel.org/r/20250516-ipq5018-cmn-pll-v3-0-f3867c5a2076@outlook.com

Changes in v3:
- After further testing and evaluating different solutions, reverted to
  marking the XO clock in the GCC as critical as agreed with Konrad
- Moved kernel traces out of commit message of patch 1 to under the
  diffstat separator and updated commit message accordingly
- Updated commit message of patch 3
- Link to v2: https://lore.kernel.org/r/20250506-ipq5018-cmn-pll-v2-0-c0a9fcced114@outlook.com

Changes in v2:
- Moved up commit documenting ipq5018 in qcom,tcsr bindings
- Fixed binding issues reported by Rob's bot
- Undone accidental deletion of reg property in cmn pll bindings
- Fixed register address and size based on address and size cells of 1
- Removed XO and XO_SRC clock structs from GCC and enabled them as
  always-on as suggested by Konrad
- Removed bindings for XO and XO_SRC clocks
- Removed qcom,tscr-cmn-pll-eth-enable property from bindings and will 
  move logic to ipq5018 internal phy driver as per Jie's recommendation.
- Removed addition of tcsr node and its bindings from this patch set
- Corrected spelling mistakes
- Link to v1: https://lore.kernel.org/r/20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com

---
George Moussalem (2):
      arm64: dts: ipq5018: Add CMN PLL node
      arm64: dts: qcom: Update IPQ5018 xo_board_clk to use fixed factor clock

 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts     |  3 +-
 .../dts/qcom/ipq5018-tplink-archer-ax55-v1.dts     |  3 +-
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              | 34 ++++++++++++++++++++--
 3 files changed, 36 insertions(+), 4 deletions(-)
---
base-commit: 098738b001e2e6944805f8ea53e9bc711f13d47f
change-id: 20250501-ipq5018-cmn-pll-8e517de873f8

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

