From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH 0/3] mm: support splitting mappingless swapcache folios
Date: Wed, 05 Aug 2026 16:48:23 +0530
Message-Id: <20260805-b4-mappingless-swapcache-v1-0-b1d78ba257ca@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP8bc2oC/yXMTQ6CQAxA4auQrm3CFOLfVYyLzlCgRsfJVNCEc
 HdGXX6L9xYwySoG52qBLLOaPmOB21UQRo6DoHbFQDXt6wMR+hYfnJLG4S5maG9OgcMoePLc9Y4
 a1xwZSp6y9Pr5rS/Xv23yNwmv7w/WdQOr4E30fAAAAA==
X-Change-ID: 20260722-b4-mappingless-swapcache-9badf123138a
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Barry Song <baohua@kernel.org>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Shuah Khan <shuah@kernel.org>, Nico Pache <nico.pache@linux.dev>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785928706; l=2322;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=MU5empUMl3yldn/ojRHKh06PTEKGbPUZ4kS1eWRJoVY=;
 b=h7y3Pjsg4r+NdPMicPmvEWMC2Ho6ZdL0IIy0BTtTOeVECkZ/mZLDLYhfb2ahKy3FOQMnebkaH
 flAUIWn8AC6DVQVxGuodSOCJ5ZwParkiGLGybn9or1t3EVrTEdorstP
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Large shmem folios lose their address-space mapping when they are written
to swap, but remain valid members of the swap cache. Folios read from swap
but not yet associated with an anon_vma can have the same mappingless
swapcache state. folio_check_splittable() currently mistakes both cases for
truncation and rejects the split with -EBUSY.

Implement the longstanding TODO for this state. Allow mappingless
swapcache folios to use the existing uniform order-0 swapcache split path,
while continuing to reject truly truncated folios and unsupported
higher-order or non-uniform swapcache splits.

memory_failure() is one caller affected by the restriction: it cannot
isolate a poisoned base page within a mappingless swapcache THP. The
end-to-end test uses this case to exercise the complete shmem pageout,
swapcache split, and swapin path.

The first patch contains the MM implementation. The second adds focused
KUnit coverage for the split eligibility checks. The third adds the
end-to-end hwpoison selftest, which pages out a shmem THP, poisons a tail
page, and verifies both isolation and the data read back from swap.

Tests:
  - The split_hwpoison_swapcache kselftest passes under x86_64 QEMU
      using virtme-ng 1.41 (2 GiB RAM, 4 KiB pages). 

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Shivam Kalra (3):
      mm/huge_memory: allow splitting mappingless swapcache folios
      mm: add KUnit coverage for mappingless swapcache folios
      selftests/mm: test hwpoison recovery of mappingless swapcache THPs

 mm/Kconfig                                         |  14 ++
 mm/Makefile                                        |   1 +
 mm/huge_memory.c                                   |  18 +-
 mm/tests/folio_split_kunit.c                       |  52 ++++
 tools/testing/selftests/mm/Makefile                |   2 +
 tools/testing/selftests/mm/run_vmtests.sh          |   1 +
 .../selftests/mm/split_hwpoison_swapcache.sh       |  57 +++++
 .../selftests/mm/split_hwpoison_swapcache_test.c   | 261 +++++++++++++++++++++
 8 files changed, 395 insertions(+), 11 deletions(-)
---
base-commit: 0b53bff4fa05ff0d3ffbd3d3bb10fae69dfab498
change-id: 20260722-b4-mappingless-swapcache-9badf123138a

Best regards,
--  
Shivam Kalra <shivamkalra98@zohomail.in>

