From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Sat, 07 Nov 2026 09:28:46 +0200
Subject: [PATCH 6.18.y] cxl/features: Ensure that count is set before
 access to ent[] __counted_by()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-cxl-features-6-18-y-v1-1-2607e151ffc2@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CQAwAv0J6tmS7wkL8CvGwlqI1Bs0WDITwd
 1c9ziQzG5gkFYNTsUGSt5o+xwx0KIBvcbwKap8ZvPOByDXIywMHidOcxDAgtbii830d64q5qY6
 Qy1eSQZfftYNQUluucP57my934em7hH3/AKUozVp/AAAA
X-Change-ID: 20261107-cxl-features-6-18-y-02d5a54cc743
To: stable@vger.kernel.org
Cc: Ashok Raj <ashok.raj@oss.qualcomm.com>, 
 Dave Jiang <dave.jiang@intel.com>, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>, 
 linux-cxl@vger.kernel.org, Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794036528; l=3408;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=kGxIhmutMPB0t26HBZzy5K5cqXcRM4FNrQBpPeExzXU=;
 b=PwQHc1r8VxRJDZam1vDQ4PStYycWRpoRAjshq4AdXhb/xvZBBP2SCA/cVsyq1jQEoXYGXGQyh
 pJwZJzcOj9TB+Vqkqe6FLNRd+bhEwH6bJQ4F8rFoc5+495VKvl/2WPz
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ashok Raj <ashok.raj@oss.qualcomm.com>

commit c1031c2474f73261d8d5e4deef2b5dc20fb964f5 upstream.

get_supported_features() assigns entries->num_features only after the
memcpy() loop that fills entries->ent[] has already run. Since ent[]
is __counted_by(num_features), the compiler's bounds instrumentation
sees a 0-length array during that loop and FORTIFY_SOURCE trips on
the memcpy. Set @num_features right after allocation, before any
write into ent[], so the bound is correct for the whole lifetime of
the array.

This was found via a fortify panic:

 memcpy: detected buffer overflow: 384 byte write of buffer size 0
 WARNING: lib/string_helpers.c:1035 at __fortify_report+0x54/0xa0
 kernel BUG at lib/string_helpers.c:1043!
 Call trace:
  __fortify_panic+0x10/0x18
  get_supported_features.isra.0+0x4a0/0x4d0 [cxl_core]
  devm_cxl_setup_features+0x84/0x120 [cxl_core]
  cxl_pci_probe+0x254/0x5e0 [cxl_pci]

Same class of bug, same fix shape as commit 6c9d2e87df40
("cxl/fwctl: Fix __fortify_panic"), which fixed the analogous issue
in cxlctl_get_supported_features() but missed this one.

[ dj: Fixed up title typo per Jonathan. ]

Fixes: f0e6a2329bf9 ("cxl: Add Get Supported Features command for kernel usage")
Signed-off-by: Ashok Raj <ashok.raj@oss.qualcomm.com>
Reviewed-by: Dave Jiang <dave.jiang@intel.com>
Reviewed-by: Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Link: https://patch.msgid.link/20260911215304.1816467-1-ashok.raj@oss.qualcomm.com
Signed-off-by: Dave Jiang <dave.jiang@intel.com>
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
On 6.18.y, cxl_pci BUG()s in __fortify_panic() while probing any device
that reports CXL Features, such as QEMU's cxl-type3, when the kernel is
built with CONFIG_FORTIFY_SOURCE and a compiler that supports
__counted_by (GCC 15 or newer, clang 20.1 or newer). I hit it with the
Arch Linux LTS kernel (6.18.44, GCC 16) in a QEMU guest.

Tested on 6.18.62 (GCC 16.2) in a QEMU q35 guest with a cxl-type3
device. Without the patch the probe BUG()s the same way as in the log
above, and with cxl_pci built in the boot then hangs. With it, cxl_pci
binds and mem0 shows up.

Please also queue it for 7.3.y, where it applies cleanly. There
kvmalloc_flex() already sets num_features at allocation, but only when
__builtin_counted_by_ref is usable, so builds with clang 20 or 21 are
still affected.
---
 drivers/cxl/core/features.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/cxl/core/features.c b/drivers/cxl/core/features.c
index bb73f205f16c..0ea5a31275d3 100644
--- a/drivers/cxl/core/features.c
+++ b/drivers/cxl/core/features.c
@@ -97,6 +97,7 @@ get_supported_features(struct cxl_features_state *cxlfs)
 		kvmalloc(struct_size(entries, ent, count), GFP_KERNEL);
 	if (!entries)
 		return NULL;
+	entries->num_features = count;
 
 	struct cxl_mbox_get_sup_feats_out *mbox_out __free(kvfree) =
 		kvmalloc(cxl_mbox->payload_size, GFP_KERNEL);
@@ -174,7 +175,6 @@ get_supported_features(struct cxl_features_state *cxlfs)
 		start += num_entries;
 	} while (remain_feats);
 
-	entries->num_features = count;
 	entries->num_user_features = user_feats;
 
 	return no_free_ptr(entries);

---
base-commit: c3f63d70f236bb7685e6d11d1d9b5b351552e600
change-id: 20261107-cxl-features-6-18-y-02d5a54cc743

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

