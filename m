From: Andrea Scian <andrea.scian@dave.eu>
Subject: [PATCH v3 0/2] PL353 SW ECC fixes
Date: Wed, 04 Feb 2026 18:41:43 +0100
Message-Id: <20260204-pl353-soft-ecc-support-v3-0-fd8ee7595cc1@dave.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANeEg2kC/4XNTQ7CIBCG4as0rMXwU6B15T2MC4TBkphCoCWap
 neXdqMb4/L9knlmQRmSh4xOzYISFJ99GGvwQ4PMoMc7YG9rI0aYJJRRHB9ccJyDmzAYg/McY0g
 TVn0LFJTgimtUj2MC5587fLnWHnyeQnrtfwrd1r9koZhgQrTtgEpiO362usARZrSBhX0j8ifCK
 uKMVe1NQi+E+yDrur4B0s7gtP8AAAA=
X-Change-ID: 20260121-pl353-soft-ecc-support-794e1e75373a
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Michal Simek <michal.simek@amd.com>, Richard Weinberger <richard@nod.at>, 
 Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Andrea Scian <andrea.scian@dave.eu>, stable@kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770226919; l=1281;
 i=andrea.scian@dave.eu; s=20260121; h=from:subject:message-id;
 bh=SN/EnI3gRH5EgPtrtzgUHt1OXyTJ4FMI4Zj0DQ7Bzfg=;
 b=alB+oSyKR61RnSRxCpvkButoFr42kGODXraEw9NXPMkSn9ky/J95WooC/VZ1ffU+01w3Og2qv
 caVYdgr2mocCE6UfVoHDud+zpId8MmoiZVqMtglBoEdOg5GzztzauH3
X-Developer-Key: i=andrea.scian@dave.eu; a=ed25519;
 pk=PMQL72nEsyoiJCobnq0uEXwUFpVmkwoWIx317WvaQOU=
X-Endpoint-Received: by B4 Relay for andrea.scian@dave.eu/20260121 with auth_id=613
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PL353 has some known errata with its ECC implementation and it may be
useful to switch to software ECC, to avoid issue with this.

On-die ECC is already supported (while I didn't test it) but when
enabling SW ECC we get operation-not-supported error during page write
(page read already work correctly)

IMHO it's enough to have 1-bit Hamming ECC correction, because this is
the only one supported on PL353, but this might be a wrong assumption.

This has been tested with nandflipbits and mtd_nandbiterrs

---
Changes in v3:
- remove wrong SW ECC algo selection
- add Fixes and CC to stable
- Link to v2: https://lore.kernel.org/r/20260126-pl353-soft-ecc-support-v2-0-fcd74b6e955f@dave.eu

Changes in v2:
- change dev_info() into dev_dbg() to reduce messages
- Link to v1: https://lore.kernel.org/r/20260121-pl353-soft-ecc-support-v1-0-00ad8e160d83@dave.eu

---
Andrea Scian (2):
      mtd: rawnand: pl353: Fix software ECC support
      mtd: rawnand: pl353: Add message about ECC mode

 drivers/mtd/nand/raw/pl35x-nand-controller.c | 4 ++++
 1 file changed, 4 insertions(+)
---
base-commit: 24d479d26b25bce5faea3ddd9fa8f3a6c3129ea7
change-id: 20260121-pl353-soft-ecc-support-794e1e75373a

Best regards,
-- 
Andrea Scian <andrea.scian@dave.eu>

