From: Thomas Prescher <thomas.prescher@cyberus-technology.de>
Subject: [PATCH 0/2] Add a command line option that enables control of how
 many threads per NUMA node should be used to allocate huge pages.
Date: Fri, 21 Feb 2025 14:49:02 +0100
Message-Id: <20250221-hugepage-parameter-v1-0-fa49a77c87c8@cyberus-technology.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE+EuGcC/x2M0QpAQBBFf0XzbGtNlPyKPEzcZR6wzSIl/27ze
 E6d81CCKRJ1xUOGS5PuW4aqLGhcZJvhdMpM7LnxzJVbzhlRso9isuKAObRNzWEKoxdQDqMh6P1
 P++F9P6ZOKcZkAAAA
X-Change-ID: 20250221-hugepage-parameter-e8542fdfc0ae
To: Jonathan Corbet <corbet@lwn.net>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Thomas Prescher <thomas.prescher@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740145745; l=1895;
 i=thomas.prescher@cyberus-technology.de; s=20250221;
 h=from:subject:message-id; bh=UalauN8XWtUsTEbYj+PKqhYtpX3u+/YFSuhA5nmw7d8=;
 b=JfCkdFsZg1zFxVgHw1RR2OOZrwWQQ4+CJPZufzTC/zoCX918Y1i8T5b22UG2JM5RDv9J1D80m
 Uwxd5zbJJTADWO9UMhCRe7u8qHjPlCmGfjpSD4XvLx4UDMa4ecmxOg0
X-Developer-Key: i=thomas.prescher@cyberus-technology.de; a=ed25519;
 pk=T5MVdLVCc/0UUyv5IcSqGVvGcVkgWW/KtuEo2RRJwM8=
X-Endpoint-Received: by B4 Relay for thomas.prescher@cyberus-technology.de/20250221 with auth_id=345
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allocating huge pages can take a very long time on servers
with terabytes of memory even when they are allocated at
boot time where the allocation happens in parallel.

The kernel currently uses a hard coded value of 2 threads per
NUMA node for these allocations. This value might have been good
enough in the past but it is not sufficient to fully utilize
newer systems.

This patch allows to override this value.

We tested this on 2 generations of Xeon CPUs and the results
show a big improvement of the overall allocation time.

+--------------------+-------+-------+-------+-------+-------+
| threads per node   |   2   |   4   |   8   |   16  |    32 |
+--------------------+-------+-------+-------+-------+-------+
| skylake 4node      |   44s |   22s |   16s |   19s |   20s |
| cascade lake 4node |   39s |   20s |   11s |   10s |    9s |
+--------------------+-------+-------+-------+-------+-------+

On skylake, we see an improvment of 2.75x when using 8 threads,
on cascade lake we can get even better at 4.3x when we use
32 threads per node.

This speedup is quite significant and users of large machines
like these should have the option to make the machines boot
as fast as possible.

Signed-off-by: Thomas Prescher <thomas.prescher@cyberus-technology.de>
---
Thomas Prescher (2):
      mm: hugetlb: add hugetlb_alloc_threads cmdline option
      mm: hugetlb: log time needed to allocate hugepages

 Documentation/admin-guide/kernel-parameters.txt |  7 +++
 Documentation/admin-guide/mm/hugetlbpage.rst    |  9 +++-
 mm/hugetlb.c                                    | 59 ++++++++++++++++++-------
 3 files changed, 58 insertions(+), 17 deletions(-)
---
base-commit: 334426094588f8179fe175a09ecc887ff0c75758
change-id: 20250221-hugepage-parameter-e8542fdfc0ae

Best regards,
-- 
Thomas Prescher <thomas.prescher@cyberus-technology.de>

