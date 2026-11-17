From: Mattathias Pinchover <mattathias.pinchover@uber.com>
Date: Tue, 17 Nov 2026 23:22:18 +0000
Subject: [PATCH v2 4/6] Docs/mm/damon/design: update for
 sz_ops_filter_passed_last
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-damon-sz-ops-b4-v2-4-439888fa04ac@uber.com>
References: <20261117-damon-sz-ops-b4-v2-0-439888fa04ac@uber.com>
In-Reply-To: <20261117-damon-sz-ops-b4-v2-0-439888fa04ac@uber.com>
To: SJ Park <sj@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: damon@lists.linux.dev, linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Mattathias Pinchover <mattathias.pinchover@uber.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794957787; l=1087;
 i=mattathias.pinchover@uber.com; s=20261113; h=from:subject:message-id;
 bh=sxtzpPREIDw7ZFR+5CW2rzs4hwvhtdKiGsknt4ydMYc=;
 b=xiVHw5199HmKXsAOjssCMVsuFWusG6DrqEzzM1EhmXCqsD5qfarnz5oHJ3Esi7c9q4IO2vUhk
 5Fd52nRKojmBVQKEJF5MYGEkmW+QeOfHqB2Tu/ZJ9MIKpxS0THNEGAK
X-Developer-Key: i=mattathias.pinchover@uber.com; a=ed25519;
 pk=6Bh6OEwWiU6dpON0CVcoipq8fXtEgvhsM1Tmm9CTmtY=
X-Endpoint-Received: by B4 Relay for mattathias.pinchover@uber.com/20261113 with auth_id=1515
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update DAMON design document for the newly added DAMOS stat,
sz_ops_filter_passed_last.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Mattathias Pinchover <mattathias.pinchover@uber.com>
---
 Documentation/mm/damon/design.rst | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/mm/damon/design.rst b/Documentation/mm/damon/design.rst
index b676be697158..41e56af84d45 100644
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

-- 
2.54.0-uber3

