From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v4 0/3] soc: mediatek: pwrap: mt6572 support + log level
 fixes
Date: Wed, 28 Oct 2026 12:37:49 +0200
Message-Id: <20261028-6572-pwrap-v4-0-1780c58d2097@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NTQ6CMBCG4auQrq2hPxRw5T2Mi1KmUqOUtFg1h
 LtbMEaILr9knncG5MEZ8GiXDMhBMN7YNg6+SZBqZHsCbOq4EU2pSHNCschyiru7kx3mqiSZYEr
 XlKEIOgfaPObY4fje/ladQfVTYbpojO+te87fApnuPmG+DAeCU1wXkElWKp2D3nfO9ra9SnPZK
 ntFUz3Qpc9WnkZfgSR1kRJVkOqvZ19f0vV/Fr3guSgrwbmQ6seP4/gCiA/uhDsBAAA=
X-Change-ID: 20260712-6572-pwrap-4c91563cfd23
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Flora Fu <flora.fu@mediatek.com>, Alexandre Mergnat <amergnat@baylibre.com>, 
 soc@kernel.org
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793183929; l=1859;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=rJSpPVEVPd0aF8LzZm8VDw4PaJi/3ZvOaWXpH7hlhls=;
 b=2v0NrIKTGEwX1A5XYHkOaJuwQKzzo2fV2ckeeI/DM5UdabuqfcoyLQJlDC0Ln0egcudaPuE8I
 vFTkIO6uwbxDfZGyHXcNxRykDseZXINxapSKlk8azImrEvgRDCa133R
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the mt6572 pwrap.

All known mt6572 devices use mt6323 PMIC, which is already supported
by the upstream drivers. mt6572 also shares SoC-specific init with
mt2701.

Patch 1 adds dt-bindings compatible.
Patch 2 fixes improper log levels in the driver, improving UX when
debugging.
Patch 3 adds mt6572 support.

Tested on various mt6572 devices without any failures.

Note: this series was reviewed since July, but still wasn't applied.
Pings and resend for MediaTek maintainer were unanswered. Could the SoC
maintainers consider picking this up directly? The series cleanly applies
to v7.3 tag.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v4:
- Send to soc@kernel.org, no other changes
- Link to v3: https://patch.msgid.link/20260924-6572-pwrap-v3-0-64769b6446ac@protonmail.com

Changes in v3:
- Pick up Krzysztof's tag
- No other changes, resend
- Link to v2: https://patch.msgid.link/20260715-6572-pwrap-v2-0-bea1d801c81b@protonmail.com

Changes in v2:
- Fix typo in patch 2 commit message ('Errors paths' -> 'Error paths')
- Drop unused registers in pwrap driver and use existing mt2701 array
- Also clarify mt6320 register usage
- Link to v1: https://patch.msgid.link/20260714-6572-pwrap-v1-0-d8e5a39cf7ef@protonmail.com

---
Roman Vivchar (3):
      dt-bindings: soc: mediatek: pwrap: add mt6572
      soc: mediatek: pwrap: use correct log level
      soc: mediatek: pwrap: add mt6572 support

 .../bindings/soc/mediatek/mediatek,pwrap.yaml      |  1 +
 drivers/soc/mediatek/mtk-pmic-wrap.c               | 71 +++++++++++++---------
 2 files changed, 44 insertions(+), 28 deletions(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260712-6572-pwrap-4c91563cfd23

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

