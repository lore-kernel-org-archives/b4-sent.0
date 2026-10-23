From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 0/5] riscv: kexec: fix kexec_file with CMA-backed segments
Date: Fri, 23 Oct 2026 15:33:13 +0800
Message-Id: <20261023-riscv-kexec-cma-fixes-v1-0-825b90ea23c4@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqCQBCF4VeRuW5AV9S2V4ku1vGYU2SxkyKI7
 95qlx+H/6xkiAqjS7ZSxKym7zGhOGUkQxjvYO2SyeWuLnJXclSTmZ9YICyvwL0uMPat1L7x51B
 JT6n9RBxDSq+3v21qH5Dvfkbb9gOHEL0ueQAAAA==
X-Change-ID: 20261023-riscv-kexec-cma-fixes-9bc69798a5cf
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Baoquan He <baoquan.he@linux.dev>, Mike Rapoport <rppt@kernel.org>, 
 Pasha Tatashin <pasha.tatashin@soleen.com>, 
 Pratyush Yadav <pratyush@kernel.org>, Yao Zi <me@ziyao.cc>
Cc: Han Gao <rabenda.cn@gmail.com>, Han Gao <gaohan@iscas.ac.cn>, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, kexec@lists.infradead.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792740795; l=1990;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=Thjxfmu56NJtgVUdSnPeX0m3Ki7icxN2HFTUo0uN07Y=;
 b=XDRVxrg/MPvhZsdxIHy3UA8cSlaAZoQOXZCJXfFOxKsAnZAwNXDEMiirk3dJXJ0NxyUn3KHzz
 ALTRjBPSRlUDwLRKSoyIDI9T86UgT2itnhAauIZ2jOmBuocOu7ukC1r
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I ran into these while doing kexec_file reboots in a loop on a Zhihe
A210 board. Things mostly worked, but every few rounds the next kernel
would hang or purgatory would spin, depending on where the segments and
the DTB happened to land. Most of it goes back to segments now being
allocated from CMA, which exposed a few assumptions that no longer hold.
They are separate bugs, so each one gets its own patch.

Patch 1 lets the RISC-V relocation code turn the MMU off even when the
entry list has no indirection page, which is the normal case with CMA.
Patch 2 fixes the purgatory relocations, which assumed a PC-relative low
part always sits right after its high part. Patches 3 and 4 are in the
generic code: CMA quietly caps the alignment below what the RISC-V
kernel needs, and the tail of CMA segment pages was never cleared even
though the purgatory digest expects zeroes there. Patch 5 reserves the
DTB early enough that a CMA pool cannot be placed on top of it.

With all five applied, the board survives repeated kexec_file reboots,
including the layouts where every segment comes from CMA.

---
Han Gao (5):
      riscv: kexec: Disable the MMU before walking the entry list
      riscv: kexec_file: Pair PC-relative low parts with their high parts
      kexec_file: Honor the segment alignment for CMA allocations
      kexec_core: Clear the unused part of CMA segments
      riscv: mm: Reserve the DTB before scanning reserved memory

 arch/riscv/kernel/kexec_relocate.S     | 29 ++++++------
 arch/riscv/kernel/machine_kexec_file.c | 84 ++++++++++++++++++++++++++--------
 arch/riscv/mm/init.c                   | 18 ++++----
 kernel/kexec_core.c                    |  6 +--
 kernel/kexec_file.c                    |  7 +++
 5 files changed, 99 insertions(+), 45 deletions(-)
---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261023-riscv-kexec-cma-fixes-9bc69798a5cf

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

