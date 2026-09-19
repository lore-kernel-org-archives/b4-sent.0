From: Kim Wooseok <5mghybrid@khu.ac.kr>
Subject: [PATCH rtw-next v3 0/3] wifi: rtl8xxxu: keep RX requests available
 across transient errors
Date: Sun, 20 Sep 2026 05:44:03 +0900
Message-Id: <20260920-codex-rtl-rx-v3-submit-v3-0-883d11351963@khu.ac.kr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zWMTQrCMBCFr1Jm7UCaSqFeRVwk6WhHNJXJtAZK7
 26i+Hbf+9sgkTAlODUbCK2ceI4FukMDYXLxRshjYbDG9mawBsM8UkbRB0rGtcO0+Ccrtv5Irh9
 sWwRl/BK6cv4en0H0jZGywuWXlM2dgtbf2vUuEXpxMUzV+rex+rDvH22yDfOkAAAA
X-Change-ID: 20260920-codex-rtl-rx-v3-submit-1b4ea6921111
To: linux-wireless@vger.kernel.org
Cc: pkshih@realtek.com, kvalo@kernel.org, linux-kernel@vger.kernel.org, 
 Jes.Sorensen@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789850643; l=3892;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=d3AcLn4a9qFXJlJjzccqYgcSQqR+1GNbo3HUaZ6Dgyc=;
 b=PVDobP5412hrNvkdROl4fhz7cddNWT6/pJNIsO6Hgy8yahYI2/XJT7sZQNi+reDOAJoWAUTs2
 fgoBmASBR3UDpoq7TO6RmEd/Gmv5rpAX6q18sjXn+ZnArcQQLwK1Opn
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl8xxxu keeps 32 RX URBs in circulation. Completed requests wait on a
pending list until more than eight are ready to be submitted again.
Completion errors free their URBs, however, so a finite run of errors
can leave too few requests to reach that threshold. At that point,
reception can stay stopped even after the errors end.

This series fixes that loss of RX requests, along with two problems in
the submission and startup paths: a failed submission can leak its skb,
and a failed start can leave earlier requests active or report success
after only part of the pool was allocated.

In v3, normal completions and recoverable failures return requests to
one pending list, serviced by one delayed work item. An error queues a
100 ms retry. When a normal completion takes the pending count above
eight, mod_delayed_work(..., 0) brings the work forward. ENOMEM/EAGAIN
during submission uses the same retry path.

The delay limits repeated retries when normal reception is not
progressing; it is not a minimum wait for each URB. During stop, the RX
lock prevents new reservations once shutdown is set. Stop then cancels
the delayed work before draining active and pending requests.

Changes since v2:
- Keep patch 1's code unchanged and retain Ping-Ke's Reviewed-by.
- Share the startup and worker submission loop, preserving their
  different handling of fatal errors.
- Replace the separate retry list and worker with one pending list
  and one delayed work item; normal completions can advance a retry.
- Remove the shutdown initialization added in probe.
- Drop the KUnit patch and its test-only hooks from this series.
- Use the confirmed author name and verify the Fixes references.

I built the driver at baseline and after each patch with W=1 under ARM64
allmodconfig and allyesconfig. Both full kernel builds also passed, and
the baseline/final sparse comparisons produced no new diagnostics.

The hardware tests used an RTL8192EU USB adapter on a Raspberry Pi. I
adapted the RX changes to the Pi's existing Linux 6.18.46 RT kernel to
run them on the device. V3 passed 52 tests covering allocation and
submission failures, all six completion errors, repeated failures,
scheduling, stop and normal RX/down-up. Two interrupt-URB tests were not
run because this device does not use that path.

Nine of the passing tests failed the first start after a fresh module
load, at the first, middle or last TX/RX allocation or fatal RX
submission. Each began with no previous start, cleaned up after the
injected failure, and received packets after the next start.

For the same 24 injected EPROTO completions in a 32-URB pool, the
unpatched driver stopped with eight pending requests and none in flight.
V3 kept all 32 and received 1,225 packets over 30 seconds without
restarting the interface.

The fault-injection changes are kept outside the series and exercise the
actual allocation, submission, completion, worker and stop paths.

v2: https://lore.kernel.org/linux-wireless/20260913-codex-rtw-rx-v2-v2-0-f09c964e0b96@khu.ac.kr/

Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>

---
Kim Wooseok (3):
      wifi: rtl8xxxu: free RX skb when URB submission fails
      wifi: rtl8xxxu: unwind incomplete receive startup
      wifi: rtl8xxxu: preserve RX requests across recoverable transfer errors

 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 153 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--------------------------------------------------------------------
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |   2 +-
 2 files changed, 86 insertions(+), 69 deletions(-)
---
base-commit: 73e3b1c94c7d5b4a113e7cbb42665dc2fe3b9d78
change-id: 20260920-codex-rtl-rx-v3-submit-1b4ea6921111

Best regards,
--  
Kim Wooseok <5mghybrid@khu.ac.kr>

