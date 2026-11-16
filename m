From: Mattathias Pinchover <mattathias.pinchover@uber.com>
Date: Mon, 16 Nov 2026 19:10:07 +0000
Subject: [PATCH 4/6] Docs/mm/damon/design: update for
 sz_ops_filter_passed_last
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-damon-sz-ops-b4-v1-4-1cffe7227e6d@uber.com>
References: <20261116-damon-sz-ops-b4-v1-0-1cffe7227e6d@uber.com>
In-Reply-To: <20261116-damon-sz-ops-b4-v1-0-1cffe7227e6d@uber.com>
To: SJ Park <sj@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: damon@lists.linux.dev, linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Mattathias Pinchover <mattathias.pinchover@uber.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794856219; l=2118;
 i=mattathias.pinchover@uber.com; s=20261113; h=from:subject:message-id;
 bh=nwHjZVHHDRBT1eHlqqDWBt5BJ2Vcy+5/DHoQlewkkIE=;
 b=b0tvkQypc2c7AsnCXE+pq9rOaYIeO3iDB0Oj8qy+Oo2BDDoOAEgQn7E9EZf8uFy1tHQ24VVWB
 X5KJIE6CiWvBDh8V8PfnZmpjaQE2zudNNk0YZuofHhRxEiKtyhq8L1E
X-Developer-Key: i=mattathias.pinchover@uber.com; a=ed25519;
 pk=6Bh6OEwWiU6dpON0CVcoipq8fXtEgvhsM1Tmm9CTmtY=
X-Endpoint-Received: by B4 Relay for mattathias.pinchover@uber.com/20261113 with auth_id=1515
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update DAMON design document for the newly added DAMOS stat,
sz_ops_filter_passed_last.  Also explain that, unlike other
stats, it is not accumulated from the beginning of the scheme's
execution but shows the value of the last apply interval.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Mattathias Pinchover <mattathias.pinchover@uber.com>
---
 Documentation/mm/damon/design.rst | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/mm/damon/design.rst b/Documentation/mm/damon/design.rst
index b676be697158..e40b8c1a3461 100644
--- a/Documentation/mm/damon/design.rst
+++ b/Documentation/mm/damon/design.rst
@@ -876,6 +876,8 @@ scheme's execution.
 - ``sz_tried``: Total size of regions that the scheme is tried to be applied.
 - ``sz_ops_filter_passed``: Total bytes that passed operations set
   layer-handled DAMOS filters.
+- ``sz_ops_filter_passed_last``: Bytes that passed operations set
+  layer-handled DAMOS filters in the last ``apply_interval``.
 - ``nr_applied``: Total number of regions that the scheme is applied.
 - ``sz_applied``: Total size of regions that the scheme is applied.
 - ``qt_exceeds``: Total number of times the quota of the scheme has exceeded.
@@ -903,6 +905,13 @@ to exclude anonymous pages and the region has only anonymous pages, or if the
 action is ``pageout`` while all pages of the region are unreclaimable, applying
 the action to the region will fail.
 
+Unlike other stats, ``sz_ops_filter_passed_last`` is not
+accumulated from the beginning of the scheme's execution.  It is updated at the
+end of each :ref:`apply_interval <damon_design_damos>` with the amount of
+``sz_ops_filter_passed`` increase in the interval.  Hence it shows the size of
+memory that passed the operations set layer-handled filters in the last
+completed ``apply_interval``.
+
 Unlike normal stats, ``max_nr_snapshots`` is set by users.  If it is set as
 non-zero and ``nr_snapshots`` equals or is greater than ``max_nr_snapshots``,
 the scheme is deactivated.  Note that, unlike watermarks, even if a scheme's

-- 
2.54.0-uber3

