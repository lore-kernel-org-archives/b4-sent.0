From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 0/3] ARM: dts: cortina: Enable CS7542 Almond+ peripherals
Date: Fri, 27 Nov 2026 23:59:28 +0300
Message-Id: <20261127-b4-cs7542-peripherals-dts-v1-0-7ce24b842b3a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/41U0W4bRwz8FUPPvYDLXXJ3jaLofxR54JJc+xrbc
 iTFcRDk30vZcQEdGtQCJOEOO7MkZ4bfd0c/rH7cXV993x38aT2u+4d4SL9d7fRWHm58WS2edwj
 IKWFeRln0WKng8hjIx1s/yN1xsVN8pyAIaS1t7gL/ePC5Pr9w//Xx9fn4ZfztejoT/jxx8M9f4
 tLT67HdkKMvur+/X0/XV4OlT8lFvaRWdXC3rNSalDHm1JzUycbrZfd+PMpLtddXv/8sFt+KfX5
 envoCS5qaRodh0OufN/ey3n2Iu/74FR7ewOvDSZcnCoaJwyspea/6/wypvzHcPK775YmDIVdxE
 5D4tXfU8G8DK0YJLQgMGsDoXFvjdxCkRQ73y+mrLV/tdB5DWlpKzaA0nebvKuGNQe/2+ml52J/
 WufpheUpBxthzpgriuJ3po5z09oVKkozuKhkFqxDmwsYpWwn+mQg9DRTO7RLFFAfGyCoijVJzJ
 04z3ubJkMU8d55z9ksUkWmZyXuo3SgX0FIQS26INAmmTc5c+wZVpbWa0Zr1mIpN5AEVO54nmAx
 nLRqfVDeoObwXIGTymS25MsZ0SyIprACcZFrVTV9QvQHB+c/IQZMBO0GYfXoUNnvMJtqmTV8ZU
 o4I9EGzsjBB2DAuSYPzmAk4Fz8zbFDeeLpAx1a7cBTrdUJvNlgtZBClRC1v+irdpdTu3IbajLj
 Vjl5jFBkGoo6uipbrpi8f1nqtGEKqmXNFKLM36hxeo4wx0Nkml0tUZsDQN3EG9+xhzZ4BFbMOo
 W6lZZduLV2iUk25RhstWU4FLM60qKtBLAfRLoIoUSBsKpTQaOhovXCzCmChOnHPM0QsDMZGgq9
 6/XcUYqN8VmmfIg/7ZXw7+XIbpBGG9WE9vSZCuRRAinU15ZeJiI5ce+2RiKRZipZkYlwiRZmL5
 R7CNUy66XrEhs3MiJChjdS4hCSxSyYK5ZhhgjTD7hu/CYV2QAPHaKXEAvWYnWCEssZ2Felq4Vi
 +RA1oGZhaGjMSdZ4MlTwgRKqUIF5xDZFo41LzGQo6cwf1zi1sWmmEg7jE2FNuo89YPBu/hZ3P0
 ew5VlLyHPFLVssgJNcZBaOTAtVxiWpmdaIxdYhzFJZUGMo8KLyUYsGVHMSWdh9//PgHzKsNWek
 GAAA=
X-Change-ID: 20261123-b4-cs7542-peripherals-dts-dfa20a5c748f
To: Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795813168; l=5734;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=6Or3mAfqJgt3Mk70H6WetS/Z7QWVCsD3NX9KPcQ2sKE=;
 b=EUITBK+MoyOS+B03rJA6nIqgPymg9Tbm78GTUasqPRldDT7MPIoQomepVMNMzs6x9ACO/pxM9
 K2jmztc0fPKBhJKArGEnS5jVKq0wvcYg/wHt8bIP+MluWTCZcf4iUpq
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the CS7542 controllers in cs7542.dtsi and the Almond+ wiring in
cs7542-securifi-almondplus.dts. Enable the peripheral drivers in
multi_v7_defconfig. Platform v9 supplies the minimal bootable SoC and board
descriptions; this series completes them using the subsystem bindings.

Use the global syscon for clocks and seven independent network-engine
resets. Describe all three PCIe Root Ports, with one owner for GPIO92
shared by the Wi-Fi endpoints. Put endpoint addresses and factory NVMEM
cells on the actual PCI children. Both QCA8337 CPU links use rgmii-id,
matching the tested board wiring. The MDIO input is the APB clock, as
confirmed by a differentiating clock-domain measurement on Almond+.

The NAND node describes the AXI clock, interrupt, data aperture and
separate flash reset from the vendor resources and posted NAND v5 binding.
The NAND driver has passed the recorded Almond+ checks; that is driver
evidence, not execution of this publication commit. The board properties
follow the tested OpenWrt integration.

Validation: the final sources pass unsuppressed preprocessing/dtc and
complete board schema validation. Reset/clock specifiers, PCIe addresses,
shared PERST ownership and NVMEM cells were checked explicitly. The final
dependency stack is checked with b4 against the base commit below.
Earlier combined revisions passed full native ARM builds and RAM tests;
no new hardware result is claimed for these DT-only changes.

