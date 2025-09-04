From: Nikita Ofitserov <himikof@gmail.com>
Subject: [PATCH v3 0/7] Accounting for accurate progress reporting
Date: Thu, 04 Sep 2025 08:20:31 +0300
Message-Id: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ8huWgC/2XNQQqDMBCF4avIrJsSJ1Gjq96jdJHGqQaqkURCi
 3j3RqEguHwD3z8LBPKWAjTZAp6iDdaNaYhLBqbXY0fMtmkDciy4wpI9aZ7Js8m7zlMITImirWW
 phREKkpo8vexnL94fafc2zM5/9wcx367/VnVqxZxxVkmDsqWqVkrfukHb99W4AbZWxKNXZ4/JG
 54gci5qyY9+Xdcf+2bFLO4AAAA=
X-Change-ID: 20250826-better-progress-835d946a3c38
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2624; i=himikof@gmail.com;
 h=from:subject:message-id; bh=tEilySZIzzg/utCPi/DUhTpiv2r8lWfAh2Lf9phQYvE=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPxx5ddLiR/ipR2x86vXffepjwgOknrt8OnZT+P79
 45MPOI8taOUhUGMi0FWTJHlw5Kvf9ZkWv+xFNprCDOHlQlkCAMXpwBM5KUqw1+xmY3zdPIrFhrF
 2y+fZXHWLPxe1tRUll/3a1vTntzkVBZiZFjDOKlGstP/SrL38aPW9U/KJLayPLFL8Fp8f2tizGG
 NRwwA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces new per-btree accounting counters and uses
them for (hopefully) accurate progress reporting in recovery passes.
Also includes various assorted bugfixes.

The commit "Relax restrictions on the number of accounting 
counters" is optional, but will likely greatly improve the 
upgrade/tools version mismatch experience. Without it, all bree usage 
accounting will be thrown out and rebuilt on any version mismatch.

The commit "bcachefs_metadata_version_btree_node_accounting"
introduces the format change along with upgrade/downgrade table entries.

The first two commits are drive-by fixes/improvements.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
Changes in v3:
- Removed already merged patches
- Fixed a locking issue in do_bch2_trans_commit_to_journal_replay
- Link to v2: https://lore.kernel.org/r/20250828-better-progress-v2-0-c088a2003940@gmail.com

Changes in v2:
- Reordered the format-change-dependent commits to the end
- Added the new metadata version, upgrade and downgrade entries
- Fixed an issue with hidden usage calculation after device removal
- Link to v1: https://lore.kernel.org/r/20250827-better-progress-v1-0-74c24de7988a@gmail.com

---
Nikita Ofitserov (7):
      bcachefs: Fix missing c->usage updates from early recovery
      bcachefs: Fix online hidden (sb+journal) data accounting
      bcachefs: Relax restrictions on the number of accounting counters
      bcachefs: bcachefs_metadata_version_btree_node_accounting
      bcachefs: Use explicit node counts in progress reporting
      bcachefs: Better progress reporting for btree iteration without leaves
      bcachefs: More accurate progress reporting for inner node iteration

 fs/bcachefs/backpointers.c           |  4 +++-
 fs/bcachefs/bcachefs_format.h        |  3 ++-
 fs/bcachefs/btree_gc.c               |  2 +-
 fs/bcachefs/btree_trans_commit.c     |  4 ++++
 fs/bcachefs/buckets.c                | 16 ++++++++++-----
 fs/bcachefs/disk_accounting.c        | 23 ++++++++++++++-------
 fs/bcachefs/disk_accounting.h        | 14 ++++++++-----
 fs/bcachefs/disk_accounting_format.h | 10 ++++++++-
 fs/bcachefs/migrate.c                | 13 ++++++++----
 fs/bcachefs/progress.c               | 39 ++++++++++++++++++++++++++++++------
 fs/bcachefs/progress.h               | 12 ++++++++++-
 fs/bcachefs/sb-downgrade.c           | 11 ++++++++--
 12 files changed, 117 insertions(+), 34 deletions(-)
---
base-commit: 5b7f3db1969892f536be48e082a32095aa86042a
change-id: 20250826-better-progress-835d946a3c38

Best regards,
-- 
Nikita Ofitserov

