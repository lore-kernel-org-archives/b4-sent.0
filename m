From: =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
Subject: [PATCH v2 0/3] arm64: dts: socfpga: agilex5: add support for
 Terasic DE25-Nano
Date: Thu, 26 Nov 2026 10:47:34 +0100
Message-Id: <20261126-de25-nano-v2-0-02e43ba72681@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Nyw6CMBAAf4Xs2Zpuy0M9+R+GQ4EF1khrWiQa0
 n+34NXjJJOZFQJ5pgCXbAVPCwd2NoE6ZNCOxg4kuEsMSqoSEU+iI1UIa6wTMu/NWTdFSSgh+U9
 PPb/31q3+cXg1d2rnLbAZI4fZ+c8+W3Dz/nUXFFLkle6wRI19Za7DZPhxbN0EdYzxC/+66i60A
 AAA
X-Change-ID: 20261118-de25-nano-04fa93b56e10
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Mahesh Rao <mahesh.rao@altera.com>, 
 Mohamad Asyraaf Azhar <mohamad.asyraaf.azhar@altera.com>, 
 James Clark <jjc@jclark.com>, 
 =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795686456; l=1919;
 i=alex.cramt@gmail.com; s=20261118; h=from:subject:message-id;
 bh=hT7xxaLvHFgWA0nTSeZrZRfSJUG//t51lZyFRrNe5Uk=;
 b=JtlkjNR9BUxMu2igXHNkvR55WbhFelaxhJMezHh1DuH2w1atuYcvwhJLsifX9/ATEg+FRTJI6
 cF6o15JEVuYBqDZBzLp/BSK2QnGkff1kwJ5qHPKie9VFfRCpVEYVNgF
X-Developer-Key: i=alex.cramt@gmail.com; a=ed25519;
 pk=vQBaXUvFG7cCIaWDKclPMjo3b4XfPEVkuPjaWCkYddc=
X-Endpoint-Received: by B4 Relay for alex.cramt@gmail.com/20261118 with auth_id=1561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Terasic DE25-Nano is an Agilex 5 SoC FPGA board. This adds its
binding and device tree, plus the service layer interrupt that the
Agilex 5 dtsi is missing (Stratix 10 and Agilex 7 already have it).

Altera's vendor tree (altera-fpga/linux-socfpga) carries a DE25-Nano
device tree too; this one is written against upstream's dtsi, so it uses
the SD6HC sdmmc node, and it only enables what has been tested on the
board.

Tested on the board on v7.4-rc3 carrying the same device tree (its
decompiled DTB matches this series' build on next-20261117 apart from
nodes added to the dtsi since): boot from the microSD slot, gigabit
Ethernet, USB, the HPS LED, I2C1 with the onboard accelerometer, and FPGA
configuration through the stratix10-soc FPGA manager. dt_binding_check, dtbs_check and
dt-check-style --mode=strict are clean.

---
Changes in v2:
- dts: the HPS LED is active high; v1 copied the vendor trees' active low,
  which inverted it (James Clark)
- dts: enable I2C1, which reaches the onboard LIS2DW12 accelerometer on
  the HPS's own pins (James Clark)
- Collected Conor's Acked-by on the binding
- Link to v1: https://patch.msgid.link/20261118-de25-nano-v1-0-473d16131f7a@gmail.com

---
Alexandra Østermark (3):
      arm64: dts: socfpga: agilex5: add the service layer interrupt
      dt-bindings: arm: altera: add Terasic DE25-Nano
      arm64: dts: socfpga: agilex5: add support for Terasic DE25-Nano

 Documentation/devicetree/bindings/arm/altera.yaml  |  1 +
 arch/arm64/boot/dts/altera/Makefile                |  1 +
 arch/arm64/boot/dts/altera/socfpga_agilex5.dtsi    |  2 +
 .../boot/dts/altera/socfpga_agilex5_de25_nano.dts  | 95 ++++++++++++++++++++++
 4 files changed, 99 insertions(+)
---
base-commit: 7cfbf79c66c63e807ea452abf0546e6f6d6833a6
change-id: 20261118-de25-nano-04fa93b56e10

Best regards,
--  
Alexandra Østermark <alex.cramt@gmail.com>

