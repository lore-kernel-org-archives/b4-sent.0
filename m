From: Joachim Eastwood <joachim.eastwood@gmail.com>
Subject: [PATCH 0/9] arm64: dts: rockchip: NanoPi 6 series fixes and
 improvements
Date: Wed, 14 Oct 2026 18:33:00 +0200
Message-Id: <20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CQAxA4auQrm0yTORHr2JYQK1Qk+lMpkhMC
 Hd31OW3eG8H4yxscK12yLyJSdSC+lQBLaPOjHIvBu986zp/QR01JsHQooSU48aBdTVs+jNRN7m
 e6gZKnDI/5P0b34a/7TU9mdbvDY7jA1Si6uZ6AAAA
X-Change-ID: 20260729-nanopi-m6-improvements-584cc7b08c15
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Diederik de Haas <diederik@cknow-tech.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791995685; l=1823;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=M4oiCczvM6va+isk9WjeSYqDXsbuek40oN13boAHt8I=;
 b=xeGKQRKGVzN67jaE0vQ2rOyJewPenDA0ogXBP4ukvIeWddMRTGL61vnp9dk5p0HmKdbZxvORi
 lmfDP60AGfbDqIcrlIFG5lraHthr6513r8hHj9ES9D337D1w3tWZExj
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series contains a few fixes and miscellaneous improvements
for the NanoPi 6 series of boards.

Patch 1 fixes the voltage range on the SDMMC regulator.
Patch 2 enables HS400 mode on eMMC. Tested on my M6 board.
Patch 3 adds an IIO HWMON device to monitor the input voltage.
Patch 4 moves a regulator that only exist R6 boards to the correct dtsi.
Patch 5-9 renames DT names to match the schematics signals/nets.

If patch 5-9 is just considered churn I'll drop them. These are more
nice to have and just makes it easier to cross-reference DT and
schematics.

Based on linux-rockchip tag v7.4-rockchip-dts64-3.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
Joachim Eastwood (9):
      arm64: dts: rockchip: rk3588s-nanopi: fix sd min/max voltage
      arm64: dts: rockchip: rk3588s-nanopi: enable mmc-hs400 and add supplies
      arm64: dts: rockchip: rk3588s-nanopi: add voltage iio-hwmon device
      arm64: dts: rockchip: rk3588s-nanopi: move vcc_3v3_s0 to nanopi-r6
      arm64: dts: rockchip: rk3588s-nanopi: rename sd power pin
      arm64: dts: rockchip: rk3588s-nanopi: rename usb host power pin
      arm64: dts: rockchip: rk3588s-nanopi: rename gmac1 reset pin
      arm64: dts: rockchip: rk3588s-nanopi-m6: rename pcie2 power pin
      arm64: dts: rockchip: rk3588s-nanopi-m6: rename pcie2 power rail

 .../arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi | 14 ++++---
 .../arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi | 14 +++++++
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi   | 45 ++++++++++++----------
 3 files changed, 48 insertions(+), 25 deletions(-)
---
base-commit: ae965b9856f033145e292b0c29082a26bcc45efd
change-id: 20260729-nanopi-m6-improvements-584cc7b08c15

Best regards,
--  
Joachim Eastwood <joachim.eastwood@gmail.com>

