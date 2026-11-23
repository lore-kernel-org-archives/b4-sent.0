From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 24 Nov 2026 02:44:45 +0800
Subject: [PATCH] riscv: vdso: Define BUILD_VDSO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-riscv-vdso-build-vdso-v1-1-c52b0b3592dc@iscas.ac.cn>
X-B4-Tracking: v=1; b=H4sIAJyJBGsC/yWMQQqAIBAAvyJ7TkjJir4SHSzXWogMlyQI/57Ub
 eYw8wBjJGQYxAMREzGFo4iqBCybPVaU5IqDrnWrlG5kJF6STI6DnC/a3Y/Wzb7rTWO98VDaM6K
 n+/uOU84vR63LbmcAAAA=
X-Change-ID: 20261124-riscv-vdso-build-vdso-adbf7854af5f
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: Drew Fustini <fustini@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459491; l=1289;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=dAS3hQxQuE0pYdjMaRRfsno7t7qwdj3jEoveU0f6oWg=;
 b=YPNE9RlZxuADbrEQ9JR/ChY+NDusx5Ei/QLKFb9cujFmClqvAns64uITCNJZzvn7HsRzmfE6L
 /PEZXb+MtO3AfClONlwsVevAQx7iL8yfowyl2z7/xMEydoxHkWkBNPB
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unlike arm64, powerpc and others, riscv does not define BUILD_VDSO
for its vDSO build, so header checks on it never apply here.

The T-Head WRITE_ONCE errata needs it to keep its alternative out of
the vDSO. Otherwise booting with CONFIG_DEBUG_VIRTUAL=y hits
VIRTUAL_BUG_ON() in vmalloc_to_page().

Link: https://lore.kernel.org/linux-riscv/CAJF2gTQ+cOYfQX=JsK6T6Aij79FU9RGuyxAAouyL958z8ABqng@mail.gmail.com/
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Tested with the WRITE_ONCE errata V6 in qemu -cpu thead-c906.
---
 arch/riscv/kernel/vdso/Makefile | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/riscv/kernel/vdso/Makefile b/arch/riscv/kernel/vdso/Makefile
index c023046a3fd75a95946babb96b3f9019ee2dec4a..b99645672634852df814e9d17c768bf82297079b 100644
--- a/arch/riscv/kernel/vdso/Makefile
+++ b/arch/riscv/kernel/vdso/Makefile
@@ -35,6 +35,7 @@ endif
 
 ccflags-y := -fno-stack-protector
 ccflags-y += -DDISABLE_BRANCH_PROFILING
+ccflags-y += -DBUILD_VDSO
 ccflags-y += -fno-builtin
 ccflags-y += $(CONFIG_CC_OPT_INLINE_MEMSET)
 ccflags-y += $(KBUILD_BASE_ISA)$(CFI_MARCH)

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261124-riscv-vdso-build-vdso-adbf7854af5f

Best regards,
-- 
Han Gao <gaohan@iscas.ac.cn>

