From: Alireza Haddadi <alireza.haddadi@it.uu.se>
Date: Mon, 09 Nov 2026 15:23:24 +0100
Subject: [PATCH] mm/filemap: let sequential faults restart mmap readahead
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-mmap-miss-v1-1-8b44b33f3358@it.uu.se>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwML3dzcxALd3MziYt2kNNNEUwOgmEVqkhJQfUFRalpmBdis6NjaWgB
 ICNwhWwAAAA==
X-Change-ID: 20261108-mmap-miss-bf5a501088eb
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Jan Kara <jack@suse.cz>, Andrew Morton <akpm@linux-foundation.org>, 
 Vishal Moola <vishal.moola@gmail.com>, fujunjie <fujunjie1@qq.com>
Cc: linux-fsdevel@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Alireza Haddadi <alireza.haddadi@it.uu.se>, 
 Roman Gushchin <roman.gushchin@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794234210; l=6499;
 i=alireza.haddadi@it.uu.se; s=20261109; h=from:subject:message-id;
 bh=VesPRu4IT/ZtoA3aVaKTwKE/1K7QAS1jhjR+g2t6EGk=;
 b=Sy7KY/luAQ5Aohpe/Z/EdT8wc3l94GWWHUgSNGSFsVIL63SJOdCymXf/zizlciRttGQrO8eZW
 QildE77yaXXDKJY58RkrHHDCcxJV9LG1Qmi8uh3KQ4O3K/+lJ6jKbF+
X-Developer-Key: i=alireza.haddadi@it.uu.se; a=ed25519;
 pk=xbyB5yIjo8Ef+o8CJo4XbAn95znJPGlxM66RW0Y71Wk=
X-Endpoint-Received: by B4 Relay for alireza.haddadi@it.uu.se/20261109 with auth_id=1460
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After commit 0b9c0aeba938 ("mm/filemap: count only the faulting address
as a mmap hit"), once a file's mmap_miss goes over MMAP_LOTSAMISS it can
stay there until the file is closed.

With mmap_miss over the limit, do_sync_mmap_readahead() reads only the
page that faulted. Since nothing gets read ahead, no later fault can
land on a page that readahead brought in. In turn filemap_map_pages()
never counts a hit, and the counter never comes back down. From then
on every fault on the file reads only a single page, even when the
access has become sequential.

I ran into this on v7.3 with llama.cpp, where a model larger than its
memory limit sometimes ended up being read 4 KiB at a time, but other
programs hit it as well. Anything that does some random reads and then
reads the same open file in order faces the same problem. I tested the
following:

 - SQLite with mmap_size set, 300 random lookups followed by a full scan
   of a 1.8 GiB table. The scan took 9.3-14.2 s instead of 2.1 s in 8 of
   10 runs.

 - numpy.memmap, 1000 random rows sampled from the first 75% of a 4 GiB
   array and then the last 25% read sequentially, as a training and
   evaluation loop would do. The sequential part took 3.3 s instead of
   0.3 s in 5 of 5 runs.

Give a sequential reader a way back. When readahead is off and the page
before the faulting one is in the page cache, read the next page too
and mark it with PG_readahead. A sequential reader faults on that page
next, which starts async readahead. That path is not gated by mmap_miss,
and the pages it brings in count as hits again, so the counter drops
and readahead resumes. A random reader, however, rarely has the previous
page cached, so it keeps reading one page per fault, or at most two.
Forced THP readahead is left as it is.

This reproducer takes 100 random faults on a file of at least 4 GiB
and then reads 1 GiB of it in order:

	#define _GNU_SOURCE
	#include <fcntl.h>
	#include <stdio.h>
	#include <stdlib.h>
	#include <unistd.h>
	#include <sys/mman.h>
	#include <sys/resource.h>

	/* ./a.out FILE N: N random faults, then read 1 GiB in order */
	int main(int argc, char **argv)
	{
		long G = 1L << 30, i, flt, size;
		struct rusage ru;
		volatile char *p;
		int fd;

		if (argc != 3 || (fd = open(argv[1], O_RDONLY)) < 0)
			return 2;
		size = lseek(fd, 0, SEEK_END);
		posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
		p = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, 0);

		/* N random faults beyond 3 GiB */
		for (i = 0; i < atol(argv[2]); i++)
			p[3 * G + random() % (size - 3 * G) / 4096 * 4096];

		/* then read [2 GiB, 3 GiB) in order */
		getrusage(RUSAGE_SELF, &ru);
		flt = ru.ru_majflt;
		for (i = 2 * G; i < 3 * G; i += 4096)
			p[i];
		getrusage(RUSAGE_SELF, &ru);
		printf("%ld major faults for %ld pages\n",
		       ru.ru_majflt - flt, G / 4096);
		return 0;
	}

	$ ./a.out FILE 100
	before: 262144 major faults for 262144 pages
	after:       2 major faults for 262144 pages

