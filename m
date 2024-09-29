From: Eric Long <i@hack3r.moe>
Date: Sun, 29 Sep 2024 17:31:15 +0800
Subject: [PATCH bpf-next v2 2/2] selftests/bpf: make sure linking objects
 with duplicate extern functions doesn't fail
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240929-libbpf-dup-extern-funcs-v2-2-0cc81de3f79f@hack3r.moe>
References: <20240929-libbpf-dup-extern-funcs-v2-0-0cc81de3f79f@hack3r.moe>
In-Reply-To: <20240929-libbpf-dup-extern-funcs-v2-0-0cc81de3f79f@hack3r.moe>
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3770; i=i@hack3r.moe;
 h=from:subject:message-id; bh=Hww+IY99Jvgbtqt0tYLYI8/UdyT0Cd78O9SVglyM2YM=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGk/5VKnPdIy9koRPHK/2LZgprpRPB/vvSsr2LIk4oRay
 lL0b0l0lLIwiHExyIopsmw5/EctQb970xLuOeUwc1iZQIYwcHEKwERO72Zk+CH0WuWwFVtj+IqX
 jRcW8F2LuWr9JiRVdGfGwz2Skwv36TIyPK35xfsrnzliRrlOXOOcGjYPyZnr/xVGvE6zYf/+YKE
 CAwA=
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
 tools/testing/selftests/bpf/Makefile                 |  3 ++-
 .../selftests/bpf/prog_tests/dup_extern_funcs.c      |  9 +++++++++
 .../testing/selftests/bpf/progs/dup_extern_funcs1.c  | 20 ++++++++++++++++++++
 .../testing/selftests/bpf/progs/dup_extern_funcs2.c  | 18 ++++++++++++++++++
 4 files changed, 49 insertions(+), 1 deletion(-)

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
index 0000000000000000000000000000000000000000..6850e01d1455c0a2da947ad6d5b1c5dab0187e00
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/dup_extern_funcs1.c
@@ -0,0 +1,20 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include "vmlinux.h"
+#include <bpf/bpf_helpers.h>
+#include <bpf/bpf_tracing.h>
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
index 0000000000000000000000000000000000000000..66ba3620274497cc40f8dfbb8d98856d4eab707e
--- /dev/null
+++ b/tools/testing/selftests/bpf/progs/dup_extern_funcs2.c
@@ -0,0 +1,18 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include "vmlinux.h"
+#include <bpf/bpf_helpers.h>
+#include <bpf/bpf_tracing.h>
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

