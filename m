From: Nikita Ofitserov <himikof@gmail.com>
Subject: [PATCH 00/12] Accounting for accurate progress reporting
Date: Wed, 27 Aug 2025 01:49:06 +0300
Message-Id: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOI5rmgC/x3MQQqAIBBA0avErBNKU6yrRIvKyWaTMhMRRHdPW
 r7F/w8IMqHAUD3AeJFQOgrauoJ1n4+IikIx6EbbxmunFjxPZJU5RUYR5Y0NfedmsxoPpcqMG93
 /cZze9wNX2lPZYQAAAA==
X-Change-ID: 20250826-better-progress-835d946a3c38
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2620; i=himikof@gmail.com;
 h=from:subject:message-id; bh=8KztQX5RYFze7BGFBWYrQJ/vOs5MCiuY59PzEzAk1cU=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5LOsNkz61H8E+ZLTQUalboWDLqPzGr3ZbFrX1zh3
 xWuIbOlo5SFQYyLQVZMkeXDkq9/1mRa/7EU2msIM4eVCWQIAxenAExEPZrhf12URKB/sQGn3SYO
 48O69f927/7XrRE/f3n1X/mJhddiHjL8lbgZVZf7zelI0k7GigiBvVWNzOfiSq6ffmRvI/D/3cJ
 KXgA=
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces new per-btree accounting counters and uses
them for (hopefully) accurate progress reporting in recovery passes.
Also includes various assorted bugfixes.

The first commit ("Relax restrictions on the number of accounting 
counters") is optional, but will likely greatly improve the 
upgrade/tools version mismatch experience. Without it, all bree usage 
accounting will be thrown out and rebuilt on any version mismatch.

The second commit has the format change but does not contain the
upgrade/downgrade table entries. It is intended to be integrated
together with other accounting changes in a single version upgrade.

The last four commits are drive-by fixes/improvements, especially 
"Improve check_allocations pass speed not in fsck", which should make
the future accounting upgrades much faster.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
Nikita Ofitserov (12):
      bcachefs: Relax restrictions on the number of accounting counters
      bcachefs: Introduce btree node number accounting
      bcachefs: Use explicit node counts in progress reporting
      bcachefs: Introduce btree_leaf_has_triggers_mask
      bcachefs: Better progress reporting for btree iteration without leaves
      bcachefs: Refactor/rename btree_type_has_ptrs
      bcachefs: More accurate progress reporting for inner node iteration
      bcachefs: Fix progress reporting for unknown btrees
      bcachefs: Partially fix old device removal with unknown btrees
      bcachefs: Improve check_allocations pass speed not in fsck
      bcachefs: Fix missing c->usage updates from early recovery
      bcachefs: Fix online hidden (sb+journal) data accounting

 fs/bcachefs/backpointers.c           |  6 ++++--
 fs/bcachefs/btree_gc.c               | 28 ++++++++++++++++--------
 fs/bcachefs/btree_trans_commit.c     |  3 +++
 fs/bcachefs/btree_types.h            | 11 ++++++----
 fs/bcachefs/buckets.c                | 16 +++++++++-----
 fs/bcachefs/disk_accounting.c        | 23 ++++++++++++++------
 fs/bcachefs/disk_accounting.h        | 14 +++++++-----
 fs/bcachefs/disk_accounting_format.h | 10 ++++++++-
 fs/bcachefs/migrate.c                | 18 ++++++++++------
 fs/bcachefs/move.c                   |  2 +-
 fs/bcachefs/progress.c               | 41 ++++++++++++++++++++++++++++++------
 fs/bcachefs/progress.h               | 12 ++++++++++-
 12 files changed, 136 insertions(+), 48 deletions(-)
---
base-commit: 8bf9cabd6109efc82bdccf6c450102d0be3ed3da
change-id: 20250826-better-progress-835d946a3c38

Best regards,
-- 
Nikita Ofitserov

