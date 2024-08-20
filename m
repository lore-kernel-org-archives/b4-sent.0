From: Manas <manas18244@iiitd.ac.in>
Date: Tue, 20 Aug 2024 16:28:59 +0530
Subject: [PATCH] Fix missing description in struct member for journal_s
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240820-journal_s-missing-description-fix-v1-1-578b218e646d@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAPJ2xGYC/x2N0QrCMAxFf2Xk2UAXZBZ/RURmG2tEu5HoGJT9+
 4KP58K5p4GxChucuwbKi5hM1aE/dJCeYy2Mkp2BAh1DpICv6ad1fN8MP2ImtWBmSyrz1018yIp
 87ymmMOR4IvCfWdnnf+Ny3bYd+nV2xXMAAAA=
To: Theodore Ts'o <tytso@mit.edu>, Jan Kara <jack@suse.com>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-ext4@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724151549; l=849;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=w1+MRLpQlqWk+mrt0yJy8pQkb3cf8RgO7noQOxVKLCA=;
 b=nWb0FIVRoU7+fyLBkHM9tXMnfqm6Flnn2gHKxXt0krC45Pm5HUIqkb9w/Dc/PB/96rkrQ8ukC
 Xknx9ml/9kdAUdUZYkVn23a4SGYGVDZCfNXM7snM2cVA0QRXZqbO14A
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The struct member 'j_transaction_overhead_buffers' in 'journal_s' was
commented with partial name. 'make htmldocs' warned about this.

Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
 include/linux/jbd2.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/jbd2.h b/include/linux/jbd2.h
index 5157d92b6f23..17662eae408f 100644
--- a/include/linux/jbd2.h
+++ b/include/linux/jbd2.h
@@ -1086,7 +1086,7 @@ struct journal_s
 	int			j_revoke_records_per_block;
 
 	/**
-	 * @j_transaction_overhead:
+	 * @j_transaction_overhead_buffers:
 	 *
 	 * Number of blocks each transaction needs for its own bookkeeping
 	 */

---
base-commit: 47ac09b91befbb6a235ab620c32af719f8208399
change-id: 20240820-journal_s-missing-description-fix-eb128c06d872

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

