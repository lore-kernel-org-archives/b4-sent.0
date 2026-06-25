From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH 0/2] wifi: mt76: bound the device-reported EEPROM address
Date: Thu, 25 Jun 2026 07:10:25 -0500
Message-Id: <20260625-b4-disp-16f99062-v1-0-aee52ecf61b9@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALEaPWoC/x2MQQqAMAzAviI9W9iGVuZXxIOzVXuZsoEIsr87P
 CaQvJAlqWQYmxeS3Jr1jBVs28B6LHEXVK4Mzjgy5HoMHbLmCy1t3leDhpkseQ5+CFCzK8mmz7+
 c5lI+pfRdiGIAAAA=
To: Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>, Felix Fietkau <nbd@nbd.name>
Cc: Sean Wang <sean.wang@mediatek.com>, linux-mediatek@lists.infradead.org, 
 Shayne Chen <shayne.chen@mediatek.com>, linux-wireless@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782389425; l=1450;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=aEqGl/t2oeE3z5GCNLJYJ3vk5L2f28hG2tdsN4d5BLI=;
 b=WbuVeuUOSSAzABLV05jlMQnSZpj/raKBFDPyhwD8be073heZMHbwiVoYI6fAQpTaqNsazavWJ
 23UyCJqyU2hAq4LnYOQK+5yYicaiaORXEMLHfn0uQiomcyovRq4UWmY
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both mt76 get_eeprom handlers copy a device-reported EFUSE block into
dev->mt76.eeprom.data at an offset taken from the MCU response (res->addr /
event->addr, a device-controlled __le32). They clamp the copy length but
never the destination offset, so an adapter that reports an out-of-range
address drives an out-of-bounds write past eeprom.data -- 16 bytes on mt7915,
up to 1024 on mt7996. Both patches reject such an address before deriving the
pointer; a device that echoes the requested in-bounds offset is unaffected.

It is adapter-side only -- there is no unprivileged user path -- so this
hardens against a malicious or compromised device, not a remote attacker.

An out-of-tree KASAN module that reproduces each handler's destination
arithmetic faults the unpatched path (slab-out-of-bounds write past
eeprom.data) and runs clean both with the bound and on an in-range control.

---
Bryam Vargas (2):
      wifi: mt76: mt7915: bound the device EEPROM address before the EFUSE copy
      wifi: mt76: mt7996: bound the device EEPROM address before the EFUSE copy

 drivers/net/wireless/mediatek/mt76/mt7915/mcu.c | 11 +++++++++--
 drivers/net/wireless/mediatek/mt76/mt7996/mcu.c |  9 ++++++++-
 2 files changed, 17 insertions(+), 3 deletions(-)
---
base-commit: 502d801f0ab03e4f32f9a33d203154ce84887921
change-id: 20260625-b4-disp-16f99062-0dd6169db97b

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

