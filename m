From: Karthik Nayak <karthik.188@gmail.com>
Subject: [PATCH 0/5] pack-write: cleanup usage of global variables
Date: Thu, 16 Jan 2025 12:35:12 +0100
Message-Id: <20250116-kn-the-repo-cleanup-v1-0-a2f4c8e1c4c3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPDuiGcC/x3MQQqAIBBA0avErBtQmzZdJVqITTkUJloRSHdPW
 r7F/wUyJ+EMQ1Mg8S1ZjlCh2wact2FllLkajDK90lrhFvD0jInjgW5nG66IRJposWRm10EtY+J
 Fnv86Tu/7AQJjq8FlAAAA
X-Change-ID: 20250110-kn-the-repo-cleanup-44144fa42dc3
To: git@vger.kernel.org
Cc: Karthik Nayak <karthik.188@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1560; i=karthik.188@gmail.com;
 h=from:subject:message-id; bh=E1DMnM5IRNdyQnMHIUSxSwpllBmkbgs35wlsAYkQMdI=;
 b=owJ4nAHtARL+kA0DAAoBPtWfJI5GjH8ByyZiAGeI7vRH8Nxxn9h6WXyhncoNrHat+S7Jj/TP4
 dWpDSsHZk7izYkBswQAAQoAHRYhBFfOTH9jdXEPy2XGBj7VnySORox/BQJniO70AAoJED7VnySO
 Rox/gycL/AqSkEEhm1yjQG7fqB98QfAX2oDfskUNLOoLspvaPUxI5MCrnNEZNFtWTzcjgQnxHo7
 fu4ZWdMZGucRQChjh4X7OesFCUQv3sCnzKczcQ2WlFFeGkcJtrxoW0sv7KjpLvV7S/GOzZNA/xI
 /eOtDdx68b4nRJxLs+VO87jAYfmbcK1gZbSFDibLWfI7v5zPLBV5m0LBoPdvlEcHyjMmIVVGyUT
 0HPOLI7ylwUdLaSGD6QRpRykyCU3hlFmkTfxJd60/AF/5eR7c2Xz1cT+fmeIHljRL+Mof4nbhsH
 9Jk66dvWaqxPCmOjJynstGVuSpL936dQ7pOXO+WoUiFjq13zJLzkHaMA6UX+JgIVRNPGI7/4BYm
 jTjtlC4z0Qx8NSc1fPRZXv8GvnyoO93aCp6NbkFuw61SXjJ/LgxEejHLvtZ/PIXqvBsFShQ+Uu0
 9cWg5U4/LNZDPcD1Jz1xX+Bl7MJMMHVwMFnyoDKcmJqBkxEc9wixP7KYwi71HlndMPgTe9xvrB6
 bA=
X-Developer-Key: i=karthik.188@gmail.com; a=openpgp;
 fpr=57CE4C7F6375710FCB65C6063ED59F248E468C7F
X-Endpoint-Received: by B4 Relay for karthik.188@gmail.com/default with auth_id=276
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a small series to remove global variable usage from
`pack-write.c`. Mostly it bubble's up the usage of global variables to
upper layers. The only exception is in `write-midx.c`, which was cleaned
of global variable usage, so there, we use the repo that is in available
in the context.

This series is based on fbe8d3079d (Git 2.48, 2025-01-10) with
'ps/more-sign-compare' and 'ps/the-repository' merged in.

There are no conflicts with topics in 'next', however there is a
conflict with 'tb/incremental-midx-part-2' in 'seen', the fix is simple
but happy to merge that in too if necessary.

Signed-off-by: Karthik Nayak <karthik.188@gmail.com>
---
Karthik Nayak (5):
      pack-write: pass hash_algo to `fixup_pack_header_footer()`
      pack-write: pass repository to `index_pack_lockfile()`
      pack-write: pass hash_algo to `write_idx_file()`
      pack-write: pass hash_algo to `write_rev_file()`
      pack-write: pass hash_algo to `write_rev_*()`

 builtin/fast-import.c  | 11 +++---
 builtin/index-pack.c   | 11 +++---
 builtin/pack-objects.c | 12 +++---
 builtin/receive-pack.c |  2 +-
 bulk-checkin.c         |  7 ++--
 fetch-pack.c           |  4 +-
 midx-write.c           |  4 +-
 pack-write.c           | 99 +++++++++++++++++++++++++++-----------------------
 pack.h                 | 30 ++++++++++++---
 9 files changed, 106 insertions(+), 74 deletions(-)
---



---

base-commit: 8b2efc058aaa3d1437678616bccf7c5f7ce1f92b
change-id: 20250110-kn-the-repo-cleanup-44144fa42dc3

Thanks
- Karthik

