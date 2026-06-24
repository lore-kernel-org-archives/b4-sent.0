From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH v2 0/2] libnvdimm/labels: fix the nslot product overflow
 and cap the slot count
Date: Tue, 23 Jun 2026 23:19:01 -0500
Message-Id: <20260623-b4-disp-1f2c537a-v2-0-59af73f1f090@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALVaO2oC/x3MPQqAMAxA4atIZgM1av25ijjEmmqWKi2IIN7d4
 vgN7z2QJKokGIsHolya9AgZVBbgdg6boK7ZQIassVTj0uCq6cTKk2vrjrE1jnsaeBC2kLMzitf
 7X07z+359isKbYgAAAA==
To: Ira Weiny <iweiny@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dan Williams <djbw@kernel.org>, Dave Jiang <dave.jiang@intel.com>
Cc: David Laight <david.laight.linux@gmail.com>, 
 Alison Schofield <alison.schofield@intel.com>, nvdimm@lists.linux.dev, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782274741; l=2193;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=XANCZNyCbG+Ly+jntP8fH38JNMbRF1f10/kOrgQxa0Y=;
 b=F32OGyjLZ5F7QLCAS0OR0iHEqX9zcJY6j6RY95ARQHiK8tW+o8y9AjzXAfaE64PF0PgoZL4O6
 8x7xeMRIqGmDEDY6kU9hqClsiY3MhREQEexFtuKdAoPAbsDkZkvklZe
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The on-media namespace index nslot is a u32 read from the DIMM label area,
or written from userspace via ND_CMD_SET_CONFIG_DATA.  __nd_label_validate()
bounds nslot against config_size, but the product nslot * label_size is
evaluated in 32 bits and wraps, so a crafted nslot passes the check and then
drives an out-of-bounds memset in nd_label_data_init().

Patch 1 evaluates the product in 64 bits so the bound is exact; it is the
targeted fix, tagged for stable.  Patch 2 caps nslot, so a bogus
firmware-reported config_size cannot admit a large slot count -- and the large
allocation it implies -- even after the product is computed correctly.

The sibling multiply in sizeof_namespace_index() derives nslot from config_size
via nvdimm_num_label_slots(), not the on-media field, so it cannot overflow and
is left unchanged.

Verified on -m64 and -m32: the 64-bit bound agrees with an exact divide-based
check on the boundary and on randomized inputs, and the cap rejects every
wrapping one.  The same crafted nslot is an out-of-bounds write on -m32 but not
on -m64 before the fix.  An out-of-tree module mirroring nd_label_data_init()
reproduces the KASAN slab-out-of-bounds write unpatched and is clean with
either patch; harness available on request.

A negative ndctl test (test/label-compat.sh, oversize nslot) covering both
patches will follow separately, per Alison's suggestion.

v1 (single patch):
https://lore.kernel.org/all/20260620-b4-disp-7f43b155-v1-1-0cfd8017f7a0@proton.me/
v2: split the exact fix and the cap into two patches per review; the
    Reviewed-by and Suggested-by are recorded on the respective patches.

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Bryam Vargas (2):
      libnvdimm/labels: Prevent integer overflow in __nd_label_validate()
      libnvdimm/labels: reject an implausibly large on-media slot count

 drivers/nvdimm/label.c | 6 +++++-
 drivers/nvdimm/label.h | 7 +++++++
 2 files changed, 12 insertions(+), 1 deletion(-)
---
base-commit: 502d801f0ab03e4f32f9a33d203154ce84887921
change-id: 20260623-b4-disp-1f2c537a-50ca829a9ea6

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

