From: Biswapriyo Nath <nathbappai@gmail.com>
Subject: [PATCH 0/5] Fix volume up and add RTC, PRNG, UART in xiaomi-ginkgo
Date: Mon, 19 Jan 2026 15:13:02 +0000
Message-Id: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zXMywrCMBCF4VcpszaShBKriPge0kXaTuJgm2jSG
 5S+u6HV5X/gfAtEDIQRLtkCAUeK5F0KccigfmpnkVGTGiSXigtRsJm074hZci/rmUHdDwEjU4X
 MUXCDtRSQzu+AhuYNfpR7B/wMye/3ETqMUW/+Jbv+ePXnJ2pbP7FRMs5ydc4NVideN9W90+Rac
 uTs0Qd7g3Jdv9QrS0fEAAAA
X-Change-ID: 20260118-xiaomi-ginkgo-features-6824e10fec21
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Biswapriyo Nath <nathbappai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768835583; l=1701;
 i=nathbappai@gmail.com; s=20260118; h=from:subject:message-id;
 bh=Y8J3a22LxojTwtjFDIOq3Xh2Y1/v/z1bHpEomhNiyzA=;
 b=NM+djRWh0hDybZin4U0mrEc7MyDRvjJyr4UOy3vHhBJXA2rYheA/U9sXRcJ1upF5wXsk97R5b
 6iH0ILhSqhEA0H5qE7snvR1uaPnD+7cg3QQv3FjWngBVU3kiXziKcvg
X-Developer-Key: i=nathbappai@gmail.com; a=ed25519;
 pk=slmb/9yXbet+KTiT3EYLCp0p0MEOYa3EdjUXP+HXfjg=
X-Endpoint-Received: by B4 Relay for nathbappai@gmail.com/20260118 with auth_id=607
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The patch series fixes an issue and adds some components.

Changes:
- Fix volume up button gpio and power source in xiaomi ginkgo.
- Enable RTC from pm6125 in xiaomi ginkgo.
- Add prng node in sm6125.
- Add debug uart node in sm6125.
- Enable debug uart in xiaomi ginkgo.

Depends on:
[1] https://lore.kernel.org/linux-arm-msm/20260116-xiaomi-willow-v2-0-4694feb70cdb@mainlining.org/

Signed-off-by: Biswapriyo Nath <nathbappai@gmail.com>
---
Biswapriyo Nath (5):
      arm64: dts: qcom: sm6125-xiaomi-ginkgo: Fix volume up button
      arm64: dts: qcom: sm6125-xiaomi-ginkgo: Enable RTC
      arm64: dts: qcom: sm6125: Add PRNG node
      arm64: dts: qcom: sm6125: Add debug UART node
      arm64: dts: qcom: sm6125-xiaomi-ginkgo: Enable debug UART

 .../boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi | 22 ++++++++++++++++---
 arch/arm64/boot/dts/qcom/sm6125.dtsi               | 25 ++++++++++++++++++++++
 2 files changed, 44 insertions(+), 3 deletions(-)
---
base-commit: e5d16f0daba655b8c63032f7b0ae1f21881d821f
change-id: 20260118-xiaomi-ginkgo-features-6824e10fec21
prerequisite-message-id: <20260116-xiaomi-willow-v2-0-4694feb70cdb@mainlining.org>
prerequisite-patch-id: 97a500cccd7099f84f02d24b79f9632264ff0919
prerequisite-patch-id: a76649864084c6349d5bbd425c84489621e3d950
prerequisite-patch-id: 88844031b714eecc8185b968927ece52795237cd
prerequisite-patch-id: 7f01d4e3dafb4911244d6bf03db9ac03395f8609
prerequisite-patch-id: c339d93729aee842cce74ba1316f5b5c8d01d04e
prerequisite-patch-id: daad11c94235247984631a78b2c2cda74f8af5bf
prerequisite-patch-id: 816740927f2e464864884584e6af596b038074dd

Best regards,
-- 
Biswapriyo Nath <nathbappai@gmail.com>

