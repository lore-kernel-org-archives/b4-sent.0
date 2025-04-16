From: Thierry Treyer <ttreyer@meta.com>
Date: Wed, 16 Apr 2025 19:20:36 +0000
Subject: [PATCH RFC 2/3] dwarf_loader: Add name to inline expansion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-btf_inline-v1-2-e4bd2f8adae5@meta.com>
References: <20250416-btf_inline-v1-0-e4bd2f8adae5@meta.com>
In-Reply-To: <20250416-btf_inline-v1-0-e4bd2f8adae5@meta.com>
To: dwarves@vger.kernel.org, bpf@vger.kernel.org
Cc: Thierry Treyer <ttreyer@meta.com>, acme@kernel.org, ast@kernel.org, 
 yhs@meta.com, andrii@kernel.org, ihor.solodrai@linux.dev, 
 songliubraving@meta.com, alan.maguire@oracle.com, mykolal@meta.com
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744831265; l=1535;
 i=ttreyer@meta.com; s=20250416; h=from:subject:message-id;
 bh=GxSE1f8+lYV3zrhaWnIMYQRjICGOXJevdGgMRZAvrV4=;
 b=hFKyHffdY9Kr4yAK5v4Mo4gSpBq0a9f1W8sNS5wWj//EVX9husdcweWFfcGUHpYs/TXgpJ16d
 Bw9nKFhKN5LBueMspRyHu1ZwbRwtbiypjIQW2oIM6KdjNqdguG1bfXy
X-Developer-Key: i=ttreyer@meta.com; a=ed25519;
 pk=2NAyAkZ6zhou7+5zqr5ikv3g5BfFbkznGzvzfKv1nbU=
X-Endpoint-Received: by B4 Relay for ttreyer@meta.com/20250416 with auth_id=382
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the name field to inline expansion. It contains the name of the
abstract origin. The name can be used to locate the origin function in
the BTF.

Surely there's a better way to find the btf_id of the original function?

Signed-off-by: Thierry Treyer <ttreyer@meta.com>
---
 dwarf_loader.c | 9 +++++++++
 dwarves.h      | 1 +
 2 files changed, 10 insertions(+)

diff --git a/dwarf_loader.c b/dwarf_loader.c
index 24ac9afceb3793c165d3e92cfdfaf27ab67fd4d6..d7a130d138a65bad71a563cf3d629bdd7b9e6c6f 100644
--- a/dwarf_loader.c
+++ b/dwarf_loader.c
@@ -1376,6 +1376,15 @@ static struct inline_expansion *inline_expansion__new(Dwarf_Die *die, struct cu
 		dtag->decl_file = attr_string(die, DW_AT_call_file, conf);
 		dtag->decl_line = attr_numeric(die, DW_AT_call_line);
 		dwarf_tag__set_attr_type(dtag, type, die, DW_AT_abstract_origin);
+
+		Dwarf_Attribute attr_orig;
+		if (dwarf_attr(die, DW_AT_abstract_origin, &attr_orig)) {
+			Dwarf_Die die_orig;
+			if (dwarf_formref_die(&attr_orig, &die_orig)) {
+				exp->name = attr_string(&die_orig, DW_AT_name, conf);
+			}
+		}
+
 		exp->ip.addr = 0;
 		exp->high_pc = 0;
 		exp->nr_parms = 0;
diff --git a/dwarves.h b/dwarves.h
index 38efd6a6e2b0b0e5a571a8d12bbec33502509d8b..13b19433fe4aa7cd54ec0160c7008a33cbc17e24 100644
--- a/dwarves.h
+++ b/dwarves.h
@@ -809,6 +809,7 @@ struct ip_tag {
 
 struct inline_expansion {
 	struct ip_tag	 ip;
+	const char *name;
 	size_t		 size;
 	uint64_t	 high_pc;
 	struct list_head parms;

-- 
2.47.1

