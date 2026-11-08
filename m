From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Subject: [PATCH v2 0/2] nfc: st21nfca: fix SE APDU request race condition
Date: Sun, 08 Nov 2026 21:41:36 +0000
Message-Id: <20261108-st21nfca-v2-v2-0-2d1efdf5ad58@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJDs8GoC/x3MQQqAIBBA0avIrBOcwUS6SrQIG2s2FhoShHdPW
 r7F/y8UzsIFJvVC5ipFztRBg4JwrGlnLVs3kCGHaLwuN2GKYdWVdLRhjN4hW3TQiytzlOe/zUt
 rH66tJUVdAAAA
To: joasantonio108@gmail.com, linux-nfc@lists.01.org
Cc: horms@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794174096; l=1341;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=ebXR0iQXcJSvVd4YPxZu8WAcSHjyWGZ3ferWgFqe25E=;
 b=AvZ/pkrq2PTfeE8DSmydXS+77LFTvw4CvfbDTsom12NZoBpfW4HXWXDMrXevRfH3wODjcx0J9
 GwHkTd6GTDhCVuvUg5nDJhktdZH45a1whpS2WUeeo+1ZFY1ys4zKwq4
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a race between the timeout work handler and the EVT_TRANSMIT_DATA
event handler that can lead to a double invocation of the SE APDU
callback, resulting in use-after-free or double-free of the callback
context.

Split into two patches:
  1/2: Add a spinlock to serialize access to bwi_active, cb, and
       cb_context across the three concurrent paths.
  2/2: Use the lock to guard against double completion and reject
       overlapping requests.

Changes since v1:
  - Use spinlock instead of plain bwi_active flag checks (Simon Horman)
  - Split into 2-patch series: locking infrastructure + completion fix
  - Move bwi_active = true before mod_timer()
  - Copy cb/cb_context under lock, invoke after releasing
  - Reject overlapping se_io requests with -EBUSY
  - Drop Assisted-by trailer

---
Joas Antonio dos Santos (2):
      nfc: st21nfca: add spinlock to serialize SE APDU request state
      nfc: st21nfca: prevent double completion of SE APDU request

 drivers/nfc/st21nfca/se.c       | 36 ++++++++++++++++++++++++++++++++----
 drivers/nfc/st21nfca/st21nfca.h |  2 ++
 2 files changed, 34 insertions(+), 4 deletions(-)
---
base-commit: 602042bf29f6efde39cfb5fdd9289bf4854bc0c5
change-id: 20261108-st21nfca-v2-f4c5f861e416

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

