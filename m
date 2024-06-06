From: Nikita Shubin <n.shubin@yadro.com>
Date: Thu, 06 Jun 2024 11:15:19 +0300
Subject: [PATCH] ntb: intel: Fix using link status DB's
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-ntb_intel_db_fix-v1-1-ba9033aea289@yadro.com>
X-B4-Tracking: v=1; b=H4sIABZwYWYC/x2MWwqAIBAAryL7nWAWUl0lQnystRAWKhFEd0/6n
 IGZBzImwgwTeyDhRZmOWKFtGLjNxBU5+cogheyFEorHYjXFgrv2Vge6ueiUHMdgrOsHqNmZsOp
 /OS/v+wE9gs7NYgAAAA==
To: Dave Jiang <dave.jiang@intel.com>, Jon Mason <jdmason@kudzu.us>, 
 Allen Hubbe <allenbh@gmail.com>
Cc: Nikita Shubin <nikita.shubin@maquefel.me>, ntb@lists.linux.dev, 
 linux-kernel@vger.kernel.org, linux@yadro.com, 
 Nikita Shubin <n.shubin@yadro.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717661730; l=1211;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=m6Ej8L6+xmXOl3RZbV82ktzzdYahkk4scP8S6bypgnI=;
 b=+HlydAPVVu4+ZMywh4SWhA+S6XYV8sVahCZZ6LzcQ8yNPDKz7VT9FpR+U826CFRkkiBi9zeM3ILx
 tuiY46THD8IhJfZQ3NGDixQ4ib+QBUIj5WD61znSyHouI32j9RiA
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure we are not using DB's which were remapped for link status.

Fixes: f6e51c354b60 ("ntb: intel: split out the gen3 code")
Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
Hello Dave, sending a patch as planned.

Thank you for looking into this!

Link: https://lore.kernel.org/all/686c55cc658564e8f37147e0d6d5ab62bb8372af.camel@maquefel.me/
---
 drivers/ntb/hw/intel/ntb_hw_gen3.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/ntb/hw/intel/ntb_hw_gen3.c b/drivers/ntb/hw/intel/ntb_hw_gen3.c
index ffcfc3e02c35..a5aa96a31f4a 100644
--- a/drivers/ntb/hw/intel/ntb_hw_gen3.c
+++ b/drivers/ntb/hw/intel/ntb_hw_gen3.c
@@ -215,6 +215,9 @@ static int gen3_init_ntb(struct intel_ntb_dev *ndev)
 	}
 
 	ndev->db_valid_mask = BIT_ULL(ndev->db_count) - 1;
+	/* Make sure we are not using DB's used for link status */
+	if (ndev->hwerr_flags & NTB_HWERR_MSIX_VECTOR32_BAD)
+		ndev->db_valid_mask &= ~ndev->db_link_mask;
 
 	ndev->reg->db_iowrite(ndev->db_valid_mask,
 			      ndev->self_mmio +

---
base-commit: 2df0193e62cf887f373995fb8a91068562784adc
change-id: 20240606-ntb_intel_db_fix-036299fabc48

Best regards,
-- 
Nikita Shubin <n.shubin@yadro.com>

