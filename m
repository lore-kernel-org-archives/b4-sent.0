From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Subject: [PATCH RFC 0/7] Fix the load bias of objects with a non-zero link
 address
Date: Tue, 17 Nov 2026 22:36:38 +0000
Message-Id: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z2NzW7DIBCEX8Xi3JVYwGvH10h9gF6rHFhYUqokp
 GBHlaK8e50f9Tijme+7qiY1S1NTd1VVLrnlcloDvnUqfPnTXiDHNSujDSHiAOyAl73WFg7FR+D
 sG9hNYurFJo5Orc9zlZR/H9RP9fG+Vbtn2Rb+ljDfea9ZlZ9ldc6v7b9y6h5Cjf3ThrCca2GBl
 A8CJaUmM4SBXB+FYtSb6YJ3JPsmEMrxmOepI0ziySCSFu+YrDbj4AIZPxgbPeqenRtHq3a32x+
 Sw4wxCQEAAA==
X-Change-ID: 20261117-b4-bug003-load-bias-39fb65e3fbd4
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=4110;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=Pm/L8RdDiVcJkkKxYV7pmW8sToU8PyX1WZDIpNGHqbo=;
 b=stfywovjVI8UUemxpK1SIeaJKN0oQJGoR7zYsSy/QFkXrTir3SDr1c8OKenM11aVF6wOdEyV2
 9YNZ7FSSjumDI093Q0WiCEOw8VgndEyyKq7NU2dxPfHv8tKjc+wZyQb
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Posted as an RFC after a chat with Kris on IRC (2026-11-17) about the
load-bias calculations, in case it helps as a reference.  It builds on
"Fix probe placement in LLVM lld-linked objects by using file offsets"
[1]; no rush on this one until that series has been looked at.

Several places convert link-time addresses to runtime addresses using
the load address of the object's first mapping as the load bias.  That
is right only for objects linked at 0.  The bias is the first mapping's
start minus the first PT_LOAD's page-aligned p_vaddr (the gABI base
address, ld.so's l_addr): 0 for a non-PIE executable linked at 0x400000,
the mapping's start for a PIE linked at 0, and the difference for
objects linked elsewhere (GNU ld -Ttext-segment, lld --image-base).
With the first mapping's start as the bias, probes in those objects are
not created and their functions are not named.

  1-2  libproc: the fallback bias, used without ld.so's link map,
       subtracts only the low bits of p_vaddr (+ ufunc() test)
  3    libproc: add Paddr_to_load_bias()
  4-5  pid: use it for "-" probe addresses; this also fixes "-" probes
       on every PIE under -p, where MA_PIC is not yet known (+ test)
  6-7  dtprobed: subtract the first PT_LOAD's page-aligned p_vaddr from
       the base it adds to USDT note addresses (+ test)

The tests cover lld objects, hence the dependency on [1].

Tested on devel 61fea621 plus v1 of [1], building after each fix: each
test fails before its fix and passes after, and rejects a bias computed
from the containing mapping.  pid/, usdt/, begin/, end/, noresolve/ and
profile-n/ show no other change.  On dev-queue 0e93872f the tests also
fail without the series and pass with it.

dt_cg_elf_sym_to_offset() in Alan's pending uresolve() series [2] uses
the fallback formula that patch 1 replaces.

[1] https://lore.kernel.org/dtrace/20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai/
[2] https://lore.kernel.org/dtrace/20260605221217.1211791-5-alan.maguire@oracle.com/

---
Eslam Almorshdy (7):
      libproc: fix the fallback load bias for non-zero link addresses
      test: add ufunc() test for libraries with a non-zero link address
      libproc: add Paddr_to_load_bias()
      pid: use the load bias for "-" probe addresses
      test: add pid "-" probe test for -p and non-zero link addresses
      dtprobed: fix the USDT load bias for non-zero link addresses
      test: add USDT test for libraries with a non-zero link address

 dtprobed/dtprobed.c                           | 27 +++++++-
 libdtrace/dt_pid.c                            | 10 ++-
 libproc/Psymtab.c                             | 42 +++++++++++-
 libproc/libproc.h                             |  1 +
 test/unittest/pid/tst.dash-loadbias.r         |  1 +
 test/unittest/pid/tst.dash-loadbias.sh        | 95 ++++++++++++++++++++++++++
 test/unittest/pid/tst.dash-loadbias.x         | 14 ++++
 test/unittest/profile-n/tst.ufunc-loadbias.r  |  1 +
 test/unittest/profile-n/tst.ufunc-loadbias.sh | 85 ++++++++++++++++++++++++
 test/unittest/profile-n/tst.ufunc-loadbias.x  | 14 ++++
 test/unittest/usdt/tst.lib-loadbias.r         |  1 +
 test/unittest/usdt/tst.lib-loadbias.sh        | 96 +++++++++++++++++++++++++++
 test/unittest/usdt/tst.lib-loadbias.x         | 14 ++++
 13 files changed, 394 insertions(+), 7 deletions(-)
---
base-commit: 61fea621160ea4b6302874c62a723da105b44883
change-id: 20261117-b4-bug003-load-bias-39fb65e3fbd4
prerequisite-change-id: 20261015-bug001-uprobe-file-offset-c7645de6dd09:v1
prerequisite-patch-id: d5576cf337dee4c703a6e0ad59c781032fdbf3b7
prerequisite-patch-id: 288621607351e70c6a914b04494bdd2c3921ec62
prerequisite-patch-id: 2dc844beab8edb5e05b3b41b4a227365d62fc6ea
prerequisite-patch-id: b4b63ab534c3ed4380f781570ec65dc2c37e4686
prerequisite-patch-id: f3fe2289eda12cbbe9c5e2b5d5891639774d905f
prerequisite-patch-id: a9ef84a82a3940dfb7810737c4de33471a8e80d3
prerequisite-patch-id: 902233f2e3036f2d77e08e3139fe9d06beff48f9

Best regards,
--  
Eslam Almorshdy <ealmorshdy@d-matrix.ai>

