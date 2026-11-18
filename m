From: =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
Subject: [PATCH 0/3] arm64: dts: socfpga: agilex5: add support for Terasic
 DE25-Nano
Date: Wed, 18 Nov 2026 20:07:12 +0100
Message-Id: <20261118-de25-nano-v1-0-473d16131f7a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDXp1E9wFbGoGoxFSYtIpHdXL
 L/k5d3gyTF5aJIbHJ3sebURmCZgZm0nEjxEg5KqRMRKDKQKYbVdhcxHXWd9URJKiP3maOTre7X
 db3/0C5n9HUAID2zM3z9tAAAA
X-Change-ID: 20261118-de25-nano-04fa93b56e10
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Mahesh Rao <mahesh.rao@altera.com>, 
 Mohamad Asyraaf Azhar <mohamad.asyraaf.azhar@altera.com>, 
 =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795028833; l=1507;
 i=alex.cramt@gmail.com; s=20261118; h=from:subject:message-id;
 bh=I2QEA8KTDnJXjo3wsvoSR95BaaAm1rnHP6QBDVZCnCQ=;
 b=fY89QoAyxTxKeMwb4ZIxvRr60vqML9S4ya0Ah54MitvFZdihnz9DWTRrs3vZhjDf9MhnDE7b4
 6scpMSeb0uVCvcHjHqyoaTxxB+HwGysEoK6TNLyco/oYvz5wbbgMxOG
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

Tested on the board on v7.4-rc2 carrying the same device tree (its
decompiled DTB matches this series' build on next-20261117 apart from
nodes added to the dtsi since): boot from the microSD slot, gigabit
Ethernet, USB, the HPS LED, and FPGA configuration through the
stratix10-soc FPGA manager. dt_binding_check, dtbs_check and
dt-check-style --mode=strict are clean.

---
Alexandra Østermark (3):
      arm64: dts: socfpga: agilex5: add the service layer interrupt
      dt-bindings: arm: altera: add Terasic DE25-Nano
      arm64: dts: socfpga: agilex5: add support for Terasic DE25-Nano

 Documentation/devicetree/bindings/arm/altera.yaml  |  1 +
 arch/arm64/boot/dts/altera/Makefile                |  1 +
 arch/arm64/boot/dts/altera/socfpga_agilex5.dtsi    |  2 +
 .../boot/dts/altera/socfpga_agilex5_de25_nano.dts  | 91 ++++++++++++++++++++++
 4 files changed, 95 insertions(+)
---
base-commit: 7cfbf79c66c63e807ea452abf0546e6f6d6833a6
change-id: 20261118-de25-nano-04fa93b56e10

Best regards,
--  
Alexandra Østermark <alex.cramt@gmail.com>

