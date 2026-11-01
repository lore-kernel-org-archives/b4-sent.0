From: Joachim Eastwood <joachim.eastwood@gmail.com>
Subject: [PATCH v2 0/9] arm64: dts: rockchip: NanoPi 6 series fixes and
 improvements
Date: Sun, 01 Nov 2026 22:55:18 +0100
Message-Id: <20261101-nanopi-m6-improvements-v2-0-a24769efda23@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4V0bU2nPIqu/A/DAsoAY+wjLTYaw
 r8LuHZ5knvPWVjEQBjZNVtYwESRnN1AnjKmp9aOyKnfmEkhK6HkhdvWOk/cVJyMDy6hQTtHXta
 F1qoTtYaSbWcfcKD3Ib43P46v7oF63m37YqI4u/A5ygn23REBAcW/SAIuOCrIBwXYFX1+G01Lz
 7N2hjXrun4BvvIHD84AAAA=
X-Change-ID: 20260729-nanopi-m6-improvements-584cc7b08c15
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793570136; l=2308;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=Z+SfRe4fp/DxdMUhi/Z0MvVrWIpYybLtZkdy3R3z0kk=;
 b=+sE670vEICeBu231TaMLM2TkQ1lJHsPZXbXjkd/oJc9VPF5gyNUwU3QhQtpT94MK21T0UrGqX
 5N7giBeUMinBhFcvkeDb7lfCn1kKs9SNtZ4bLnLU9o+17qkhC7u4ch9
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

Schematics for the boards can be found here:
M6: https://wiki.friendlyelec.com/wiki/images/8/85/NanoPi_M6_2405_SCH.PDF
R6C: https://wiki.friendlyelec.com/wiki/images/f/f7/NanoPi_R6C_2302_SCH.PDF
R6S: https://wiki.friendlyelec.com/wiki/images/2/2f/NanoPi_R6S_2208_SCH.PDF

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
Changes in v2:
- Add schematic links to cover letter to ease review
- Renamed rtl8211f node to gmac
- Add R-b tags from Shawn Lin
- Rebased on v7.4-rc1
- Link to v1: https://patch.msgid.link/20261014-nanopi-m6-improvements-v1-0-e713f71eb4d3@gmail.com

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

 .../arm64/boot/dts/rockchip/rk3588s-nanopi-m6.dtsi | 14 ++++--
 .../arm64/boot/dts/rockchip/rk3588s-nanopi-r6.dtsi | 14 ++++++
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi   | 55 ++++++++++++----------
 3 files changed, 53 insertions(+), 30 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20260729-nanopi-m6-improvements-584cc7b08c15

Best regards,
--  
Joachim Eastwood <joachim.eastwood@gmail.com>

