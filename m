From: Mattathias Pinchover <mattathias.pinchover@uber.com>
Subject: [PATCH 0/6] mm/damon: add sz_ops_filter_passed_last DAMOS stat
Date: Mon, 16 Nov 2026 19:10:03 +0000
Message-Id: <20261116-damon-sz-ops-b4-v1-0-1cffe7227e6d@uber.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAxV+2oC/yXMQQqDMBBA0avIrB1ojLbiVcSFScZ2BBPJ2CKKd
 zfa5Vv8v4NQZBJosh0i/Vg4+ASVZ2A/vX8TskuG4lE8lVIaXT8Fj7JhmAVNibquXmTcYKytIFV
 zpIHX+9h2f8vXjGSXawPHcQJT4AiccwAAAA==
X-Change-ID: 20261113-damon-sz-ops-b4-3857ebdfbcc5
To: SJ Park <sj@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: damon@lists.linux.dev, linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Mattathias Pinchover <mattathias.pinchover@uber.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794856219; l=4336;
 i=mattathias.pinchover@uber.com; s=20261113; h=from:subject:message-id;
 bh=KL42jbLaW3+y5f9RJAaNYDZJo0sdCvb1DZpH27JUO/U=;
 b=X9esLWMWkEhP4E6HhN3S5Vq1gM1ODJaamqF71Hoem0y6pvT2abvY3Er0xEBNSKZ7w2J0tLt/U
 YB1QuY6pfvcBlG4mMNCzzo36wzxj0nqCDXe39JwX0dq2/1MnUCc+KlO
X-Developer-Key: i=mattathias.pinchover@uber.com; a=ed25519;
 pk=6Bh6OEwWiU6dpON0CVcoipq8fXtEgvhsM1Tmm9CTmtY=
X-Endpoint-Received: by B4 Relay for mattathias.pinchover@uber.com/20261113 with auth_id=1515
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DAMOS stat sz_ops_filter_passed shows the total bytes that passed
operations layer-handled DAMOS filters, accumulated from the beginning
of the scheme's execution.  Users who want the amount for only the
latest apply interval, e.g., the size of a workload's anonymous memory
that is cold as of now, have to keep the previous value in user space
and compute the difference.  To know how many apply intervals a
difference covers, they have to rely on nr_snapshots.  But nr_snapshots
is increased once per target per apply interval, so the computation is
complicated for contexts having multiple targets.

This series introduces a new DAMOS stat, sz_ops_filter_passed_last.  It
shows the amount of sz_ops_filter_passed increase in the last apply
interval of the scheme.  It is updated at the end of each apply
interval, and kept unchanged until the next apply interval is
completed.  Like the other DAMOS stats, it is exposed under the stats/
directory of the scheme in the DAMON sysfs interface, and refreshed
together with the other stats when refresh_ms expires or
update_schemes_stats is written.

Patches sequence
================

Patch 1 introduces the stat to the DAMON core.  Patch 2 exposes it via
the DAMON sysfs interface.  Patch 3 adds a kunit test.  Patches 4-6
update the design, usage, and ABI documents, respectively.

Tests
=====

I ran the DAMON kunit tests (all 50 pass, including the new one), built
mm/damon/ with W=1 (no warnings), built htmldocs (no new warnings
compared to mm-new), and ran checkpatch.pl --strict on the patches (it
reports a warning and an error on each patch because it does not
recognize the Assisted-by tag, and four alignment checks on patches 2
and 3 for the continuation line alignment that the existing DAMON code
uses).

I also ran the DAMON selftests in a QEMU VM without KVM, on mm-new and
on mm-new with this series.  On mm-new, 12 tests pass, 2 fail
(sysfs_update_schemes_tried_regions_wss_estimation.py and
damos_tried_regions.py), and 1 is skipped (sysfs_memcg_path_leak.sh,
because kmemleak is not available).  With this series, 13 pass, 1 fails
(the wss_estimation one), and the same one is skipped, so I saw no
failure that mm-new does not also have.

None of the selftests read the new stat, so I also checked it on a
live kernel.  In the same kind of VM running this series, I started two
Docker containers, each running a Python process that allocates 512 MiB
and 2 GiB of anonymous memory and then holds it.  Each process was
monitored by its own kdamond, using the vaddr operations set and a
stat scheme with an anon operations layer filter, with refresh_ms set
to 1000.  Output from sz_ops_filter_passed_last was correct:

    # cd /sys/kernel/mm/damon/admin/kdamonds
    # cat 0/contexts/0/schemes/0/stats/sz_ops_filter_passed_last
    546385920
    # cat 1/contexts/0/schemes/0/stats/sz_ops_filter_passed_last
    2157043712

Tool use
========

Claude (Anthropic) assisted with the code, kunit test, documents, and
changelogs of this series, as noted by the Assisted-by: tags.  I
reviewed all of it and ran the tests listed above.

Signed-off-by: Mattathias Pinchover <mattathias.pinchover@uber.com>
---
Mattathias Pinchover (6):
      mm/damon/core: introduce sz_ops_filter_passed_last stat
      mm/damon/sysfs-schemes: add sz_ops_filter_passed_last file
      mm/damon/tests/core-kunit: test sz_ops_filter_passed_last
      Docs/mm/damon/design: update for sz_ops_filter_passed_last
      Docs/admin-guide/mm/damon/usage: update for sz_ops_filter_passed_last
      Docs/ABI/damon: update for sz_ops_filter_passed_last

 Documentation/ABI/testing/sysfs-kernel-mm-damon |  7 ++
 Documentation/admin-guide/mm/damon/usage.rst    |  6 +-
 Documentation/mm/damon/design.rst               |  9 +++
 include/linux/damon.h                           |  6 ++
 mm/damon/core.c                                 |  5 ++
 mm/damon/sysfs-schemes.c                        | 17 +++++
 mm/damon/tests/core-kunit.h                     | 92 +++++++++++++++++++++++++
 7 files changed, 139 insertions(+), 3 deletions(-)
---
base-commit: 67f3b04b277373438f17300e056306adbd9edf7b
change-id: 20261113-damon-sz-ops-b4-3857ebdfbcc5

Best regards,
--  
Mattathias Pinchover <mattathias.pinchover@uber.com>

