From: Eric Long <i@hack3r.moe>
Date: Tue, 01 Oct 2024 11:55:22 +0800
Subject: [PATCH bpf-next v3 2/2] selftests/bpf: test linking with duplicate
 extern functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241001-libbpf-dup-extern-funcs-v3-2-42f7774efbf3@hack3r.moe>
References: <20241001-libbpf-dup-extern-funcs-v3-0-42f7774efbf3@hack3r.moe>
In-Reply-To: <20241001-libbpf-dup-extern-funcs-v3-0-42f7774efbf3@hack3r.moe>
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3710; i=i@hack3r.moe;
 h=from:subject:message-id; bh=lBW/ZkssutZzZs0+icq0x4wdMAyMMqQZLN7YcP9oJJs=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGm/i9b8Wm/+2/V0QO/tHyEnru/S2vh//3HOt7NnfOCcc
 07F0TWzraOUhUGMi0FWTJFly+E/agn63ZuWcM8ph5nDygQyhIGLUwAmwqTJ8FdUrfmGVK+7a2Xy
 12XbTJ5Mc1jhMO+M1+bd79+0mF8wyeNlZFjdl/TAP6z4VIPkBwUXa58ZjzdEznWfd37DTpOZZve
 u7GUCAA==
X-Developer-Key: i=i@hack3r.moe; a=openpgp;
 fpr=3A7A1F5A7257780C45A9A147E1487564916D3DF5
X-Endpoint-Received: by B4 Relay for i@hack3r.moe/default with auth_id=225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Previously when multiple BPF object files referencing the same extern
function (usually kfunc) are statically linked using `bpftool gen
object`, libbpf tries to get the nonexistent size of BTF_KIND_FUNC_PROTO
and fails. This test ensures it is fixed.

Signed-off-by: Eric Long <i@hack3r.moe>
---
 tools/testing/selftests/bpf/Makefile                  |  3 ++-
 .../selftests/bpf/prog_tests/dup_extern_funcs.c       |  9 +++++++++
 tools/testing/selftests/bpf/progs/dup_extern_funcs1.c | 19 +++++++++++++++++++
 tools/testing/selftests/bpf/progs/dup_extern_funcs2.c | 17 +++++++++++++++++
 4 files changed, 47 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/bpf/Makefile b/tools/testing/selftests/bpf/Makefile
index e295e3df5ec6c3c21abe368038514cfb34b42f69..644c4dd6002c691a9cd94ef26ddf51f6dc84e2cc 100644
--- a/tools/testing/selftests/bpf/Makefile
+++ b/tools/testing/selftests/bpf/Makefile
@@ -496,7 +496,7 @@ SKEL_BLACKLIST := btf__% test_pinning_invalid.c test_sk_assign.c
 LINKED_SKELS := test_static_linked.skel.h linked_funcs.skel.h		\
 		linked_vars.skel.h linked_maps.skel.h 			\
 		test_subskeleton.skel.h test_subskeleton_lib.skel.h	\
-		test_usdt.skel.h
+		test_usdt.skel.h dup_extern_funcs.skel.h
 
 LSKELS := fentry_test.c fexit_test.c fexit_sleep.c atomics.c 		\
 	trace_printk.c trace_vprintk.c map_ptr_kern.c 			\
@@ -520,6 +520,7 @@ test_usdt.skel.h-deps := test_usdt.bpf.o test_usdt_multispec.bpf.o
 xsk_xdp_progs.skel.h-deps := xsk_xdp_progs.bpf.o
 xdp_hw_metadata.skel.h-deps := xdp_hw_metadata.bpf.o
 xdp_features.skel.h-deps := xdp_features.bpf.o
+dup_extern_funcs.skel.h-deps := dup_extern_funcs1.bpf.o dup_extern_funcs2.bpf.o
 
 LINKED_BPF_OBJS := $(foreach skel,$(LINKED_SKELS),$($(skel)-deps))
 LINKED_BPF_SRCS := $(patsubst %.bpf.o,%.c,$(LINKED_BPF_OBJS))
diff --git a/tools/testing/selftests/bpf/prog_tests/dup_extern_funcs.c b/tools/testing/selftests/bpf/prog_tests/dup_extern_funcs.c
new file mode 100644
index 0000000000000000000000000000000000000000..b26f855745b451f7f53e44b27d47a2f659ad1378
--- /dev/null
+++ b/tools/testing/selftests/bpf/prog_tests/dup_extern_funcs.c
@@ -0,0 +1,9 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <test_progs.h>
+#include "dup_extern_funcs.skel.h"
+
+void test_dup_extern_funcs(void)
+{
+	RUN_TESTS(dup_extern_funcs);
+}
diff --git a/tools/testing/selftests/bpf/progs/dup_extern_funcs1.c b/tools/testing/selftests/bpf/progs/dup_extern_funcs1.c
new file mode 100644
index 0000000000000000000000000000000000000000..a5b6ea361c3d457d48bc562040f1ef946fadfc81
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/dup_extern_funcs1.c
@@ -0,0 +1,19 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include "vmlinux.h"
+#include <bpf/bpf_helpers.h>
+
+char _license[] SEC("license") = "GPL";
+
+void *bpf_cast_to_kern_ctx(void *obj) __ksym;
+
+SEC("tc")
+int handler1(struct __sk_buff *skb)
+{
+	struct sk_buff *skb_kern = bpf_cast_to_kern_ctx(skb);
+
+	if (!skb_kern)
+		return -1;
+
+	return 0;
+}
diff --git a/tools/testing/selftests/bpf/progs/dup_extern_funcs2.c b/tools/testing/selftests/bpf/progs/dup_extern_funcs2.c
new file mode 100644
index 0000000000000000000000000000000000000000..2f9f63dcc6ed2a35e82b55da54356502cfc95c9d
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/dup_extern_funcs2.c
@@ -0,0 +1,17 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include "vmlinux.h"
+#include <bpf/bpf_helpers.h>
+
+void *bpf_cast_to_kern_ctx(void *obj) __ksym;
+
+SEC("xdp")
+int handler2(struct xdp_md *xdp)
+{
+	struct xdp_buff *xdp_kern = bpf_cast_to_kern_ctx(xdp);
+
+	if (!xdp_kern)
+		return -1;
+
+	return 0;
+}

-- 
2.46.2

