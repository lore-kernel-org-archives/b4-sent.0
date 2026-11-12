From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Subject: [PATCH net v3 0/2] nfc: st21nfca: fix SE APDU request race
 condition
Date: Thu, 12 Nov 2026 13:39:28 +0000
Message-Id: <20261112-st21nfca-v2-v3-0-c81702269e01@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJDB9WoC/22NQQrDIBRErxL+uha1UaSr3qNkIfpNPjSmqEhL8
 O4V14XZvBlm5oSMiTDDfTohYaVMR+xwu0zgNhtXZOQ7g+RSC8ENy0WKGJxlVbIwOxWMFjgLDb3
 xThjoM9aeELHA0s2NcjnSdzxUOaK/Y12cSS8w+KCsV+ax7pZeV3fssLTWfvYTPearAAAA
To: david@ixit.cz, krzk@kernel.org, joasantonio108@gmail.com
Cc: oe-linux-nfc@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, horms@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794490768; l=2879;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=dycIAZ67P7dxjyM+e8OFg3HpvpHw09nTXrMGmQMNnPc=;
 b=6yRt9w5P/R9HsMDsNiXb10MzNMRwJYk9eP7zeICOXpcwYmTNQaucAkfBW+Vv2usoxUi0c27Kl
 BIUBdlEkkTtAlciYSNzd11VrdTCmfReHW68CqAYxW3Rz/28EcMYehbj
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The BWI timeout work and the EVT_TRANSMIT_DATA handler can both
complete the same SE APDU request.  The callback frees its context, so
the second completion is a use-after-free followed by a double free.

  1/2: Add a spinlock around bwi_active, cb and cb_context in the three
       paths that use them.
  2/2: Use the lock to complete a request only once and to reject
       overlapping requests.

This was found with the help of an LLM-based code review tool (Claude).
I checked the code paths by hand and reviewed the fixes myself.  The
series is build-tested only (W=1, arm64); I do not have the hardware.

Not addressed here, all older than this series and pointed out by the
Sashiko review of v2:

- st21nfca_se_deinit() can leave bwi_timer armed when info is freed
   (it runs before nfc_hci_unregister_device() and only deletes the
   timer when bwi_active is set).  The remove ordering needs its own
   patch.
 - EVT_TRANSMIT_DATA carries no request id, so a response that arrives
   after its request timed out can still be taken for the answer to the
   next request.
 - When nfc_hci_send_event() fails in st21nfca_hci_se_io() the request
   stays pending until the BWI timeout completes it with -ETIME.
 - drivers/nfc/st-nci/se.c has the same double completion.  I will send
   a separate patch for it once the approach here is agreed on.

---
Changes in v3:
- 2/2: free cb_context when a request is rejected with -EBUSY; it was
  leaked (Sashiko).
- 2/2: still send EVT_SE_END_OF_APDU_TRANSFER for a response that
  arrives after the timeout, as before the series; only the callback is
  skipped (Sashiko).
- 1/2: comment on what se_lock protects (checkpatch), commit message
  no longer claims every access is serialized.
- Rebased on v7.4-rc3+, target tree added to the subject.
- Link to v2: https://lore.kernel.org/r/20261110-st21nfca-v2-v2-0-cf9102b314cb@gmail.com

Changes in v2:
- Use a spinlock instead of plain bwi_active flag checks (Simon Horman).
- Split into two patches: locking, then the completion fix.
- Set bwi_active before mod_timer().
- Copy cb/cb_context under the lock, call it after unlocking.
- Reject overlapping se_io requests with -EBUSY.
- Drop the Assisted-by trailer.
- Link to v1: https://lore.kernel.org/r/179332800288.52644.8728400883396719965@gmail.com

---
Joas Antonio dos Santos (2):
      nfc: st21nfca: add spinlock to serialize SE APDU request state
      nfc: st21nfca: prevent double completion of SE APDU request

 drivers/nfc/st21nfca/se.c       | 38 ++++++++++++++++++++++++++++++++++----
 drivers/nfc/st21nfca/st21nfca.h |  2 ++
 2 files changed, 36 insertions(+), 4 deletions(-)
---
base-commit: 9d66f26fefacebfeed15de31c1123451a17ff119
change-id: 20261108-st21nfca-v2-f4c5f861e416

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

