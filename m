From: kimwooseok <5mghybrid@khu.ac.kr>
Subject: [PATCH rtw-next v2 0/4] wifi: rtl8xxxu: keep RX requests available
 across transient errors
Date: Sun, 13 Sep 2026 16:33:18 +0900
Message-Id: <20260913-codex-rtw-rx-v2-v2-0-f09c964e0b96@khu.ac.kr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL9RpmoC/yWMSw7CMAwFr1K9NZZSV+J3FcQCEgfMIkVOWiJVv
 TspLEfvzSzIYioZ526ByaxZx9SAdx3885YeQhoagx3v3akfyI9BKln5kFWamWL03LvD4I4holl
 vk6j1V7xguyWpBdf/kqf7S3zZgljXL4SBtZd9AAAA
X-Change-ID: 20260913-codex-rtw-rx-v2-ffc2107308df
To: linux-wireless@vger.kernel.org
Cc: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-kernel@vger.kernel.org, 
 kimwooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789284810; l=3885;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=RBuppGYN9JIqPwxc9VsY+/5iSz70Aght3JSaf+MDnwc=;
 b=wN/1ZeL/quUqGmF/Fqh8k21cHqwzvXRcDfpHOfSnAvGcSlSNA5oaL16DLhkISE7D5iNr41D83
 r8ei9ZEwK1PDtHBABWsBO2wABWEL44oRn9yfdxVe4vusBBUnYD1nY7t
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl8xxxu maintains a pool of 32 RX URBs. Successful completions return
their URBs to a pending list and schedule the RX worker when more than
eight URBs are waiting. The worker allocates fresh receive buffers and
resubmits the queued URBs in a batch.

Completion errors free the affected URBs, reducing the pool. Once eight
or fewer survive, their completions can leave all remaining requests on
the pending list without reaching the worker scheduling threshold. If no
request is in flight and no worker is pending or running, nothing triggers
further submissions, so RX remains stalled after the errors stop.

Temporary submission failures can leave requests in the same state, while
retaining an skb that the next submission attempt overwrites.

This series fixes buffer ownership on failed submission, unwinds
incomplete startup, and preserves requests through one delayed retry path.
The retry worker schedules submission even for a single request. A
separate error list provides a 100 ms batch delay from the first error
while preserving normal successful RX batching. Shutdown drains retry
work, submission work and active requests in that order.

Completion retries cover EPROTO, EILSEQ, ETIME, EOVERFLOW, ECOMM and ENOSR;
ENOMEM/EAGAIN from startup or worker submission uses the same retry path.
Cancellation and removal keep their release behavior. EPIPE endpoint-halt
recovery is outside this series.

With 24 injected EPROTO completions, the original driver stopped at eight
pending requests and zero in flight for about 30 seconds. Under the same
error budget, the patched driver retained all 32 requests and resumed RX
without restarting the interface.

Validation:
- ARM64 QEMU KUnit: 11/11 cases passed, covering the actual RX helpers,
  worker, buffer ownership, startup failures and shutdown.
- RTL8192EU on Raspberry Pi, kernel 6.18.46-thesis-test-rt+: 13/13 cases
  passed using a compatibility backport. The lab fixture substitutes
  completion statuses and injects submission and allocation failures.
  Each of the six completion statuses recovered after 32 completion
  errors followed by 96 submission failures. Error-window, pending-retry
  stop, startup failure and clean RX/down-up cases also passed.
- W=1 ARM64 allmodconfig and allyesconfig builds passed with incremental
  caches; the changed driver and KUnit objects rebuilt in both.
  Sparse added no diagnostics relative to baseline.
- Each intermediate production commit compiled, and sequential patch
  application reproduced the corresponding source trees.

---
Changes in v2:
- Target the rtw-next branch of https://github.com/pkshih/rtw.git.
- Send the patches inline as plain text, without attachments.
- No code changes; the base commit is unchanged.
- Link to v1: https://lore.kernel.org/linux-wireless/CAH1Bc_yJ1e_nHk9tP2qP_4D8MHEve1R2EF5cYCEXRwc+1xVAxw@mail.gmail.com/

---
kimwooseok (4):
      wifi: rtl8xxxu: free RX skb when URB submission fails
      wifi: rtl8xxxu: unwind incomplete receive startup
      wifi: rtl8xxxu: preserve RX requests across recoverable transfer errors
      wifi: rtl8xxxu: test RX ownership and recovery across failures

 drivers/net/wireless/realtek/rtl8xxxu/.kunitconfig |  16 +
 drivers/net/wireless/realtek/rtl8xxxu/Kconfig      |  11 +
 drivers/net/wireless/realtek/rtl8xxxu/Makefile     |   3 +
 drivers/net/wireless/realtek/rtl8xxxu/core.c       | 236 ++++++++---
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h   |   3 +
 drivers/net/wireless/realtek/rtl8xxxu/rx-test.c    | 461 +++++++++++++++++++++
 drivers/net/wireless/realtek/rtl8xxxu/rx-test.h    |  27 ++
 7 files changed, 707 insertions(+), 50 deletions(-)
---
base-commit: f71dd599a98182d6bc34dce39977f928068ecd64
change-id: 20260913-codex-rtw-rx-v2-ffc2107308df

Best regards,
--  
kimwooseok <5mghybrid@khu.ac.kr>

