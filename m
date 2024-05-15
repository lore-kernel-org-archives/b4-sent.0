From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH v2 0/3] Bluetooth: hci_bcm4377 fixes
Date: Wed, 15 May 2024 18:15:01 +0000
Message-Id: <20240515-btfix-msgid-v2-0-bb06b9ecb6d1@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKX7RGYC/22MQQ7CIBBFr9LM2jGAVcSV9zBdgEzbWUgbIETTc
 Hexa5fv/7y3QaLIlODWbRCpcOIlNFCHDp6zDRMh+8aghOrFWSp0eeQ3vtLEHr2+CGWs9kZqaMY
 aqZ177TE0njnlJX72eJG/9X+nSBRonXTenK5Wj/09FQorZYpHTwWGWusXkPK1faoAAAA=
To: Hector Martin <marcan@marcan.st>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>, stable@vger.kernel.org, 
 Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715796911; l=1561;
 i=sven@svenpeter.dev; s=20240512; h=from:subject:message-id;
 bh=PGURJy5MHlm6XUXszUKhFzRvUcIs8Hj8iEYpUECP0Y0=;
 b=rWKwkEblh6RdLBuKAhQAswaTPpV6aL8Wlnu8pLb0phkNIIfvgOLdAMCME/FjRPa1SgQyUa4Vu
 txh3IgfhG9KCoQ9FpGoeKnyAJ6Htc4DOcOoVEJvVsMLLMP30Ve5yNKd
X-Developer-Key: i=sven@svenpeter.dev; a=ed25519;
 pk=jIiCK29HFM4fFOT2YTiA6N+4N7W+xZYQDGiO0E37bNU=
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/20240512 with auth_id=159
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

There are just two minor fixes from Hector that we've been carrying downstream
for a while now. One increases the timeout while waiting for the firmware to
boot which is optional for the controller already supported upstream but
required for a newer 4388 board for which we'll also submit support soon.
It also fixes the units for the timeouts which is why I've already included it
here. The other one fixes a call to bitmap_release_region where we only wanted
to release a single bit but are actually releasing much more.

Best,

Sven

To: Hector Martin <marcan@marcan.st>
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>
To: Marcel Holtmann <marcel@holtmann.org>
To: Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-bluetooth@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Sven Peter <sven@svenpeter.dev>

Changes in v2:
- split the timeout commit into two
- collect Neal's tag
- Link to v1: https://lore.kernel.org/r/20240512-btfix-msgid-v1-0-ab1bd938a7f4@svenpeter.dev

---
Hector Martin (2):
      Bluetooth: hci_bcm4377: Increase boot timeout
      Bluetooth: hci_bcm4377: Fix msgid release

Sven Peter (1):
      Bluetooth: hci_bcm4377: Use correct unit for timeouts

 drivers/bluetooth/hci_bcm4377.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)
---
base-commit: cf87f46fd34d6c19283d9625a7822f20d90b64a4
change-id: 20240512-btfix-msgid-d76029a7d917

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

