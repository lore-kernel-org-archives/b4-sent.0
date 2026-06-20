From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 20 Jun 2026 15:54:39 -0500
Subject: [PATCH] libnvdimm/labels: Prevent integer overflow in
 __nd_label_validate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-b4-disp-7f43b155-v1-1-0cfd8017f7a0@proton.me>
X-B4-Tracking: v=1; b=H4sIAA7+NmoC/x3MTQqAIBBA4avIrBuYTPu7SrRInWo2JQoRRHdPW
 n6L9x7InIQzjOqBxJdkOY+CulLg9+XYGCUUgybdUqsJncEgOWK3msbV1uKgXW/8QMZTDyWLiVe
 5/+U0v+8HL7wcnmIAAAA=
To: Dave Jiang <dave.jiang@intel.com>, Dan Williams <djbw@kernel.org>, 
 Ira Weiny <ira.weiny@intel.com>, Vishal Verma <vishal.l.verma@intel.com>
Cc: linux-kernel@vger.kernel.org, nvdimm@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781988878; l=2964;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=dMEqUebt+fSrQCUWcbCd+vcAjwiYJq6rPAxYeIr65ao=;
 b=CziGNvNLLqPwryaor2yCzelXtrjLC6gyYvlxpHufLDdJ9+9ht7obykAFld35+c9Iz1l6Jh+c9
 dbzOberahf1Cu8Pk6UzIlu+l+Oquw8NtKhrh5b8iA87ssTUqc8SZCwF
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The on-media namespace index field nslot is a u32 read from the DIMM
label storage area.  __nd_label_validate() bounds it against the config
area size, but sizeof_namespace_label() returns unsigned, so the product
nslot * label_size is evaluated in 32-bit and wraps modulo 2^32 before
the comparison.  A crafted nslot passes the bound and is then used as the
loop trip count in nd_label_data_init(), whose memset() walks off the end
of the config_size buffer: an out-of-bounds write.

The field is not trusted -- it comes from the medium, or from userspace
via ND_CMD_SET_CONFIG_DATA.  Evaluate the product in 64-bit so the bound
check is exact; conforming labels are unaffected.

Fixes: 564e871aa66f ("libnvdimm, label: add v1.2 nvdimm label definitions")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
The check was safe when introduced: 4a826c83db4e ("libnvdimm: namespace
indices: read and validate") multiplied by sizeof(struct
nd_namespace_label), a size_t, so the product was 64-bit.  564e871aa66f
replaced that with sizeof_namespace_label(), which returns unsigned, when
the label size became a runtime value -- narrowing the product to 32 bits.

The sibling multiply in sizeof_namespace_index() uses an nslot derived
from config_size (nvdimm_num_label_slots()), not the on-media field, so it
cannot overflow and is left unchanged.

Reproduced with an out-of-tree module that mirrors nd_label_data_init() --
kvzalloc(config_size), the __nd_label_validate() bound check, and the
memset loop -- since the defect is the wrapped arithmetic into the memset,
not the DIMM-probe plumbing:

Build A (without this patch), nslot = 0x02000000, 128-byte labels:
    the u32 product wraps to 0, the index is accepted, and the loop's
    memset() writes past the kvzalloc'd buffer ->
      right of the config_size region -> panic.
  Build B (with this patch): the 64-bit product exceeds config_size, the
    index is rejected, the loop never runs -> clean.
  Control (legitimate small nslot): writes stay in bounds -> clean.

BUG: KASAN: slab-out-of-bounds, Write of size 128, 0 bytes to the
---
 drivers/nvdimm/label.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/nvdimm/label.c b/drivers/nvdimm/label.c
index 4218e3ac4a2a..ec12ce72cfe2 100644
--- a/drivers/nvdimm/label.c
+++ b/drivers/nvdimm/label.c
@@ -202,7 +202,7 @@ static int __nd_label_validate(struct nvdimm_drvdata *ndd)
 		}
 
 		nslot = __le32_to_cpu(nsindex[i]->nslot);
-		if (nslot * sizeof_namespace_label(ndd)
+		if ((u64)nslot * sizeof_namespace_label(ndd)
 				+ 2 * sizeof_namespace_index(ndd)
 				> ndd->nsarea.config_size) {
 			dev_dbg(dev, "nsindex%d nslot: %u invalid, config_size: %#x\n",

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260620-b4-disp-7f43b155-92b84c904c08

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

