From: Thomas Prescher <thomas.prescher@cyberus-technology.de>
Subject: [PATCH v3 0/3] Add a command line option that enables control of
 how many threads should be used to allocate huge pages.
Date: Fri, 28 Feb 2025 00:02:09 +0100
Message-Id: <20250228-hugepage-parameter-v3-0-2628e9b2b5c0@cyberus-technology.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPHuwGcC/33NQQ6CMBAF0KuQrq0pBSy68h7GRZlOaROlTQuNh
 HB3CysXajKb/5P/ZiERg8VILsVCAiYbrRtyqA4FASOHHqlVORPOeMM4L6mZevQy914G+cQRA8W
 2qblWGphEkoc+oLavHb3dczY2ji7M+49Ubu1fLpWUUS3rsxQC2nxXmDsMU6Qjghncw/XzUSHZ6
 MQ/OfGV45kTqmvhpIDVTfWLW9f1DRVYK/QPAQAA
X-Change-ID: 20250221-hugepage-parameter-e8542fdfc0ae
To: Jonathan Corbet <corbet@lwn.net>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Thomas Prescher <thomas.prescher@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740697330; l=2949;
 i=thomas.prescher@cyberus-technology.de; s=20250221;
 h=from:subject:message-id; bh=77mfKSU/7bUid7o9jDTk0QDdNak1HyZH2KPQxoAjUqg=;
 b=9MUeqnBuqLbrQS5045xPrHI4IgCVsWVTUBuVD3OAtqS7we6JJlqgxV8uvskTuQNoPESsrgYVm
 o84ZIPyr5GTBHpV7LiQWNLpUR+QEgJaYo3w7hpJzfrKF5Aw7i/+vbWK
X-Developer-Key: i=thomas.prescher@cyberus-technology.de; a=ed25519;
 pk=T5MVdLVCc/0UUyv5IcSqGVvGcVkgWW/KtuEo2RRJwM8=
X-Endpoint-Received: by B4 Relay for thomas.prescher@cyberus-technology.de/20250221 with auth_id=345
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allocating huge pages can take a very long time on servers
with terabytes of memory even when they are allocated at
boot time where the allocation happens in parallel.

Before this series, the kernel used a hard coded value of 2 threads per
NUMA node for these allocations. This value might have been good
enough in the past but it is not sufficient to fully utilize
newer systems.

This series changes the default so the kernel uses 25% of the available
hardware threads for these allocations. In addition, we allow the user
that wish to micro-optimize the allocation time to override this value
via a new kernel parameter.

We tested this on 2 generations of Xeon CPUs and the results
show a big improvement of the overall allocation time.

+-----------------------+-------+-------+-------+-------+-------+
| threads               |   8   |   16  |   32  |   64  |   128 |
+-----------------------+-------+-------+-------+-------+-------+
| skylake      144 cpus |   44s |   22s |   16s |   19s |   20s |
| cascade lake 192 cpus |   39s |   20s |   11s |   10s |    9s |
+-----------------------+-------+-------+-------+-------+-------+

On skylake, we see an improvment of 2.75x when using 32 threads,
on cascade lake we can get even better at 4.3x when we use
128 threads.

This speedup is quite significant and users of large machines
like these should have the option to make the machines boot
as fast as possible.

Signed-off-by: Thomas Prescher <thomas.prescher@cyberus-technology.de>
---
Changes in v3:
- Fix log message (the name of the parameter was incorrect)
- Link to v2: https://lore.kernel.org/r/20250227-hugepage-parameter-v2-0-7db8c6dc0453@cyberus-technology.de

Changes in v2:
- the default thread value has been changed from 2 threads per node to
  25% of the available hardware threads
- the hugepage_alloc_threads parameter now specifies the total number of
  threads being used instead of threads per node
- the kernel now logs the time needed to allocate the huge pages and the
  number of threads being used
- update the documentation so that users are aware that this does not
  apply to gigantic huge pages
- Link to v1: https://lore.kernel.org/r/20250221-hugepage-parameter-v1-0-fa49a77c87c8@cyberus-technology.de

---
Thomas Prescher (3):
      mm: hugetlb: improve parallel huge page allocation time
      mm: hugetlb: add hugetlb_alloc_threads cmdline option
      mm: hugetlb: log time needed to allocate hugepages

 Documentation/admin-guide/kernel-parameters.txt |  9 ++++
 Documentation/admin-guide/mm/hugetlbpage.rst    | 10 ++++
 mm/hugetlb.c                                    | 67 +++++++++++++++++++------
 3 files changed, 70 insertions(+), 16 deletions(-)
---
base-commit: dd83757f6e686a2188997cb58b5975f744bb7786
change-id: 20250221-hugepage-parameter-e8542fdfc0ae

Best regards,
-- 
Thomas Prescher <thomas.prescher@cyberus-technology.de>

