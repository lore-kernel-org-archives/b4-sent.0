From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Subject: [PATCH 0/2] arm64: dts: rockchip: Add FriendlyElec NanoPi R28S
Date: Sat, 05 Sep 2026 19:17:25 +0800
Message-Id: <20260905-r28s-upstream-v1-0-f68d5389269a@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSwNT3SIji2Ld0oLikqLUxFzdVCNDo1Qj8xQzQzNTJaCegqLUtMwKsHn
 RsRB+cWlSVmpyCcgQpdpaABtk4b1xAAAA
X-Change-ID: 20260905-r28s-upstream-e212e27d6165
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 jensen <jensenhuang@friendlyarm.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1842;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=oAmDDrKnMv/AyVbWT0Wk8eZYpbvdxe5fXhli2PbtOEg=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqzZv71PLerYNfnZBvaoZZdaI6qZFjxf2XOXhd1bVqb0/
 bqVphy1HaUsDGJcDLJiiiyym6ojhVZFzyxikToOM4eVCWQIAxenAEwkuIXhJ6Pel+MTvVhbdk5a
 /PrxU7WGX1++1N7UfRV0Ma47eqrvzShGhvWKCyfHh719vXbvvEkJl2yzfvoyWP8u299w3a9wdeG
 +XGYA
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The [NanoPi R28S](https://wiki.friendlyelec.com/wiki/index.php/NanoPi_R28S) is a dual gigabit Ethernet router board based on the
Rockchip RK3528 SoC. It is closely related to the already supported
NanoPi Zero2, sharing most of its power tree and peripheral routing.

Tested on a metal-case unit without the optional onboard eMMC: boots
from microSD, both Ethernet ports link up at 1000 Mbps, the HYM8563 RTC
registers, and all three LEDs are functional. The USB Type-C connector
registers as a DWC3 UDC in peripheral mode; gadget enumeration against
a USB host was not completed, because that connector is also the 5V
input and a PC port cannot power the board.

The patch referred to [fridendlyarm/kernel-rockchip](https://github.com/friendlyarm/kernel-rockchip/commit/ee640c5344b13a0a317436e2357df01af8268ce7) but with many changes make it suitable for kernel mainline.

Two things I didn't do because they are limited by my current hardware:

- The AICSemi AIC8800D80 WiFi chip on sdio0 has no upstream driver, so
  only the SDIO controller is described.
- The eMMC is described as HS200 rather than the vendor's HS400 with
  enhanced strobe, since the board at hand has an unpopulated eMMC
  footprint and the faster modes could not be verified.

---
安容 (2):
      dt-bindings: arm: rockchip: Add FriendlyElec NanoPi R28S
      arm64: dts: rockchip: Add devicetree for the FriendlyElec NanoPi R28S

 .../devicetree/bindings/arm/rockchip.yaml          |   5 +
 arch/arm64/boot/dts/rockchip/Makefile              |   1 +
 .../arm64/boot/dts/rockchip/rk3528-nanopi-r28s.dts | 404 +++++++++++++++++++++
 3 files changed, 410 insertions(+)
---
base-commit: 32e0f64640d558a0f5410ac5cdd8ebf371c5e6a6
change-id: 20260905-r28s-upstream-e212e27d6165

Best regards,
--  
安容 <HystericalDragons@proton.me>

