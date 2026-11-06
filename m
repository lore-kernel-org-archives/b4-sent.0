From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH 0/2] wifi: ath: simplify copying a peer's PPE thresholds
Date: Fri, 06 Nov 2026 12:48:25 -0600
Message-Id: <20261106-ath-peer-ppe-thres-loop-v1-0-f6bb5fe9ffb3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPkg7moC/yXMQQrCMBBG4auUWTvQBAziVcRFG3/NiDTDTBSh9
 O5GXX6L91ZymMDpOKxkeIlLXTrCbqBcpuUGlks3xTGmEMbEUyusgLEquBWD86NW5Yx9jnNEOiB
 Qr9VwlffvfDr/7c/5jty+O9q2Dx44q7l7AAAA
X-Change-ID: 20261106-ath-peer-ppe-thres-loop-ce5c2b2e68e1
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Rameshkumar Sundaram <rameshkumar.sundaram@oss.qualcomm.com>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 ath12k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793990906; l=1038;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=BZ5UT6GcKMGhEPdLdsmXEAyHHHroZPYfl6Q6xV+s1sk=;
 b=I6tQcvhYxaQai7bBUx4Hd+v1uXiA6kOGJUQgRMMpWBIRVkLVvt251Nq2uCFN4vH9ElbRhmOM8
 5QePBEhVxl3COlRvD5hSjzIlnM2C7oZ6fQS/vxMx3JlHAe6lXx9a2/W
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rameshkumar suggested this while reviewing the PPE threshold bit-order
fix [1]: the loop that copies a peer's PPE thresholds into the WMI
layout shifts each bit in from the top, where it can put it in place.
ath11k and ath12k carry the same loop, so one patch each. No functional
change; the patches don't depend on the bit-order series.

The patches, this letter and the equivalence test were written with
Claude, an AI coding assistant.

[1] https://lore.kernel.org/all/b60c4c56-483b-406e-92ab-643b0fdf2dc8@oss.qualcomm.com/

---
Christopher Griffin (2):
      wifi: ath11k: simplify copying a peer's PPE thresholds
      wifi: ath12k: simplify copying a peer's PPE thresholds

 drivers/net/wireless/ath/ath11k/mac.c | 3 +--
 drivers/net/wireless/ath/ath12k/mac.c | 3 +--
 2 files changed, 2 insertions(+), 4 deletions(-)
---
base-commit: 5c8eab13e391aaabd5a1ad58f3ee4bb10ce7573e
change-id: 20261106-ath-peer-ppe-thres-loop-ce5c2b2e68e1

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

