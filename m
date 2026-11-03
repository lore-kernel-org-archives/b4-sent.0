From: Mani Tofigh <mt4022@columbia.edu>
Subject: [PATCH v2 0/2] mm/hugetlb: clear the hugetlb flag before leaking a
 hwpoisoned folio
Date: Tue, 03 Nov 2026 16:00:48 -0500
Message-Id: <20261103-hugetlb-hwpoison-leak-v2-0-98085750c145@columbia.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNSw6CMBRFt0I69pl++MUR+zAMaHnSp0hJS1FD2
 LuAC3B4knPPXVhATxjYJVmYx5kCuWEDeUqYsc3QIVC7MZNc5oLLEmzscOo12NfoKLgBemweoMt
 WpanKRSoU27ajxxu9j+61/nGI+o5m2mO7YSlMzn+O41ns3r+PWYCAojCY5ZzLTKrKuD4+NTVnb
 COr13X9AjoMILHPAAAA
X-Change-ID: 20261028-hugetlb-hwpoison-leak-b8d344361413
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Miaohe Lin <linmiaohe@huawei.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Naoya Horiguchi <nao.horiguchi@gmail.com>, 
 Matthew Wilcox <willy@infradead.org>, Jane Chu <jane.chu@oracle.com>, 
 Zi Yan <ziy@nvidia.com>, Kaitao Cheng <kaitao.cheng@linux.dev>, 
 Mike Rapoport <rppt@kernel.org>, Mike Kravetz <mike.kravetz@oracle.com>, 
 Yu Zhao <yuzhao@google.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793739649; l=1890;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=Pt9krYX8CsGOTLKtcfpUYXNuinBo/7tPW4KlvXKyiEA=;
 b=02MqQBVkEqAHUZSGVcKHoKLwHhvp4MXoLv73o/U6clby1qlWMLDJX7szSHzPoTqqIJrGoAfBq
 CFQP0xoTxDpAE+YMJFHC0wllKhbMVCv/tSdEtxCu8bk2Xkz7dRP9VIg
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If memory_failure() can't save the raw error page of a hugetlb folio,
the folio is marked raw_hwp_unreliable and leaked once it's freed.  With
hugetlb_free_vmemmap=on it's leaked while it's still a hugetlb folio,
and dissolving it then loops forever, e.g., when offlining its memory
block.  Patch 2 leaks it only after the hugetlb flag is cleared, as
without vmemmap optimization.

Miaohe pointed out that unpoison_memory() then doesn't see a hugetlb
folio anymore and unpoisons it.  That already happens without vmemmap
optimization, so patch 1 fixes it on its own and goes first.

Patch 2 lets a raw_hwp_unreliable folio reach the add_hugetlb_folio()
rollback when restoring its vmemmap fails, as
dissolve_free_hugetlb_folio() already does.  It relies on Kaitao's
"mm/hugetlb: preserve persistent flags when returning folios to the
pool" [1] (in mm-new) to keep the flag there.

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/hugeoffline.c

[1] https://lore.kernel.org/all/20261102024910.31486-3-kaitao.cheng@linux.dev/

Changes in v2:
- New patch 1 so unpoison_memory() refuses the leaked folio (Miaohe).
- Patch 2: same code, added Fixes: bd225530a4c7 and fixed the commit
  message (offlining still retries until a signal).
- Rebased on mm-new.
- Link to v1: https://lore.kernel.org/all/20261028-hugetlb-hwpoison-leak-v1-1-77ce56002523@columbia.edu/

---
Mani Tofigh (2):
      mm/memory-failure: don't unpoison a leaked raw_hwp_unreliable folio
      mm/hugetlb: clear the hugetlb flag before leaking a hwpoisoned folio

 mm/hugetlb.c        | 15 ++++++++-------
 mm/memory-failure.c |  9 +++++++++
 2 files changed, 17 insertions(+), 7 deletions(-)
---
base-commit: 74d73ffcffe03804f97e9fb82301dadf75671282
change-id: 20261028-hugetlb-hwpoison-leak-b8d344361413

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