I also ran the access patterns from that commit's changelog (random,
strides of 1021, 1024, 2053, and 4099 pages, and sequential, on a
20 GiB and a 4 GiB file in an 8 GiB guest). With this change, bytes
read stay within 0.1% and times within 3% in all cases, so its gains
are kept.

Fixes: 0b9c0aeba938 ("mm/filemap: count only the faulting address as a mmap hit")
Signed-off-by: Alireza Haddadi <alireza.haddadi@it.uu.se>
Cc: fujunjie <fujunjie1@qq.com>
Cc: Jan Kara <jack@suse.cz>
Cc: Vishal Moola <vishal.moola@gmail.com>
Cc: Matthew Wilcox (Oracle) <willy@infradead.org>
Cc: Roman Gushchin <roman.gushchin@linux.dev>
---
Tested on mm-new (x86-64):

 - With the patch, no run gets stuck: the SQLite scan (10 runs) and
   the numpy pass (5 runs) take as long as their controls.
 - mm selftests: no new failures. droppable fails about once in 20
   runs, with and without this patch.
 - A KVM guest with KASAN, lockdep and DEBUG_VM ran the reproducer
   above, strided and interleaved access, and a 4-thread test: after
   200 random faults, 4 threads read the same file in order through
   one mapping, so they all take the new path at once; the file is
   twice the guest's memory, so this runs under reclaim. No reports,
   with or without the patch.
 - W=1 and sparse are clean, also with THP or LRU_GEN disabled.

The cost for random readers, once readahead is off: when every third
page is cached and each access lands just after a cached page, 1.77
pages are read per access instead of 0.89. Strided access reads the
same as before.

Forced THP readahead has a similar problem with mmap_miss. I left it
out to keep this change small and will look at it separately.

I can share the benchmark scripts (SQLite, numpy, the access patterns
of 0b9c0aeba938) if that helps.
---
 mm/filemap.c | 27 ++++++++++++++++++++++++++-
 1 file changed, 26 insertions(+), 1 deletion(-)

diff --git a/mm/filemap.c b/mm/filemap.c
index 93db8fc60ae0..0930aacee9fe 100644
--- a/mm/filemap.c
+++ b/mm/filemap.c
@@ -3403,8 +3403,33 @@ static struct file *do_sync_mmap_readahead(struct vm_fault *vmf)
 		 * Do we miss much more than hit in this file? If so,
 		 * stop bothering with read-ahead. It will only hurt.
 		 */
-		if (mmap_miss > MMAP_LOTSAMISS)
+		if (mmap_miss > MMAP_LOTSAMISS) {
+			struct folio *prev = NULL;
+
+			/*
+			 * Nothing is read ahead now, so mmap_miss stays high
+			 * forever.  If the previous page is cached, this may be
+			 * a sequential read: read the next page as well and
+			 * mark it, so that async readahead, which does not
+			 * check mmap_miss, restarts when the mark is hit.  The
+			 * pages it reads then count as hits and lower
+			 * mmap_miss.  A random reader rarely has the previous
+			 * page cached and keeps reading one page per fault.
+			 */
+			if (!force_thp_readahead && vmf->pgoff)
+				prev = xa_load(&mapping->i_pages,
+					       vmf->pgoff - 1);
+			if (prev && !xa_is_value(prev)) {
+				fpin = maybe_unlock_mmap_for_io(vmf, fpin);
+				ra->start = vmf->pgoff;
+				ra->size = 2;
+				ra->async_size = 1;
+				ra->order = 0;
+				ractl._index = ra->start;
+				page_cache_ra_order(&ractl, ra);
+			}
 			return fpin;
+		}
 	}
 
 	if (force_thp_readahead) {

---
base-commit: b95f8bb86713c860ce8536d22a988b949b884d5f
change-id: 20261108-mmap-miss-bf5a501088eb

Best regards,
--  
Alireza Haddadi <alireza.haddadi@it.uu.se>

