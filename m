From: Christopher Griffin <christophergriffin05@gmail.com>
Subject: [PATCH v2 0/2] wifi: ath: simplify copying a peer's PPE thresholds
Date: Tue, 10 Nov 2026 08:37:51 -0600
Message-Id: <20261110-ath-peer-ppe-thres-loop-v2-0-fced87507920@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEAs82oC/4WNQQ6CMBBFr0Jm7RhaQ6OuvIdhQeuUjgHatJVoS
 O8u4AFcvuT99xdIFJkSXKsFIs2c2E8ryEMFxnVTT8iPlUHWUglRK+yyw0AUMQTC7CIlHLwPaKg
 xUktSZxKwrkMky++9fG9/nF76SSZvuc1wnLKPn/16Fpv3/2UWWKNVWjeWLtbq060fOx6Oxo/Ql
 lK+7y0Yc9AAAAA=
X-Change-ID: 20261106-ath-peer-ppe-thres-loop-ce5c2b2e68e1
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Rameshkumar Sundaram <rameshkumar.sundaram@oss.qualcomm.com>, 
 Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 ath12k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794321472; l=1569;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=vBZaf4TEYAxqUGlg0dDE1mpIQ9acO6vuybyJLRWS5LY=;
 b=K3soglbfb5eqqDMtq403mFJS21XB1PNr0p0+UHvGArEQGIwyy5Q0ExUHlR90T7sYQW/hT+d0v
 cEM9AiHHq3yCORTiPfc/yPhD+4WLjFX3VRYXP7sbvfUr8IkHKCoSkeq
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rameshkumar suggested this while reviewing the PPE threshold bit-order
fix [1]: the loop that copies a peer's PPE thresholds into the WMI
layout shifts each bit in from the top, where it can put it in place.
ath11k and ath12k carry the same loop, so one patch each. No functional
change; the patches don't depend on the bit-order series.

Compile tested only (W=1, both drivers). A userspace copy of the old
and the new loop gives the same output for every 6-bit value in every
RU slot.

The patches, this letter and that test were written with Claude, an AI
coding assistant.

[1] https://lore.kernel.org/all/b60c4c56-483b-406e-92ab-643b0fdf2dc8@oss.qualcomm.com/

---
Changes in v2:
- Dropped the paragraph about the equivalence test from both changelogs
  (Rameshkumar).
- Kept the one-line note on AI use in the changelogs:
  Documentation/process/generated-content.rst asks for it in changelogs
  and cover letters.
- Rebased on ath-next.
- Link to v1: https://patch.msgid.link/20261106-ath-peer-ppe-thres-loop-v1-0-f6bb5fe9ffb3@gmail.com

---
Christopher Griffin (2):
      wifi: ath11k: simplify copying a peer's PPE thresholds
      wifi: ath12k: simplify copying a peer's PPE thresholds

 drivers/net/wireless/ath/ath11k/mac.c | 3 +--
 drivers/net/wireless/ath/ath12k/mac.c | 3 +--
 2 files changed, 2 insertions(+), 4 deletions(-)
---
base-commit: d0fbb39d65dc9dcb4175fa6b23e473dec3670f4d
change-id: 20261106-ath-peer-ppe-thres-loop-ce5c2b2e68e1

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

