From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH 0/3] arm64: dts: rockchip: Enable the NPU on some rk3588
 boards
Date: Tue, 30 Dec 2025 21:19:29 +0100
Message-Id: <20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-0-d38b182a59e3@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANIzVGkC/x2NywrCMBAAf6Xs2YU8Wg3+inhIk9UutduwUSmU/
 rvB4zAws0MlZapw7XZQ+nLlVRrYUwdpivIk5NwYnHGDdd5g1OXcY35X1DXNaeKCOvshBJTyQZI
 4vmghad6SC95kR5fRQOsVpQdv/9ftfhw/usSzmnsAAAA=
X-Change-ID: 20251230-arm64-dts-rockchip-rk3588-npu-enablements-1e2830d2e7b0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=878; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=Z4EYAHZGekQfOTPPZ/bCzt9bocu5SLTKB2VfqWaqPQI=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpVDPYd76x2JB906NyNHFhO6NnaxWsW+lO80Uql
 Ji2PwKD1t+JATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaVQz2AAKCRA7Xj/jnsft
 6UMPB/0aiS04N/PRQ7spsEThwruzr2esSQwAH9xDCV4eZcHZQTkVVHaH5RnanJ28d3fabRgZmSy
 1BmvrsltvRrqNQ3rI1Kay3RfkvZU2vn0IMEMA985DFXBjCEV43ZGCNMd2qX0JLBUZ73Q1lA4a3R
 gtXRZZqOyY368C6QyJWVjFWfQjPzWtt4X8DKKQzcWLpC6O2FJWCA1NHr/0gr6MOgpwSViPL9P+C
 fwKllrnSZeMRvupYc0FHxO5Z0JiGVY6fjB9mSAjzWSMszf6ZlvEB3ZLmfF2PdRTQKlH5FDx5KDl
 j0E+pA6o3ysj2lr2BwqUO0AVil5ptuiZRO96Ot1J6lQWk7Bz
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series enables the NPU on a few Rockchip rk3588 boards.
In every case here, the required regulator was already described.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
Ricardo Pardini (3):
      arm64: dts: rockchip: Enable the NPU on NanoPC T6/T6-LTS
      arm64: dts: rockchip: Enable the NPU on FriendlyElec CM3588
      arm64: dts: rockchip: Enable the NPU on Turing RK1

 .../dts/rockchip/rk3588-friendlyelec-cm3588.dtsi   | 34 +++++++++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 35 ++++++++++++++++++++++
 .../arm64/boot/dts/rockchip/rk3588-turing-rk1.dtsi | 34 +++++++++++++++++++++
 3 files changed, 103 insertions(+)
---
base-commit: 9448598b22c50c8a5bb77a9103e2d49f134c9578
change-id: 20251230-arm64-dts-rockchip-rk3588-npu-enablements-1e2830d2e7b0

Best regards,
-- 
Ricardo Pardini <ricardo@pardini.net>

