From: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
Date: Wed, 07 May 2025 15:28:06 +0200
Subject: [PATCH v5] mm: mmap: map MAP_STACK to VM_NOHUGEPAGE only if THP is
 enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250507-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v5-1-c6c38cfefd6e@kuka.com>
X-B4-Tracking: v=1; b=H4sIAOVfG2gC/63PzWrDMAwH8FcpPk/Dn3XS095jjOLZcmPS2CFOz
 UrJu8/pLqHHMIwOfyH0kx8k4xQwk9PhQSYsIYcUa1BvB2I7Ey8IwdVMOOWKSt7AYMa1znk2toc
 5QRnOMXW3C46mTqd4vUPwMHcjhAwYzfcVHViU1DCHtFWO1N3jhD78PN3Pr5q7kOc03Z9nFLZ2/
 0RF+U6xMKiPCWuPQlqn2Ed/6827TQNZwcK3yHEvwoGCZ8xTq1vZaP6CiC2i9yKi/qShLW+9oM5
 r/4LIf0FkRWQjtG0Ft9yIDbIsyy/9iVPGKAIAAA==
X-Change-ID: 20250428-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-ce40a1de095d
To: lorenzo.stoakes@oracle.com
Cc: Liam.Howlett@oracle.com, akpm@linux-foundation.org, 
 yang@os.amperecomputing.com, david@redhat.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746624491; l=4009;
 i=Ignacio.MorenoGonzalez@kuka.com; s=20220915; h=from:subject:message-id;
 bh=KRtim3yfth2l4PHic4jekA4cmgo5wuFooLe0ZbE9+RI=;
 b=FiOh6lew9Hv1XHsuhoxjwZdijxRDLbIWX9cpBYSWYVXzDW5CLDt21UWHU0wikslAeX5CwFivm
 fDJFj/UjWKTAkzDTmzlAaAYzx5fSBK77NOPaTPE0rCUTw3XUJo1XSkF
X-Developer-Key: i=Ignacio.MorenoGonzalez@kuka.com; a=ed25519;
 pk=j7nClQnc5Q1IDuT4eS/rYkcLHXzxszu2jziMcJaFdBQ=
X-Endpoint-Received: by B4 Relay for Ignacio.MorenoGonzalez@kuka.com/20220915 with auth_id=391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

commit c4608d1bf7c6 ("mm: mmap: map MAP_STACK to VM_NOHUGEPAGE") maps
the mmap option MAP_STACK to VM_NOHUGEPAGE. This is also done if
CONFIG_TRANSPARENT_HUGEPAGE is not defined. But in that case, the
VM_NOHUGEPAGE does not make sense.

I discovered this issue when trying to use the tool CRIU to checkpoint
and restore a container. Our running kernel is compiled without
CONFIG_TRANSPARENT_HUGEPAGE. CRIU parses the output of
/proc/<pid>/smaps and saves the "nh" flag. When trying to restore the
container, CRIU fails to restore the "nh" mappings, since madvise()
MADV_NOHUGEPAGE always returns an error because
CONFIG_TRANSPARENT_HUGEPAGE is not defined.

Fixes: c4608d1bf7c6 ("mm: mmap: map MAP_STACK to VM_NOHUGEPAGE")
Cc: stable@vger.kernel.org
Reviewed-by: Lorenzo Stoakes <lorenzo.stoakes@oracle.com>
Reviewed-by: Yang Shi <yang@os.amperecomputing.com>
Reviewed-by: Liam R. Howlett <Liam.Howlett@oracle.com>
Signed-off-by: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
---
I discovered this issue when trying to use the tool CRIU to checkpoint
and restore a container. Our running kernel is compiled without
CONFIG_TRANSPARENT_HUGEPAGE. CRIU parses the output of /proc/<pid>/smaps
and saves the "nh" flag. When trying to restore the container, CRIU
fails to restore the "nh" mappings, since madvise() MADV_NOHUGEPAGE
always returns an error because CONFIG_TRANSPARENT_HUGEPAGE is not
defined.

The mapping MAP_STACK -> VM_NOHUGEPAGE was introduced by commit
c4608d1bf7c6 ("mm: mmap: map MAP_STACK to VM_NOHUGEPAGE") in order to
fix a regression introduced by commit efa7df3e3bb5 ("mm: align larger
anonymous mappings on THP boundaries"). The change introducing the
regression (efa7df3e3bb5) was limited to THP kernels, but its fix
(c4608d1bf7c6) is applied without checking if THP is set.

The mapping MAP_STACK -> VM_NOHUGEPAGE should only be applied if THP is
enabled.
---
Changes in v5:
- Correct typo CONFIG_TRANSPARENT_HUGETABLES -> CONFIG_TRANSPARENT_HUGEPAGE in patch description
- Link to v4: https://lore.kernel.org/r/20250507-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v4-1-4837c932c2a3@kuka.com

Changes in v4:
- Correct typo CONFIG_TRANSPARENT_HUGETABLES -> CONFIG_TRANSPARENT_HUGEPAGE
- Copy description from cover letter to commit description
- Link to v3: https://lore.kernel.org/r/20250507-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v3-1-80929f30df7f@kuka.com

Changes in v3:
- Exclude non-stable patch (for huge_mm.h) from this series to avoid mixing stable and non-stable patches, as suggested by Andrew.
- Extend description in cover letter.
- Link to v2: https://lore.kernel.org/r/20250506-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v2-0-f11f0c794872@kuka.com

Changes in v2:
- [Patch 1/2] Use '#ifdef' instead of '#if defined(...)'
- [Patch 1/2] Add 'Fixes: c4608d1bf7c6...'
- Create [Patch 2/2]

- Link to v1: https://lore.kernel.org/r/20250502-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v1-1-113cc634cd51@kuka.com
---
 include/linux/mman.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/include/linux/mman.h b/include/linux/mman.h
index bce214fece16b9af3791a2baaecd6063d0481938..f4c6346a8fcd29b08d43f7cd9158c3eddc3383e1 100644
--- a/include/linux/mman.h
+++ b/include/linux/mman.h
@@ -155,7 +155,9 @@ calc_vm_flag_bits(struct file *file, unsigned long flags)
 	return _calc_vm_trans(flags, MAP_GROWSDOWN,  VM_GROWSDOWN ) |
 	       _calc_vm_trans(flags, MAP_LOCKED,     VM_LOCKED    ) |
 	       _calc_vm_trans(flags, MAP_SYNC,	     VM_SYNC      ) |
+#ifdef CONFIG_TRANSPARENT_HUGEPAGE
 	       _calc_vm_trans(flags, MAP_STACK,	     VM_NOHUGEPAGE) |
+#endif
 	       arch_calc_vm_flag_bits(file, flags);
 }
 

---
base-commit: fc96b232f8e7c0a6c282f47726b2ff6a5fb341d2
change-id: 20250428-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-ce40a1de095d

Best regards,
-- 
Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>

