From: Kim Wooseok <5mghybrid@khu.ac.kr>
Subject: [PATCH rtw-next v4 0/3] wifi: rtl8xxxu: keep RX requests available
 across transient errors
Date: Mon, 21 Sep 2026 16:59:48 +0900
Message-Id: <20260921-codex-rtl-rx-v3-submit-v4-0-eeb09fe8f791@khu.ac.kr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4VOSw6CMBC9ipm1QyhFAq68h2FRyigVLWZaEEO4u
 y3GtbOa981bwBEbcnDcLcA0GWcGG0C+34HulL0SmjZgyNKsSKssRT20NCP7O/KMk0Q3Ng/jUTQ
 5qaLKRDgI4SfTxcxb8RnYv9DS7KH+KiFzI+1jb/Q2yhE2rKzuIvVzY+Sj3hnnB35vGye5Nf6bE
 74Uy1K2QsiDqAp56rsxUTrpGep1XT8V2yEZ+AAAAA==
X-Change-ID: 20260920-codex-rtl-rx-v3-submit-1b4ea6921111
To: linux-wireless@vger.kernel.org
Cc: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 linux-kernel@vger.kernel.org, Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789977589; l=2887;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=SmvhrJEU24sW5LU8DytMNLC3sHmZyGqZmfauFRtK3ng=;
 b=zQIRZTigf6m5OBJGnNqPeiVrjGcO35JlN7AJ61tmmv+u+IZrwsHTUYP+5UrCb2gWzQGGySH73
 NPPslW8JH/AAd7rQ1l84s8AMteA49CkH2ar4lFNxyF+xM9iQPEwHGYa
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl8xxxu keeps 32 RX URBs in circulation. Completed requests wait on a
pending list until more than eight are ready for resubmission. Completion
errors free their URBs, so a finite run of errors can leave too few
requests to reach that threshold. Reception can then remain stopped
after the errors end.

This series preserves those requests across recoverable errors. It also
fixes an skb leak after failed submission and startup error paths that
leave requests active or report success after only part of the pool was
allocated.

Normal completions and recoverable failures use one pending list and
one delayed work item. Errors schedule a retry with a 100 ms delay.
When a normal completion takes the pending count above eight,
mod_delayed_work(..., 0) brings the work forward. The delay limits
repeated retries when normal reception is not progressing; it is not a
minimum wait for each URB. ENOMEM/EAGAIN during submission uses the same
retry path.

I designed the v3 tests around the error paths changed by this series
and exercised them on an RTL8192EU with the RX changes backported to the
Pi's 6.18.46 RT kernel. I checked resource cleanup and reception after
recovery and restart.

With the same 24 injected EPROTO completions, the unpatched driver
stopped with eight pending URBs and none in flight. V3 retained all 32
and received 1,225 packets in 30 seconds without restarting the
interface.

For the changes in v4, I rebuilt the driver with W=1 after patches 2
and 3 using the existing ARM64 build configuration. Both builds passed
without warnings. All three patches pass strict checkpatch and apply
in order to the base commit.

Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>

---
Changes in v4:
- Leave patch 1 unchanged and add Ping-Ke's Reviewed-by to patch 2.
- Initialize the RX worker's priv pointer at declaration and add the
  requested blank lines.
- Rename the queue helper's retry argument to defer_schedule.
- Use schedule_delayed_work() for delayed retries. Keep
  mod_delayed_work() to advance pending work on normal completions,
  using system_percpu_wq instead of system_wq.
- Link to v3: https://lore.kernel.org/linux-wireless/20260920-codex-rtl-rx-v3-submit-v3-0-883d11351963@khu.ac.kr/

---
Kim Wooseok (3):
      wifi: rtl8xxxu: free RX skb when URB submission fails
      wifi: rtl8xxxu: unwind incomplete receive startup
      wifi: rtl8xxxu: preserve RX requests across recoverable transfer errors

 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 154 +++++++++++++----------
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |   2 +-
 2 files changed, 87 insertions(+), 69 deletions(-)
---
base-commit: 73e3b1c94c7d5b4a113e7cbb42665dc2fe3b9d78
change-id: 20260920-codex-rtl-rx-v3-submit-1b4ea6921111

Best regards,
--  
Kim Wooseok <5mghybrid@khu.ac.kr>

