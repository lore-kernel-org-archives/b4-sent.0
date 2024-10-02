From: Eric Long <i@hack3r.moe>
Date: Wed, 02 Oct 2024 14:25:06 +0800
Subject: [PATCH bpf-next v4 1/2] libbpf: do not resolve size on duplicate
 FUNCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241002-libbpf-dup-extern-funcs-v4-1-560eb460ff90@hack3r.moe>
References: <20241002-libbpf-dup-extern-funcs-v4-0-560eb460ff90@hack3r.moe>
In-Reply-To: <20241002-libbpf-dup-extern-funcs-v4-0-560eb460ff90@hack3r.moe>
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=961; i=i@hack3r.moe;
 h=from:subject:message-id; bh=GityEu5UW6xiYc03h/u6D/purlYEFBNe2K5e1StUi1s=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGl/nru0N187X/O127LB/qHvtrDw0IV7WHbk1N7YoTGT3
 8zW/9GFjlIWBjEuBlkxRZYth/+oJeh3b1rCPaccZg4rE8gQBi5OAZjI9WZGhv53Fz46u+jWrmrX
 q4o4mH/3RaPSr+N+U3c+bbtjI1koZMTwP6rSdIOk9lXzXSu719RUBu7gkrxls3ViwZf76q8k7L8
 XMAEA
X-Developer-Key: i=i@hack3r.moe; a=openpgp;
 fpr=3A7A1F5A7257780C45A9A147E1487564916D3DF5
X-Endpoint-Received: by B4 Relay for i@hack3r.moe/default with auth_id=225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FUNCs do not have sizes, thus currently btf__resolve_size will fail
with -EINVAL. Add conditions so that we only update size when the BTF
object is not function or function prototype.

Signed-off-by: Eric Long <i@hack3r.moe>
---
 tools/lib/bpf/linker.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/tools/lib/bpf/linker.c b/tools/lib/bpf/linker.c
index 81dbbdd79a7c65a4b048b85e1dba99cb5f7cb56b..f83c1c29982c3d9d7f6775cd98a6f3387a4e9c50 100644
--- a/tools/lib/bpf/linker.c
+++ b/tools/lib/bpf/linker.c
@@ -2451,6 +2451,10 @@ static int linker_append_btf(struct bpf_linker *linker, struct src_obj *obj)
 			if (glob_sym && glob_sym->var_idx >= 0) {
 				__s64 sz;
 
+				/* FUNCs don't have size, nothing to update */
+				if (btf_is_func(t))
+					continue;
+
 				dst_var = &dst_sec->sec_vars[glob_sym->var_idx];
 				/* Because underlying BTF type might have
 				 * changed, so might its size have changed, so

-- 
2.46.2

