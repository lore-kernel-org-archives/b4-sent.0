From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Subject: [PATCH 0/2] mtd: spi-nor: spansion: Cleanup S25FS256S
Date: Mon, 14 Sep 2026 13:50:35 +0900
Message-Id: <20260914-s25fs256s-fixup-v1-0-e94019455c1e@infineon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABt9p2oC/yWMyw5AMBBFf0VmrYk2lPoVsfCYMhZIB5GIfzdY3
 MXJzTkXMAZChjK6IOBBTMssoOMIurGZB1TUC4NJjE2c1opN5mWWladzX1Xv8iYr0lZ760CsNaA
 cX7Gqf+a9nbDb3gzc9wOC8PqWcwAAAA==
X-Change-ID: 20260911-s25fs256s-fixup-d97a584b1f69
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alexander Sverdlin <alex@sverdlin.org>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789361446; l=642;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=TMaKqT3wETJ/Kskr95mwiLzIopTwehVGMkfPEoOkcbI=;
 b=lnjrw4rRAXxTvWObos4WOftuLLGns+FPN0r0oNgviWqSVvkeAamdhX5h8yTGBAG69UfrtqT7K
 GNY4ZWuAS6ACCVH+jddxxNRdfala2L/j2JEO6K0MUSU5FCtV/hymeEJ
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series cleans up the S25FS256S entries in the Spansion ID table.
Remove the invalid s25fs256s0 entry and assign the existing S25FS-S
fixups to s25fs256s1.

Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
Takahiro Kuwano (2):
      mtd: spi-nor: spansion: Remove s25fs256s0
      mtd: spi-nor: spansion: Assign .fixups to s25fs256s1

 drivers/mtd/spi-nor/spansion.c | 8 +-------
 1 file changed, 1 insertion(+), 7 deletions(-)
---
base-commit: eb652d33da1b99c58a1465028b1336af5a3367c5
change-id: 20260911-s25fs256s-fixup-d97a584b1f69

Best regards,
--  
Takahiro Kuwano <takahiro.kuwano@infineon.com>

