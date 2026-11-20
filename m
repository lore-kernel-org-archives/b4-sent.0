From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH v2 0/3] clk: renesas: r9a06g032: Add reset controller to
 clear resets for mii converter
Date: Fri, 20 Nov 2026 13:16:51 -0800
Message-Id: <20261120-rzn1-miic-resets-v2-0-f1cfa678615b@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNQQ6CMBBFr0JmbU2niqIr72FYtHWQSaA1U0JU0
 rtbcenyveS/v0AiYUpwrhYQmjlxDAXMpgLf23AnxbfCYLQ5oDZHJe+AamT2SijRlFSz002NtbX
 Gayizh1DHzzV5bQv3nKYor/Vhxq/9xRBP/7EZlVYdERnnTOPc/iI0sHUD+RgmiUPa+jhCm3P+A
 Om+Fzy7AAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795209454; l=1704;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=64flA37FYq7GX7EUX0roYoz1X+pA+V7pvD9Hrm3PL+g=;
 b=KRB/7zyk+sfhm6s21ea85KRVqZs2zvpIpkIF1zdDNcSYpDc0JgzTV4j3XneKsMkesYau7m312
 2RfhwsSykP7BNWLMwZxBRHd8XuwvRLHWp62i76L/oY+61SUOa/mROQH
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
base-commit: 662377fd1bb1d7cf4e97d312255fed868f56342d
change-id: 20261027-rzn1-miic-resets-8308515aa2c0

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