Clock/reset/pinctrl v5, MDIO v4, Ethernet v4, NAND v5 and PCIe v3 are now
posted. Prerequisites select their published code and binding patches;
independent MAINTAINERS-only additions are not needed by this DTS stack.
The bindings and drivers can proceed through their subsystem trees, with
this board series following once those dependencies are available.
No offload-specific overrides or personal LCD package are included.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
Fil Dunsky (3):
      ARM: dts: cortina: Describe CS7542 peripheral controllers
      ARM: dts: cortina: Enable Almond+ board peripherals
      ARM: multi_v7_defconfig: Enable CS7542 board peripherals

 .../dts/cortina/cs7542-securifi-almondplus.dts     | 342 ++++++++++++++++++++-
 arch/arm/boot/dts/cortina/cs7542.dtsi              | 321 ++++++++++++++++++-
 arch/arm/configs/multi_v7_defconfig                |  16 +
 3 files changed, 666 insertions(+), 13 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-peripherals-dts-dfa20a5c748f
prerequisite-message-id: <20261122-b4-cs75xx-v9-0-1fc1b90bd097@gmail.com>
prerequisite-patch-id: 104c6fb668f30ac8c2c5b3b6c524c18caa8808c4
prerequisite-patch-id: e7d503348cbec7558cd084162133f8e34df1c1bc
prerequisite-patch-id: 1d5770db02b983d012f6c58806fbf3f5291a06c9
prerequisite-patch-id: 8515988ae3509d4289a8d845803353f5ed412982
prerequisite-patch-id: 6c0137d52f201d8ec085ee6cc7b2d49af15583d8
prerequisite-patch-id: f591d13e0d394441e3cd28149633c1133bfb79ee
prerequisite-patch-id: b3dad3ee0f7e08ea9e942fd83f3d2a06ff8fb164
prerequisite-patch-id: 4fdf33aaedc9ca7f4d7a59b48e4ae55c497462e4
prerequisite-patch-id: 9b4a468b7b74861017ef533ba0a5574bc14b212e
prerequisite-patch-id: 1f232c94dd3fc0d862203b7c0c1449e6ba9a6859
prerequisite-message-id: <20261120-cs75xx-intc-v5-0-f2be75c5e97c@gmail.com>
prerequisite-patch-id: d1aa6857057b1e76a68ba14d4ea17352ffa90c7e
prerequisite-patch-id: 1fd32c18f2d4a7700528bf45da72b30b62744171
prerequisite-message-id: <20261119-cs75xx-gpio-v6-0-37aeda0aaedd@gmail.com>
prerequisite-patch-id: 7189d6a033e0e18b87b72f3f9b49a1c71a97a2b8
prerequisite-patch-id: a70999df9edd8fbb4ea81ca7e782aa89f52b4a06
prerequisite-message-id: <20261124-cs75xx-i2c-v8-0-d0800b967886@gmail.com>
prerequisite-patch-id: 1ccad6a46a6b3391a0244edbdbc4949b6614e271
prerequisite-patch-id: ac9ec16b2e96d5580a256823ab1330098380ae32
prerequisite-message-id: <20261121-arm-twd-wdt-v9-1-8118d048cfde@gmail.com>
prerequisite-patch-id: e8d416021a43d45b01ac95877bb1c42a46d30153
prerequisite-message-id: <20261124-arm-twd-clock-notifier-v1-1-62933570ae27@gmail.com>
prerequisite-patch-id: 66eb0299dcb45847726974805c675a856fea149d
prerequisite-patch-id: a1ab9eca32a27a52346d613d4611f152e1b2a638
prerequisite-patch-id: 65d46bb3caaa8518ee561f65d3f603ade396fff9
prerequisite-patch-id: 55dc4f1e91fc85340c4422438225f50fdf636799
prerequisite-patch-id: 7a88732d8d9fdedf26b0729211211d2f74cccc17
prerequisite-patch-id: 7fbe9405265ef3d1ec62811415a46c0061afd7c8
prerequisite-patch-id: 07e805007e8d5e0c1d06e50a9ffe799f9d61bb35
prerequisite-patch-id: 5301369d9b5f76a650c5e6c01b63bf10634e9ffe
prerequisite-patch-id: 5e86fea092879a6940e7f098db6cd346ac515837
prerequisite-patch-id: 49ea479e68bcdf4bb792e712130b22cb9cc2d378
prerequisite-patch-id: ebd89772638cdde67204f9859648c532072f8f64
prerequisite-patch-id: 3602aa81630ee3e18d9302c23cba59d483ea9d81
prerequisite-patch-id: 1713798d81d3140dea98cb980a4bac9aa22a3780
prerequisite-patch-id: ead1ebcb89468d700d8875693f405460d6d5a2c8
prerequisite-message-id: <20261124-b4-qca8k-two-byte-header-init-v1-1-c644025b69fa@gmail.com>
prerequisite-patch-id: 48d4c38319b803b22db91864e3321abdb6ab32b0
prerequisite-patch-id: 9d8ec97932a1c3a4c41dad64e27364d395e8821c
prerequisite-patch-id: 1b20a366220308b1864130aaef2a53816101f442
prerequisite-patch-id: 0a571205b2bb84488ae379a21ab734caa9cd15a6
prerequisite-patch-id: b08306581bf5dcd6d5543b00ee75105dc67c2355
prerequisite-patch-id: def18de6690ce96865075b4bb64cb8138b9f8cf7
prerequisite-patch-id: 6a6f50f93cfd1e3df21d74b525ecf4882e5c057b
prerequisite-patch-id: 8dd7f2d65905ec5c2dc0bc66b56301048436a6d1

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

