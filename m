From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH v3 0/2] libnvdimm/labels: two on-media validation fixes in
 __nd_label_validate()
Date: Wed, 24 Jun 2026 01:03:44 -0500
Message-Id: <20260624-b4-disp-d8279485-v3-0-cdb6cab28b41@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEBzO2oC/x3MTQqAIBBA4avErBtIM3+6SrTInGo2JgoRRHdPW
 n6L9x4olJkKjM0DmS4ufMaKvm1gPZa4E3KoBtlJ3Wmp0CsMXBIGK41TdkDhB7d5vRgrHNQsZdr
 4/pfT/L4frMyAZ2IAAAA=
To: Dave Jiang <dave.jiang@intel.com>, Dan Williams <djbw@kernel.org>, 
 Vishal Verma <vishal.l.verma@intel.com>, Ira Weiny <iweiny@kernel.org>
Cc: Alison Schofield <alison.schofield@intel.com>, nvdimm@lists.linux.dev, 
 David Laight <david.laight.linux@gmail.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782281024; l=2655;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=L8Sqgnf8uN3wM5yGArKu/lhmaHR3yE4CYwBxApOTw/g=;
 b=5RXIvnD8J7x5fbfvBUQb7P8JRbME0qUD7DDe60KUsqBq0d/qEMNQEyDgITlkTq5IkXxCC+5M0
 YNCs6EWDDECCCwZ3UfdGHMNo8N+nWwZjCgplBvJxidDKWZvqYo8p8WD
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__nd_label_validate() reads several index fields straight from the label
storage medium.  This series fixes two of them.

Patch 1 (the original report): the bound multiplies the on-media nslot by the
label size in 32 bits, which wraps, so a crafted nslot passes the config_size
check and then drives an out-of-bounds memset in nd_label_data_init().
Evaluate the product in 64 bits.  Tagged for stable.

Patch 2: the v1.2 label size is computed as 1 << (7 + labelsize), where
labelsize is a u8 from the medium; a value of 24 or more makes the shift
undefined.  Reject labelsize > 1 before the shift.

v3: Drop the "cap nslot at 64K" patch from v2.  A closer reading -- and the
    Sashiko AI review -- showed it was wrong on both counts: the allocation in
    nd_label_data_init() is kvzalloc(config_size), not nslot-derived, so the
    cap shrinks nothing; and the kernel itself writes nslot =
    nvdimm_num_label_slots() on init, which exceeds 64K once config_size is
    above ~8.4MB, so the cap would reject a freshly-formatted large device on
    the next probe -- a self-brick.  Patch 1's exact 64-bit bound already
    closes the overflow.  Replaced it with the labelsize-shift fix the same
    review surfaced.
    v2: https://lore.kernel.org/all/20260623-b4-disp-1f2c537a-v2-0-59af73f1f090@proton.me/
    v1: https://lore.kernel.org/all/20260620-b4-disp-7f43b155-v1-1-0cfd8017f7a0@proton.me/

Verified -m64 and -m32: patch 1's 64-bit bound agrees with an exact
divide-based check, and an out-of-tree module mirroring nd_label_data_init()
reproduces the KASAN slab-out-of-bounds write unpatched and is clean when
patched.
A boundary truth table confirms the self-brick the v2 cap would have caused
(kernel nslot > 64K for config_size > ~8.4MB) and that rejecting labelsize > 1
removes the undefined shift while keeping the two valid sizes.  Harness
available on request.

A negative ndctl test (test/label-compat.sh) will follow separately, per
Alison's suggestion.  With the nslot cap dropped it now covers two vectors
rather than one: an oversize nslot for patch 1 and an oversize labelsize for
patch 2.

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Bryam Vargas (2):
      libnvdimm/labels: Prevent integer overflow in __nd_label_validate()
      libnvdimm/labels: Bound the on-media label size before the shift

 drivers/nvdimm/label.c | 17 ++++++++++++++---
 1 file changed, 14 insertions(+), 3 deletions(-)
---
base-commit: 502d801f0ab03e4f32f9a33d203154ce84887921
change-id: 20260624-b4-disp-d8279485-1b59fb6a7819

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

