From: Andrea Scian <andrea.scian@dave.eu>
Subject: [PATCH v2 0/2] PL353 SW ECC fixes
Date: Mon, 26 Jan 2026 17:58:54 +0100
Message-Id: <20260126-pl353-soft-ecc-support-v2-0-fcd74b6e955f@dave.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE6dd2kC/4WNSw7CIBRFt9K8sc/wsaU6ch+mAwKvlsQUApRoG
 vYudgMOz0nuuTskio4S3LodIhWXnF8biFMHZtHrk9DZxiCYGBgXHMNL9hKTnzOSMZi2EHzMqK4
 X4qR6qaSGNg6RZvc+wo+p8eJS9vFz/BT+s3+ThSNDxrQdiQ/MjvJudaEzbTDVWr/qLIodugAAA
 A==
X-Change-ID: 20260121-pl353-soft-ecc-support-794e1e75373a
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Michal Simek <michal.simek@amd.com>, Richard Weinberger <richard@nod.at>, 
 Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Amit Kumar <amit.kumar-mahapatra@amd.com>, 
 Andrea Scian <andrea.scian@dave.eu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769446742; l=1097;
 i=andrea.scian@dave.eu; s=20260121; h=from:subject:message-id;
 bh=hE+1gQasjcI7r0KGGKKj8zLyRMoa1nqwpr1aCZA23oc=;
 b=WJ1GJupjjxNlVNUqMfkuz90Qo9NplErbJdSx7B+8HX1zwQZpNhmteJsCtu/tBipLFec4WwGPs
 6nWxWcAOgdoCMyUyssaSrXrbQ3v+ZEN+lIrRpLItfukHzyErmSTm+vN
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
Changes in v2:
- change dev_info() into dev_dbg() to reduce messages
- Link to v1: https://lore.kernel.org/r/20260121-pl353-soft-ecc-support-v1-0-00ad8e160d83@dave.eu

---
Andrea Scian (2):
      mtd: rawnand: pl353: Fix software ECC support
      mtd: rawnand: pl353: Add message about ECC mode

 drivers/mtd/nand/raw/pl35x-nand-controller.c | 5 +++++
 1 file changed, 5 insertions(+)
---
base-commit: 24d479d26b25bce5faea3ddd9fa8f3a6c3129ea7
change-id: 20260121-pl353-soft-ecc-support-794e1e75373a

Best regards,
-- 
Andrea Scian <andrea.scian@dave.eu>

