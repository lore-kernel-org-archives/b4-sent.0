From: Peter-Simon Dieterich <peter-simon.dieterich@vaillant-group.com>
Subject: [PATCH 0/2] mtd: rawnand: Handle GigaDevice chips behind the ESMT
 manufacturer ID
Date: Thu, 17 Sep 2026 15:00:41 +0200
Message-Id: <20260917-esmt-gd9fu2g8f3a-v1-0-577c0ab2d31a@vaillant-group.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHnkq2oC/yXMQQqEMAxA0atI1hbSKqJzlcFF1bRG0BkaK4J4d
 6su3+L/A4QCk8AnOyDQxsK/JUHnGfSjXTwpHpLBoKmwNqhI5lX5oXHR+NoVVjVlp11FGrGwkLJ
 /IMf7s/y2ryV2E/Xr/YHzvACsPd/+dAAAAA==
X-Change-ID: 20260820-esmt-gd9fu2g8f3a-94b1f6e1003a
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Peter-Simon Dieterich <peter-simon.dieterich@vaillant-group.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789650050; l=1814;
 i=peter-simon.dieterich@vaillant-group.com; s=20260820;
 h=from:subject:message-id; bh=ST6lkf8zWnv1Bb1/dVgKbAOWbpFORRupmi8n5QqXhzg=;
 b=v8R4RThorGStiRkYuqiy4vVHp2R3EYd1tnzChzEJWSj/iyUf1N530ytqr6Kzl4/5Gzj+SBMGs
 ExPLfO26ZG8C66WNLgYeqkRM0iUeYbWEH7rxbWUuKgU5Mu+4jS6HEzv
X-Developer-Key: i=peter-simon.dieterich@vaillant-group.com; a=ed25519;
 pk=YI8VL1pBCnAIu0GVWI3a6qn/SG0pMQhm9n/RZTI5KZg=
X-Endpoint-Received: by B4 Relay for peter-simon.dieterich@vaillant-group.com/20260820 with auth_id=965
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

JEDEC manufacturer ID 0xc8 is shared between ESMT and GigaDevice, so
GigaDevice raw NAND chips are detected as ESMT and handled by
nand_esmt.c. This series deals with a GigaDevice part that ends up there.

Patch 1 works around a broken timing mode feature on the GD9FU2G8F3A:
the parameter page advertises SET/GET_FEATURES support, but
GET_FEATURES(TIMING_MODE) does not report the mode that was written, so
the core does not see its selection acknowledged and falls back to timing
mode 0. GigaDevice confirmed the chip is compatible with every timing
mode it advertises and that SET_FEATURES is not required to enter them,
so the feature is unflagged for this model and only the host side is
configured. This mirrors the existing handling of the Macronix MX30LF AC
series in nand_macronix.c.

Patch 2 is cosmetic: it renames the manufacturer entry to
"ESMT/GigaDevice" and documents the ID collision, so a GigaDevice part
is no longer reported as ESMT at detection time. It is independent of
patch 1 and can be dropped or deferred without affecting the fix.

Tested on an i.MX6ULL board using gpmi-nand with a GD9FU2G8F3A.

Signed-off-by: Peter-Simon Dieterich <peter-simon.dieterich@vaillant-group.com>
---
Peter-Simon Dieterich (2):
      mtd: rawnand: esmt: Disable broken timings feature on GD9FU2G8F3A
      mtd: rawnand: Reflect that ESMT and GigaDevice share ID 0xc8

 drivers/mtd/nand/raw/internals.h |  1 +
 drivers/mtd/nand/raw/nand_esmt.c | 34 ++++++++++++++++++++++++++++++++++
 drivers/mtd/nand/raw/nand_ids.c  |  2 +-
 3 files changed, 36 insertions(+), 1 deletion(-)
---
base-commit: 7e874b1750a40f3dc9a629aeb72eba09c77f77e9
change-id: 20260820-esmt-gd9fu2g8f3a-94b1f6e1003a

Best regards,
--  
Peter-Simon Dieterich <peter-simon.dieterich@vaillant-group.com>

