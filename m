From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH v2 0/3] arm64: dts: rockchip: Enable the NPU on some rk3588
 boards
Date: Thu, 01 Jan 2026 07:43:08 +0100
Message-Id: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-0-013cf5d5c39d@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHwXVmkC/52NTQ6CMBBGr0K6dkx/RKsr72FYFDrKBGmbKRIN4
 e5WjuDyfV/y3iIyMmEWl2oRjDNliqGA3lWi6114IJAvLLTUtdJGguPxeAA/ZeDYDV1PCXgwtbU
 Q0gswuPaJI4byK9TWSK/x1EpRfInxTu+tdWsK95SnyJ8tPavf+k9lViDBG9sqq119RnNNjj0F2
 gecRLOu6xcK/hwP5AAAAA==
X-Change-ID: 20251230-arm64-dts-rockchip-rk3588-npu-enablements-1e2830d2e7b0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jimmy Hon <honyuenkwun@gmail.com>, Tomeu Vizoso <tomeu@tomeuvizoso.net>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1792; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=y7Xib1VykIOIuwDYT1LgmZreFH/0h6GvKNisTgW4mqI=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpVhehlL5HowYfiZYW+zzvkD9xqKEkcqkG8am37
 CxHDRvpsiWJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaVYXoQAKCRA7Xj/jnsft
 6e9hB/4l4ovOHeAw15WbmnPtzYpJE+kbvTCuT64We5Nn1iXZyE1UjGdXsKSb+jIlx1Zm2x4HPXE
 WE1ixuJDeShaDWmsAOcokRLsHDmkQUkyoSyodWOBd1+varM7QAxbGztMA+SXI1SA5EQ2x5cp0Or
 ocyRcOyVzLsSyPMyY9LcYwJhQWlbJhULCPn0FC/bZ0BGDawmWLI+KZd8tnr3+TQaIDrKeiwMQMT
 dNFApaPBJNwFxIT4xW5bYBe49qRg64wWtvCwiPaAcdFLRIU44WxK5Z21CDV69zX1dJMs4bxqZKS
 BLl44+U6rmW0wHngUCODQPWR5T15qd7I5nNXBjQ3HQL0IUIh
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series enables the NPU on a few Rockchip rk3588 boards.
In every case here, the required regulator was already in place.
As suggested by Jimmy Hon [1], since the NPU power domain supply is
being described, also remove the always-on property from the regulator.

In Jimmy's words: the commit message for the introduction of the 
pd_npu label mentions how the regulator no longer needs to be always on. 
[2]

I might send a separate series dropping always-on from the same regulator
on the boards that have already added the NPU bits with no changes to 
the regulator. I wonder if I should add Fixes for those.

[1] https://lore.kernel.org/all/CALWfF7KHyKmDcEL9=mYzfCRWc_cymNscoFdeXr8P2frJeww5vA@mail.gmail.com/
[2] https://lore.kernel.org/linux-rockchip/20250721-6-10-rocket-v9-7-77ebd484941e@tomeuvizoso.net/

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
Changes in v2:
- Drop the always-on from the vdd_npu_s0 regulator.
- Link to v1: https://lore.kernel.org/r/20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-0-d38b182a59e3@pardini.net

---
Ricardo Pardini (3):
      arm64: dts: rockchip: Enable the NPU on NanoPC T6/T6-LTS
      arm64: dts: rockchip: Enable the NPU on FriendlyElec CM3588
      arm64: dts: rockchip: Enable the NPU on Turing RK1

 .../dts/rockchip/rk3588-friendlyelec-cm3588.dtsi   | 35 ++++++++++++++++++++-
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 36 +++++++++++++++++++++-
 .../arm64/boot/dts/rockchip/rk3588-turing-rk1.dtsi | 35 ++++++++++++++++++++-
 3 files changed, 103 insertions(+), 3 deletions(-)
---
base-commit: 9448598b22c50c8a5bb77a9103e2d49f134c9578
change-id: 20251230-arm64-dts-rockchip-rk3588-npu-enablements-1e2830d2e7b0

Best regards,
-- 
Ricardo Pardini <ricardo@pardini.net>

