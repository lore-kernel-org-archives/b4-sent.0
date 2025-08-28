From: Nikita Ofitserov <himikof@gmail.com>
Subject: [PATCH v2 00/15] Accounting for accurate progress reporting
Date: Thu, 28 Aug 2025 17:16:02 +0300
Message-Id: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKNksGgC/2WNyw6CMBBFf4XM2ppSHi2u/A/DopaxTCKUTAnRk
 P67lcSVy3OSe+4OEZkwwqXYgXGjSGHOoE4FuNHOHgUNmUFJ1UijWnHHdUUWCwfPGKMwVTN0dWs
 rVxnIq4XxQa+jeOszjxTXwO/jYCu/9tfSf62tFFLo2ql6QN0ZY69+svQ8uzBBn1L6AFruW+quA
 AAA
X-Change-ID: 20250826-better-progress-835d946a3c38
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3158; i=himikof@gmail.com;
 h=from:subject:message-id; bh=sd+aLu9t3h6P3San180B4CXgz1i7bJ3bA8mbF9L5qao=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDm41e/upH8r3HVa19xP+idxt0Zj4vpvfdxb9W79P
 j5T86HJjo5SFgYxLgZZMUWWD0u+/lmTaf3HUmivIcwcViaQIQxcnAIwkR3VDH/48pW5HUSObuBP
 T15zwEh3qWTg4W4rjWndPFUWBpNnbC9j+J92ZIb/7WtNTncNzD81dhntujbbmJlxevJ3qaBpQW2
 5MgwA
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

The first ten commits are drive-by fixes/improvements, especially 
"Improve check_allocations pass speed not in fsck", which should make
future accounting upgrades much faster (including this one).

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
Changes in v2:
- Reordered the format-change-dependent commits to the end
- Added the new metadata version, upgrade and downgrade entries
- Fixed an issue with hidden usage calculation after device removal
- Link to v1: https://lore.kernel.org/r/20250827-better-progress-v1-0-74c24de7988a@gmail.com

---
Nikita Ofitserov (15):
      bcachefs: Introduce btree_leaf_has_triggers_mask
      bcachefs: Refactor bch2_gc_btree/bch2_gc_btrees
      bcachefs: Improve check_allocations pass speed when not in fsck
      bcachefs: Refactor/rename btree_type_has_ptrs
      bcachefs: Fix progress reporting for unknown btrees
      bcachefs: Partially fix old device removal with unknown btrees
      bcachefs: Fix missing c->usage updates from early recovery
      bcachefs: Optimize/fix bch2_dev_usage_remove
      bcachefs: Fix online hidden (sb+journal) data accounting
      bcachefs: Fix outdated documentation comment
      bcachefs: Relax restrictions on the number of accounting counters
      bcachefs: bcachefs_metadata_version_btree_node_accounting
      bcachefs: Use explicit node counts in progress reporting
      bcachefs: Better progress reporting for btree iteration without leaves
      bcachefs: More accurate progress reporting for inner node iteration

 fs/bcachefs/alloc_background.c       |  2 +-
 fs/bcachefs/backpointers.c           |  6 ++--
 fs/bcachefs/bcachefs_format.h        |  4 +--
 fs/bcachefs/btree_gc.c               | 28 ++++++++++-----
 fs/bcachefs/btree_trans_commit.c     |  3 ++
 fs/bcachefs/btree_types.h            | 11 +++---
 fs/bcachefs/buckets.c                | 16 ++++++---
 fs/bcachefs/disk_accounting.c        | 70 ++++++++++++++++++++++++++----------
 fs/bcachefs/disk_accounting.h        | 16 +++++----
 fs/bcachefs/disk_accounting_format.h | 10 +++++-
 fs/bcachefs/migrate.c                | 18 ++++++----
 fs/bcachefs/move.c                   |  2 +-
 fs/bcachefs/progress.c               | 41 +++++++++++++++++----
 fs/bcachefs/progress.h               | 12 ++++++-
 fs/bcachefs/sb-downgrade.c           | 11 ++++--
 15 files changed, 184 insertions(+), 66 deletions(-)
---
base-commit: 753b29cc79897dd7f776fa09654196f5b25f8b96
change-id: 20250826-better-progress-835d946a3c38

Best regards,
-- 
Nikita Ofitserov

