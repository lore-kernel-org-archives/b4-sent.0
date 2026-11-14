From: Izaac Chong <izaacchong934@gmail.com>
Date: Sat, 14 Nov 2026 08:33:43 +0800
Subject: [PATCH] scsi: fnic: Fix typo in kmem_cache creation error message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-fnic-typo-v1-1-a9f70c9c4a6b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMQQqAIBCF4avErBNSpKirRIvSqaaFilYU4t2z2
 jz44PFHCOgJA3RFBI8nBbImg5cFqHU0CzLS2SAqUXPOJZsNKbbfzrJGylYLzCtHyH/ncabra/X
 D73BMG6r9DUBKD0aIWzVtAAAA
X-Change-ID: 20261114-fnic-typo-7449d2e4494a
To: Satish Kharat <satishkh@cisco.com>, 
 Sesidhar Baddela <sebaddel@cisco.com>, 
 Karan Tilak Kumar <kartilak@cisco.com>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Izaac Chong <izaacchong934@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794616426; l=1054;
 i=izaacchong934@gmail.com; s=20261114; h=from:subject:message-id;
 bh=aK+ZdndpFxlDmt74J7lkKpKkjfqPLloO4qhOgeRfRYc=;
 b=LvzW5ATwEWwcdBjbRpA0qBV54BEsyR5iA+ZPus6w8l0rW8U5dO8bv+a4DfuZ2yBioLUnSfnjc
 ulXpHC+SWVkA2z0qCt2iJbAxX2ipsmnkuEpjGnLDtKZCApPkENof9AW
X-Developer-Key: i=izaacchong934@gmail.com; a=ed25519;
 pk=IFfOWcK2ZRkDtCqaNggolAwpvIidYMt3Oar3NEnvqzY=
X-Endpoint-Received: by B4 Relay for izaacchong934@gmail.com/20261114 with auth_id=1518
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The error printed when the fdls_frame_recv kmem_cache cannot be
created says "cach" instead of "cache". Fix the spelling so the
message matches the other cache creation errors in fnic_init_module().

Signed-off-by: Izaac Chong <izaacchong934@gmail.com>
---
 drivers/scsi/fnic/fnic_main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/scsi/fnic/fnic_main.c b/drivers/scsi/fnic/fnic_main.c
index a19c0b0d8..10c2de746 100644
--- a/drivers/scsi/fnic/fnic_main.c
+++ b/drivers/scsi/fnic/fnic_main.c
@@ -1460,7 +1460,7 @@ static int __init fnic_init_module(void)
 						  FNIC_FRAME_HT_ROOM,
 						  0, SLAB_HWCACHE_ALIGN, NULL);
 	if (!fdls_frame_recv_cache) {
-		pr_err("fnic fdls frame recv cach create failed\n");
+		pr_err("fnic fdls frame recv cache create failed\n");
 		err = -ENOMEM;
 		goto err_create_fdls_frame_recv_cache;
 	}

---
base-commit: 97d73c8251226cf27cc6656b4c542869bb8c69fa
change-id: 20261114-fnic-typo-7449d2e4494a

Best regards,
--  
Izaac Chong <izaacchong934@gmail.com>

