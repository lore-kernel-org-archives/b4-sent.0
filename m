From: Murad Dadashev <llamapersonaltv@gmail.com>
Subject: [PATCH 00/10] wifi: mt76: mt7603: add MT7603U USB support
Date: Fri, 27 Nov 2026 11:35:11 +0300
Message-Id: <20261127-mt7603u-v1-0-369bee9846f8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL9ACWsC/x3MQQ6DMAwEwK8gn2spCRBov4J6SKgBH0iRDRUS4
 u+EHme1uwcoCZPCqzhA6MfK35RhHwX0U0gjIX+ywRnnrXUNzmvjTblhNZCPz9jW1tSQ24vQwPv
 /qXtnx6CEUULqp3u/LboKhRnvHM7zAgQPgch5AAAA
X-Change-ID: 20261127-mt7603u-4fe6b9b85105
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>, Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Murad Dadashev <llamapersonaltv@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795768526; l=3763;
 i=llamapersonaltv@gmail.com; s=20261127; h=from:subject:message-id;
 bh=NxB3jZIIBFZlJM5Ywm3MKCBzXE8TLrTc5WJa1Gak8SU=;
 b=Eh5i5pjPN5Tgt4edY2Bc7IKJnKGiTkgkT8NYznZPneV+eqV7WWrCGbYZPwLm5zyGFJOPfUFRs
 cUEdjJ2nGBWAfaOHJ9zKHygrRJIO62TAR9QN4n9HKdolFO8tggR3+my
X-Developer-Key: i=llamapersonaltv@gmail.com; a=ed25519;
 pk=CeMIX207ioWRbMAA6A2GYgT+DpeVlKHVn7I0KjfHeCg=
X-Endpoint-Received: by B4 Relay for llamapersonaltv@gmail.com/20261127 with auth_id=1664
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for MT7603U USB 2.0 dongles (0e8d:7603) to the
mt7603 driver. It follows the layout of mt7615/mt7663u: the core code
moves into a new mt7603-common module, and the PCIe/SoC glue and the
new USB driver become separate modules on top of it.

Patches 1-7 prepare the shared code. Apart from the module split, the
changes that affect MT7603E and MT76x8 are:

- patch 4 only passes the TSSI enable flag to the firmware when the
  eFuse has a TSSI slope. The tested dongle sets the flag without any
  TSSI calibration, and the firmware stops transmitting in AP mode
  when TSSI is enabled.
- patch 5 adds set_antenna with separate TX and RX masks. The tested
  dongle loses about half of its two-stream frames on one TX chain;
  "iw phy phyX set antenna 1 3" keeps both RX chains and uses one TX
  stream.

Everything else that touches shared code only changes behaviour on
non-MMIO buses: register access over USB sleeps, so WTBL updates that
run in atomic context are deferred to work items, and PCIe-only setup
is skipped.

Patch 8 adds the MT7603 queue mapping to mt76-usb, patch 9 adds the
USB driver, and patch 10 adds AP mode, using an hrtimer computed from
the TSF instead of the pre-TBTT interrupt to refill the hardware beacon
and broadcast queues.

The device works with the existing mt7603_e2.bin firmware.

Tested on a 0e8d:7603 dongle on a Raspberry Pi 4, with the series
backported to 6.18:
- station mode with WPA2 on 2.4 GHz
- AP mode with hostapd and WPA2, about 56 Mbit/s in each direction
  with a single client at MCS 7

MT7603E and MT76x8 are build tested only, as I do not have that
hardware.

Claude Code was used throughout development of this series, for parts
of the code and changelogs, and for debugging. I reviewed the patches
and tested them on real hardware as described above.

---
Murad Dadashev (10):
      wifi: mt76: mt7603: split core code into mt7603-common
      wifi: mt76: mt7603: make mcu message helpers usable by other buses
      wifi: mt76: mt7603: set beacon and CAB queue index in the TXD directly
      wifi: mt76: mt7603: only enable TSSI with valid calibration data
      wifi: mt76: mt7603: allow configuring TX and RX antennas separately
      wifi: mt76: mt7603: defer WTBL updates when register access can sleep
      wifi: mt76: mt7603: skip PCIe specific setup on non-MMIO buses
      wifi: mt76: usb: add MT7603 queue mapping
      wifi: mt76: mt7603: add MT7603U USB support
      wifi: mt76: mt7603: add AP mode support for USB devices

 drivers/net/wireless/mediatek/mt76/mt7603/Kconfig  |  20 +-
 drivers/net/wireless/mediatek/mt76/mt7603/Makefile |  12 +-
 drivers/net/wireless/mediatek/mt76/mt7603/beacon.c | 217 +++++++++++--
 drivers/net/wireless/mediatek/mt76/mt7603/core.c   |   4 +
 drivers/net/wireless/mediatek/mt76/mt7603/dma.c    |   1 +
 drivers/net/wireless/mediatek/mt76/mt7603/eeprom.c |   1 +
 drivers/net/wireless/mediatek/mt76/mt7603/eeprom.h |   2 +
 drivers/net/wireless/mediatek/mt76/mt7603/init.c   |  40 ++-
 drivers/net/wireless/mediatek/mt76/mt7603/mac.c    | 154 ++++++++-
 drivers/net/wireless/mediatek/mt76/mt7603/main.c   | 103 ++++--
 drivers/net/wireless/mediatek/mt76/mt7603/mcu.c    |  37 ++-
 drivers/net/wireless/mediatek/mt76/mt7603/mt7603.h |  33 +-
 drivers/net/wireless/mediatek/mt76/mt7603/pci.c    |  28 ++
 drivers/net/wireless/mediatek/mt76/mt7603/usb.c    | 350 +++++++++++++++++++++
 drivers/net/wireless/mediatek/mt76/usb.c           |  17 +
 15 files changed, 929 insertions(+), 90 deletions(-)
---
base-commit: 18d0bedbb5f0538396cb7f763ed9cd1dd69c5b23
change-id: 20261127-mt7603u-4fe6b9b85105

Best regards,
-- 
Murad Dadashev <llamapersonaltv@gmail.com>

