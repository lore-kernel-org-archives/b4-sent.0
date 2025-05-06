From: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
Subject: [PATCH v2 0/2] Map MAP_STACK to VM_NOHUGEPAGE only if THP is
 enabled
Date: Tue, 06 May 2025 15:44:31 +0200
Message-Id: <20250506-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v2-0-f11f0c794872@kuka.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD8SGmgC/52OQQqDMBBFryJZd0oStbRd9R5FJE1GHaxJSFQq4
 t0b7Q3K8BdvGP6blUUMhJHds5UFnCmSswnkKWO6U7ZFIJOYSS5LXsgrDMrvqeOodA+jg3moreu
 mFr1K186+F6AGxs4DRUCrXm80oLHgShjkt9Kw1O0DNvQ5vM8qcUdxdGE53pjFvv0ZSy7/NM4C0
 ohc60teaFOKRz/16qzdwKpt274ztqPr+QAAAA==
X-Change-ID: 20250428-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-ce40a1de095d
To: lorenzo.stoakes@oracle.com
Cc: Liam.Howlett@oracle.com, akpm@linux-foundation.org, 
 yang@os.amperecomputing.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>, 
 stable@vger.kernel.org, Matthew Wilcox <willy@infradead.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746539072; l=1539;
 i=Ignacio.MorenoGonzalez@kuka.com; s=20220915; h=from:subject:message-id;
 bh=ilPU3kHXp7rUlXp/tVdwQH8b/OLryQpTRvXT0OKoe/o=;
 b=YUAyBvIkP4DkqhnQf03JeOpLsT887STIasmrXklw3hNcbYHWZSK/cPM1iclzn05/yf40kFG17
 lWLf5vFUOilCBLR+PlXFl2odw5ukLe/nHo8dQFyt+ou8jr8/8rdsO8u
X-Developer-Key: i=Ignacio.MorenoGonzalez@kuka.com; a=ed25519;
 pk=j7nClQnc5Q1IDuT4eS/rYkcLHXzxszu2jziMcJaFdBQ=
X-Endpoint-Received: by B4 Relay for Ignacio.MorenoGonzalez@kuka.com/20220915 with auth_id=391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

... and make setting MADV_NOHUGEPAGE with madvise() into a no-op if THP
is not enabled.

I discovered this issue when trying to use the tool CRIU to checkpoint
and restore a container. Our running kernel is compiled without
CONFIG_TRANSPARENT_HUGETABLES. CRIU parses the output of
/proc/<pid>/smaps and saves the "nh" flag. When trying to restore the
container, CRIU fails to restore the "nh" mappings, since madvise()
MADV_NOHUGEPAGE always returns an error because
CONFIG_TRANSPARENT_HUGETABLES is not defined.

These patches:
- Avoid mapping MAP_STACK to VM_NOHUGEPAGE if !THP
- Avoid returning an error when calling madvise() with MADV_NOHUGEPAGE
  if !THP

Signed-off-by: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
---
Changes in v2:
- [Patch 1/2] Use '#ifdef' instead of '#if defined(...)'
- [Patch 1/2] Add 'Fixes: c4608d1bf7c6...'
- Create [Patch 2/2]

- Link to v1: https://lore.kernel.org/r/20250502-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v1-1-113cc634cd51@kuka.com

---
Ignacio Moreno Gonzalez (2):
      mm: mmap: map MAP_STACK to VM_NOHUGEPAGE only if THP is enabled
      mm: madvise: no-op for MADV_NOHUGEPAGE if THP is disabled

 include/linux/huge_mm.h | 6 ++++++
 include/linux/mman.h    | 2 ++
 2 files changed, 8 insertions(+)
---
base-commit: fc96b232f8e7c0a6c282f47726b2ff6a5fb341d2
change-id: 20250428-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-ce40a1de095d

Best regards,
-- 
Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>

