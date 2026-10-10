From: Bochao Cao <bochaolucky@gmail.com>
Date: Sat, 10 Oct 2026 18:22:48 +0800
Subject: [PATCH net-next v5 4/5] selftests/net: Add a shared BPF skeleton
 rule
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-xdp-v5-send-20261008-v5-4-de687cb67c40@gmail.com>
References: <20261010-xdp-v5-send-20261008-v5-0-de687cb67c40@gmail.com>
In-Reply-To: <20261010-xdp-v5-send-20261008-v5-0-de687cb67c40@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791627780; l=1820;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=eipfzjTKrG/cSjQ4DLusR7Ju6IxV+23WYHtr5ArWkFc=;
 b=hGNOtzAJoRautGuG7BoOuUZCNeoZfkBYKv60IQbIsjZHPZPvAcQIlOBRd+Qs3gTC+dTQjDHK3
 elSyxSeHIi7B3bTyB80bUltw3+BKLRqric4dDvGbZdrJKaBjs3SHW7u
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add %.skel.h to net/bpf.mk. Build a host bpftool bootstrap when BPFTOOL is
not supplied.

Write the skeleton to a temporary file and rename it on success, so a
failed command does not leave a partial header.

Signed-off-by: Bochao Cao <bochaolucky@gmail.com>
---
 tools/testing/selftests/net/bpf.mk | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/tools/testing/selftests/net/bpf.mk b/tools/testing/selftests/net/bpf.mk
index a4f6755dd8941..2ded0f65dafa9 100644
--- a/tools/testing/selftests/net/bpf.mk
+++ b/tools/testing/selftests/net/bpf.mk
@@ -49,5 +49,30 @@ $(BPFOBJ): $(wildcard $(BPFDIR)/*.[ch] $(BPFDIR)/Makefile)		       \
 	$(Q)$(MAKE) $(submake_extras) -C $(BPFDIR) OUTPUT=$(BUILD_DIR)/libbpf/ \
 		    EXTRA_CFLAGS='-g -O0'				       \
 		    DESTDIR=$(SCRATCH_DIR) prefix= all install_headers
 
 EXTRA_CLEAN += $(SCRATCH_DIR)
+
+# Build a host bpftool only when a test needs a generated skeleton.
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
+		OUTPUT=$(BPFTOOL_BUILD)/ ARCH= CROSS_COMPILE= bootstrap
+
+$(OUTPUT)/%.skel.h: $(OUTPUT)/%.bpf.o $(BPFTOOL_DEP)
+	$(call msg,GEN-SKEL,,$@)
+	$(Q)$(BPFTOOL) gen skeleton $< name $(notdir $*) > $@.tmp
+	$(Q)mv $@.tmp $@
+
+EXTRA_CLEAN += $(wildcard $(OUTPUT)/*.skel.h $(OUTPUT)/*.skel.h.tmp)

-- 
Git-155)

