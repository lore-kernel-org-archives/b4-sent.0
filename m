From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Subject: [PATCH RESEND v2 0/2] nfc: st21nfca: fix SE APDU request race
 condition
Date: Tue, 10 Nov 2026 03:22:54 +0000
Message-Id: <20261110-st21nfca-v2-v2-0-cf9102b314cb@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: joasantonio108@gmail.com, david@ixit.cz, krzk@kernel.org
Cc: oe-linux-nfc@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, horms@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794280974; l=1341;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=ebXR0iQXcJSvVd4YPxZu8WAcSHjyWGZ3ferWgFqe25E=;
 b=gJuL3Cfi5rfEv9AshF/bce652gT/67VgR68YAgOkWWXYusEBjJjTMBmHbi0+Odsqk16Omh6q8
 7FdBJqpi/UoAitQhaexn+mAeQbfHitEsC5cRDNfTgp66/IvxQeJvKlX
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

