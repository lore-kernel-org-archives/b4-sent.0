From: Eric Long <i@hack3r.moe>
Date: Sun, 29 Sep 2024 17:31:14 +0800
Subject: [PATCH bpf-next v2 1/2] libbpf: do not resolve size on duplicate
 FUNCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240929-libbpf-dup-extern-funcs-v2-1-0cc81de3f79f@hack3r.moe>
References: <20240929-libbpf-dup-extern-funcs-v2-0-0cc81de3f79f@hack3r.moe>
In-Reply-To: <20240929-libbpf-dup-extern-funcs-v2-0-0cc81de3f79f@hack3r.moe>
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1761; i=i@hack3r.moe;
 h=from:subject:message-id; bh=win3dEA5LsS0+wCbt4UeGT2PjkspJzu11T/KTqEDaew=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGk/5VIfLVbZsWL6Ogv5v8lRZdsPPH9nd/3auZnHzv66/
 uuP4/Q76h2lLAxiXAyyYoosWw7/UUvQ7960hHtOOcwcViaQIQxcnAIwEcclDL+YjD3su0q49U1d
 bntW/5aTXcD893CPzsE8ReEu1mnfAlQZGb5v+2WaY2FpdnNnfOVLv3sBbnsfbp7guVpgXWG0Xtk
 CBkYA
X-Developer-Key: i=i@hack3r.moe; a=openpgp;
 fpr=3A7A1F5A7257780C45A9A147E1487564916D3DF5
X-Endpoint-Received: by B4 Relay for i@hack3r.moe/default with auth_id=225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FUNCs do not have sizes, thus currently btf__resolve_size will fail
with -EINVAL. Add conditions so that we only update size when the BTF
object is not function or function prototype.

Signed-off-by: Eric Long <i@hack3r.moe>
---
 tools/lib/bpf/linker.c | 23 +++++++++++++----------
 1 file changed, 13 insertions(+), 10 deletions(-)

diff --git a/tools/lib/bpf/linker.c b/tools/lib/bpf/linker.c
index 81dbbdd79a7c65a4b048b85e1dba99cb5f7cb56b..cffb388fa40ef054c2661b8363120f8a4d3c3784 100644
--- a/tools/lib/bpf/linker.c
+++ b/tools/lib/bpf/linker.c
@@ -2452,17 +2452,20 @@ static int linker_append_btf(struct bpf_linker *linker, struct src_obj *obj)
 				__s64 sz;
 
 				dst_var = &dst_sec->sec_vars[glob_sym->var_idx];
-				/* Because underlying BTF type might have
-				 * changed, so might its size have changed, so
-				 * re-calculate and update it in sec_var.
-				 */
-				sz = btf__resolve_size(linker->btf, glob_sym->underlying_btf_id);
-				if (sz < 0) {
-					pr_warn("global '%s': failed to resolve size of underlying type: %d\n",
-						name, (int)sz);
-					return -EINVAL;
+				t = btf__type_by_id(linker->btf, glob_sym->underlying_btf_id);
+				if (btf_kind(t) != BTF_KIND_FUNC && btf_kind(t) != BTF_KIND_FUNC_PROTO) {
+					/* Because underlying BTF type might have
+					 * changed, so might its size have changed, so
+					 * re-calculate and update it in sec_var.
+					 */
+					sz = btf__resolve_size(linker->btf, glob_sym->underlying_btf_id);
+					if (sz < 0) {
+						pr_warn("global '%s': failed to resolve size of underlying type: %d\n",
+							name, (int)sz);
+						return -EINVAL;
+					}
+					dst_var->size = sz;
 				}
-				dst_var->size = sz;
 				continue;
 			}
 

-- 
2.46.2

