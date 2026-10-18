From: Bochao Cao <bochaolucky@gmail.com>
Date: Sun, 18 Oct 2026 22:05:53 +0800
Subject: [PATCH net-next v6 4/5] selftests/net: Add a shared BPF skeleton
 rule
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-xdp-v5-send-20261008-v6-4-7336e1282ca3@gmail.com>
References: <20261018-xdp-v5-send-20261008-v6-0-7336e1282ca3@gmail.com>
In-Reply-To: <20261018-xdp-v5-send-20261008-v6-0-7336e1282ca3@gmail.com>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, netdev@vger.kernel.org, 
 =?utf-8?q?Alexis_Lothor=C3=A9?= <alexis.lothore@bootlin.com>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Tiezhu Yang <tiozhang@didiglobal.com>, Bochao Cao <bochaolucky@gmail.com>, 
 Willem de Bruijn <willemdebruijn.kernel@gmail.com>, 
 Petr Machata <petrm@nvidia.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792332371; l=2900;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=IefQQaDfNjaCeCPmWb/HPENI7gRpsQZQYQxUbSrYy/c=;
 b=OQo0u1MsdV8geeXkxktAqiL4HcdM+yS5yAsMRSubDb9daycidauVNyhLta11DV0ma6s8s2JYE
 ArUgxx68GXzBFLO93Add82knAaR9UuyYaYDxpZPW/1O8/uem8khcwK4
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a shared skeleton rule and build host bpftool when BPFTOOL is not
supplied. Use host CC/LD and absolute source paths in submakes.

Pass KHDR_INCLUDES to the BPF compiler without overriding it with
source-tree headers. Generate the skeleton through a temporary file.

Tested normal and separate-output builds, inherited relative srctree,
and host bootstrap with unusable target CC/LD. A conflicting source
header no longer overrides the installed header.

Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/net/bpf.mk | 33 +++++++++++++++++++++++++++++++--
 1 file changed, 31 insertions(+), 2 deletions(-)

diff --git a/tools/testing/selftests/net/bpf.mk b/tools/testing/selftests/net/bpf.mk
index a4f6755dd8941..016e32960280a 100644
--- a/tools/testing/selftests/net/bpf.mk
+++ b/tools/testing/selftests/net/bpf.mk
@@ -4,12 +4,12 @@ CLANG ?= clang
 SCRATCH_DIR := $(OUTPUT)/tools
 BUILD_DIR := $(SCRATCH_DIR)/build
 BPFDIR := $(top_srcdir)/tools/lib/bpf
 APIDIR := $(top_srcdir)/tools/include/uapi
 
+CCINCLUDE += $(KHDR_INCLUDES)
 CCINCLUDE += -I$(selfdir)/bpf
-CCINCLUDE += -I$(top_srcdir)/usr/include/
 CCINCLUDE += -I$(SCRATCH_DIR)/include
 
 BPFOBJ := $(BUILD_DIR)/libbpf/libbpf.a
 
 MAKE_DIRS := $(BUILD_DIR)/libbpf
@@ -44,10 +44,39 @@ $(BPF_PROG_OBJS): $(OUTPUT)/%.o : %.c $(BPFOBJ) | $(MAKE_DIRS)
 
 $(BPFOBJ): $(wildcard $(BPFDIR)/*.[ch] $(BPFDIR)/Makefile)		       \
 	   $(APIDIR)/linux/bpf.h					       \
 	   | $(BUILD_DIR)/libbpf
 	$(call msg,MAKE,,$@)
-	$(Q)$(MAKE) $(submake_extras) -C $(BPFDIR) OUTPUT=$(BUILD_DIR)/libbpf/ \
+	$(Q)$(MAKE) $(submake_extras) -C $(BPFDIR) srctree=$(abspath $(top_srcdir)) \
+		    OUTPUT=$(BUILD_DIR)/libbpf/ \
 		    EXTRA_CFLAGS='-g -O0'				       \
 		    DESTDIR=$(SCRATCH_DIR) prefix= all install_headers
 
 EXTRA_CLEAN += $(SCRATCH_DIR)
+
+# Build a host bpftool only when a test needs a generated skeleton.
+HOSTCC ?= gcc
+HOSTLD ?= ld
+BPFTOOL_BUILD := $(BUILD_DIR)/bpftool
+ifeq ($(origin BPFTOOL),undefined)
+BPFTOOL := $(BPFTOOL_BUILD)/bootstrap/bpftool
+BPFTOOL_DEP := $(BPFTOOL)
+else
+BPFTOOL_DEP := $(shell command -v $(BPFTOOL))
+endif
+
+$(BPFTOOL_BUILD)/bootstrap/bpftool: \
+	$(wildcard $(top_srcdir)/tools/bpf/bpftool/*.[ch]) \
+	$(top_srcdir)/tools/bpf/bpftool/Makefile \
+	$(wildcard $(BPFDIR)/*.[ch] $(BPFDIR)/Makefile)
+	$(call msg,MAKE,,$@)
+	$(Q)mkdir -p $(BPFTOOL_BUILD)
+	$(Q)$(MAKE) $(submake_extras) -C $(top_srcdir)/tools/bpf/bpftool \
+		OUTPUT=$(BPFTOOL_BUILD)/ srctree=$(abspath $(top_srcdir)) \
+		ARCH= CROSS_COMPILE= CC="$(HOSTCC)" LD="$(HOSTLD)" bootstrap
+
+$(OUTPUT)/%.skel.h: $(OUTPUT)/%.bpf.o $(BPFTOOL_DEP)
+	$(call msg,GEN-SKEL,,$@)
+	$(Q)$(BPFTOOL) gen skeleton $< name $(notdir $*) > $@.tmp
+	$(Q)mv $@.tmp $@
+
+EXTRA_CLEAN += $(wildcard $(OUTPUT)/*.skel.h $(OUTPUT)/*.skel.h.tmp)

-- 
Git-155)

