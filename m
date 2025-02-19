From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Wed, 19 Feb 2025 10:13:53 +0100
Subject: [PATCH] iommu/io-pgtable-dart: Only set subpage protection disable
 for DART 1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250219-dart2-no-sp-disable-v1-1-9f324cfa4e70@gmail.com>
X-B4-Tracking: v=1; b=H4sIANCgtWcC/x3MMQqAMAxA0atIZgM1oqJXEYfWRg1IlUZEkN7d4
 viG/19QjsIKQ/FC5FtUjpBRlQXMmw0ro/hsIEONoapHb+NFGA7UE72odTvjUjemo9k537eQyzP
 yIs9/HaeUPitxVDtlAAAA
X-Change-ID: 20250219-dart2-no-sp-disable-f35072cbbd96
To: Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Hector Martin <marcan@marcan.st>, Rob Herring <robh@kernel.org>, 
 Janne Grunau <j@jannau.net>
Cc: Joerg Roedel <jroedel@suse.de>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Asahi Lina <lina@asahilina.net>, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739956436; l=1398;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=4vIOKtPg+OtkD6k1fuo7D/3yWj1rRgyOMiGeGabXJoQ=;
 b=2XvYZiLPQ55QTshLqUD4aTt/pUSerHvszW6QhuxyTNjK/hq2NYquR+5dssye/dFu6aJEtq/su
 c/ZlgVVyC4ICgNDsQpVVlQtMaUH4ApO55G9hM21HQQvekVzMzpLohQw
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Asahi Lina <lina@asahilina.net>

Subpage protection can't be disabled on t6000-style darts,
as such the disable flag no longer applies, and probably
even affects something else.

Fixes: dc09fe1c5edd ("iommu/io-pgtable-dart: Add DART PTE support for t6000")
Signed-off-by: Asahi Lina <lina@asahilina.net>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/iommu/io-pgtable-dart.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/io-pgtable-dart.c b/drivers/iommu/io-pgtable-dart.c
index c004640640ee50d01dd54c38e89162c0fcb1988f..06aca9ab52f9a811a2608ae75155a36919799c74 100644
--- a/drivers/iommu/io-pgtable-dart.c
+++ b/drivers/iommu/io-pgtable-dart.c
@@ -135,7 +135,6 @@ static int dart_init_pte(struct dart_io_pgtable *data,
 	pte |= FIELD_PREP(APPLE_DART_PTE_SUBPAGE_START, 0);
 	pte |= FIELD_PREP(APPLE_DART_PTE_SUBPAGE_END, 0xfff);
 
-	pte |= APPLE_DART1_PTE_PROT_SP_DIS;
 	pte |= APPLE_DART_PTE_VALID;
 
 	for (i = 0; i < num_entries; i++)
@@ -211,6 +210,7 @@ static dart_iopte dart_prot_to_pte(struct dart_io_pgtable *data,
 	dart_iopte pte = 0;
 
 	if (data->iop.fmt == APPLE_DART) {
+		pte |= APPLE_DART1_PTE_PROT_SP_DIS;
 		if (!(prot & IOMMU_WRITE))
 			pte |= APPLE_DART1_PTE_PROT_NO_WRITE;
 		if (!(prot & IOMMU_READ))

---
base-commit: 2408a807bfc3f738850ef5ad5e3fd59d66168996
change-id: 20250219-dart2-no-sp-disable-f35072cbbd96

