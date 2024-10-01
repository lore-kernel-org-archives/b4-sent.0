From: Eric Long <i@hack3r.moe>
Date: Tue, 01 Oct 2024 11:55:21 +0800
Subject: [PATCH bpf-next v3 1/2] libbpf: do not resolve size on duplicate
 FUNCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241001-libbpf-dup-extern-funcs-v3-1-42f7774efbf3@hack3r.moe>
References: <20241001-libbpf-dup-extern-funcs-v3-0-42f7774efbf3@hack3r.moe>
In-Reply-To: <20241001-libbpf-dup-extern-funcs-v3-0-42f7774efbf3@hack3r.moe>
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=985; i=i@hack3r.moe;
 h=from:subject:message-id; bh=IhJnEF2eUexSNHu1rLCPbrDJ161gDmPF/o4WkeIj0mA=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGm/i9asrJm/+HGWVJQDW8LCpVfs0m+arxTg0O/t+uvZJ
 rZlvn16RykLgxgXg6yYIsuWw3/UEvS7Ny3hnlMOM4eVCWQIAxenAEykXZ3hf67L4aPHn51hkLiV
 e7y48NrFQ5K/2R6cjM8Q0Koo2tBS5sDIcPlU9JHbnMy5BYJC1jXuP44veRv4K21uWfBu0wBZjhU
 aDAA=
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
index 81dbbdd79a7c65a4b048b85e1dba99cb5f7cb56b..ff249ba0ab067526e82d91481d21ec88a2732b4f 100644
--- a/tools/lib/bpf/linker.c
+++ b/tools/lib/bpf/linker.c
@@ -2451,6 +2451,10 @@ static int linker_append_btf(struct bpf_linker *linker, struct src_obj *obj)
 			if (glob_sym && glob_sym->var_idx >= 0) {
 				__s64 sz;
 
+				/* FUNCs don't have size, nothing to update */
+				if (btf_is_func(t) || btf_is_func_proto(t))
+					continue;
+
 				dst_var = &dst_sec->sec_vars[glob_sym->var_idx];
 				/* Because underlying BTF type might have
 				 * changed, so might its size have changed, so

-- 
2.46.2

