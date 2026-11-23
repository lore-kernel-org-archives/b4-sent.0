From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH net-next 0/3] Add Cortina Systems CS7542 MDIO controller
 support
Date: Mon, 23 Nov 2026 21:41:41 +0300
Message-Id: <20261123-b4-cs7542-mdio-v1-0-626d0a0e3b4d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6Xs2QUTt0b8FenBpk9dwVSyUQql/
 25sj8MwM5MhK4zOzUwZXzUdUwW3ayg+rukO1qEy+b0/OucP3AtHC614fg06MqIIQhtw8kI1emf
 cdFqHF0oonDAV6jZjn/6JWP4/WpYfXr0PBXwAAAA=
X-Change-ID: 20261123-b4-cs7542-mdio-ec44e757e824
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459301; l=2489;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=6YV4xgMIs4F2rWcDax4Fkd9ZfJOEDWX72JDkQTTmzak=;
 b=nh0g6b5cnQAQ47kWGHhGbvhaB2mYIbn/Goaf+gooGXuwqoPg6zc6DooAN6xabg14v3j7DKh5X
 TeV55fea8DlBUjg0F4gAlql2TaE2lJpcGIyKAsC21GBZPj3WIqI9G4N
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an independent Clause 22 MDIO driver for the CS7542 controller used by
Securifi Almond+. The series is based on Linux v7.4-rc4 and has no platform
or ARCH_CORTINA_ACCESS dependency. It is intended for net-next.

Enable manual operation while retaining the prescaler initialized by
firmware and all unrelated configuration bits. The factory bootloader and
vendor driver set the prescaler to 0x20 on this board; the source clock and
exact divisor formula are not documented by the material available here.
Accordingly, this version does not advertise programmable clock-frequency
or preamble suppression. It does not claim Clause 45 support.

Poll short transfers with bounded microsecond waits. A timed-out transfer
remains pending until completion; a later operation cannot replace its
address and consume a stale completion. Device-managed bus allocation and
registration handle probe cleanup and removal.

Validation:
- Full independent ARM vmlinux and modules builds, driver both =y and =m,
  COMPILE_TEST=n, without the platform series.
- Binding schema/example and strict source checkpatch pass.
- Actual read/write/wait functions: 5125 address, data, timeout and recovery
  cases with mocked MMIO under UBSAN.
- Linux 7.4-rc4 booted in RAM on Almond+. Read PHY ID 004d:d036, performed
  an unchanged-value advertisement write/readback and preserved CFG=00200001.
- A RAM-only test slowed the prescaler to induce a real -ETIMEDOUT, restored
  the original setting and verified both PHY ID registers again. All hardware
  checks passed and the board returned to installed OpenWrt 6.18.64.

No kernel image was installed by these tests. The hardware-test helper and
board integration are not part of the series.

---
Fil Dunsky (3):
      dt-bindings: net: Add Cortina CS7542 MDIO controller
      net: mdio: Add Cortina CS7542 bus controller
      MAINTAINERS: Add Cortina CS7542 MDIO controller entry

 .../bindings/net/cortina,cs7542-mdio.yaml          |  48 ++++++++
 MAINTAINERS                                        |   7 ++
 drivers/net/mdio/Kconfig                           |  13 ++
 drivers/net/mdio/Makefile                          |   1 +
 drivers/net/mdio/mdio-cs75xx.c                     | 136 +++++++++++++++++++++
 5 files changed, 205 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-mdio-ec44e757e824

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

