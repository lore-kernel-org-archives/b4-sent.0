From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH v3 0/3] clk: renesas: r9a06g032: Add reset controller to
 clear resets for mii converter
Date: Wed, 25 Nov 2026 07:53:42 -0800
Message-Id: <20261125-rzn1-miic-resets-v3-0-f25a4b656d71@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNTQ6CMBCG4auQrq3pDPKjK+9hXLR1kEmAmpY0K
 uHuFtyYqMv3S+aZSQTyTEEcskl4ihzYDSnyTSZsq4crSb6kFqiwBIWV9M8BZM9spadAY5B1ruo
 CCq3RKpHObp4avq/k6Zy65TA6/1g/RFjWNwaw/8YiSCUbIkJjsDZmd/TUsTYdWTeM3nVha10vF
 jfih4Xqh4WLBbbRZVWXUJg/1jzPL0cR4O0HAQAA
X-Change-ID: 20261027-rzn1-miic-resets-8308515aa2c0
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Kyle Hendry <khendry@reliablecontrols.com>, 
 Wolfram Sang <wsa+renesas@sang-engineering.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795622048; l=1905;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=qttgeoFz50m6xocphqe7rfGCN4ggYj2FjV0TRRZ7opM=;
 b=oEMenEM8aLeiWc1ZnKj1lpXCi6n9l26UZDFUGoSR/RsCpTBs7G3WUbzEKVlbTL44Q+GENko+N
 14R9dmzhtLHCwC+EnrbsNhnlozsGAk2ZD9B3W0bJ3WiyffLtQ27LA+H
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the rzn1, there are two resets for the mii converter in the system
controller. If they are not cleared by the bootloader then the kernel needs
to do it. 

To handle this, I've added a reset controller interface to the clock
driver so the miic driver can deassert them.

---
Changes in v3:
- Move reset_controller_dev to end of priv structure
- Index resets from 0
- Link to v2: https://lore.kernel.org/r/20261120-rzn1-miic-resets-v2-0-f1cfa678615b@reliablecontrols.com

Changes in v2:
- Drop patches for pcs-rzn1-miic to be submitted separately to netdev
- Add reset_controller_dev to r9a06g032_priv fix build error
- Use designated initializers for the reset bit definitions
- Change macro for getting priv data to static inline
- Drop unnecessary reset from controller ops
- Remove debugging argument from r9a06g032_reset_set
- Remove configuration of of_reset_n_cells 
- Add #reset-cells to required and example in schema
- Make r9a06g032_reset_status correctly return the active low status
- Move reset controller register earlier in probe to better handle failure
- Link to v1: https://lore.kernel.org/r/20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com

---
Kyle Hendry (3):
      dt-bindings: clock: r9a06g032-sysctrl: Document reset cells
      clk: renesas: r9a06g032: Add reset controller
      ARM: dts: renesas: r9a06g032: Add #reset-cells to system controller node

 .../bindings/clock/renesas,r9a06g032-sysctrl.yaml  |  5 ++
 arch/arm/boot/dts/renesas/r9a06g032.dtsi           |  1 +
 drivers/clk/renesas/r9a06g032-clocks.c             | 59 ++++++++++++++++++++++
 include/dt-bindings/clock/r9a06g032-sysctrl.h      |  3 ++
 4 files changed, 68 insertions(+)
---
base-commit: 7d650c5db382c8226965b01a31e16fcf2df1d096
change-id: 20261027-rzn1-miic-resets-8308515aa2c0

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

