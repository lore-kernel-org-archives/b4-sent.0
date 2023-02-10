From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 10 Feb 2023 12:42:02 -0600
Subject: [PATCH v3 14/20] powerpc/pseries: PAPR system parameter API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v3-14-26929c8cce78@linux.ibm.com>
References: <20230125-b4-powerpc-rtas-queue-v3-0-26929c8cce78@linux.ibm.com>
In-Reply-To: <20230125-b4-powerpc-rtas-queue-v3-0-26929c8cce78@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Kajol Jain <kjain@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Andrew Donnellan <ajd@linux.ibm.com>, Nick Child <nnac123@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1676054526; l=7880;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=JVCNvglyTypb2+hufHYloAJ+QgmsxeqSdha1djQBD4k=;
 b=cQXEz8Y3zgfOUNzWjtX+bG9qMfrw6HmVd91GtHgcAf8X/E3GG2Ix3I9zn+JALfll40g82qhEQ
 ftd9B8h9G8ZCYn0zI9WOkRZluE45v3zC2K4rEfmqbUQfWqUpE1Lak8b
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Introduce a set of APIs for retrieving and updating PAPR system
parameters. This encapsulates the toil of temporary RTAS work area
management, RTAS function call retries, and translation of RTAS call
statuses to conventional error values.

There are several places in the kernel that already retrieve system
parameters by calling the RTAS ibm,get-system-parameter function
directly. These will be converted to papr_sysparm_get() in changes to
follow.

As for updating system parameters, current practice is to use
sys_rtas() from user space; there are no in-kernel users of the RTAS
ibm,set-system-parameter function. However this will become deprecated
in time because it is not compatible with lockdown.

The papr_sysparm_* APIs will form the common basis for in-kernel
and user space access to system parameters. The code to expose the
set/get capabilities to user space will follow.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/papr-sysparm.h       |  38 +++++++
 arch/powerpc/platforms/pseries/Makefile       |   2 +-
 arch/powerpc/platforms/pseries/papr-sysparm.c | 151 ++++++++++++++++++++++++++
 3 files changed, 190 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/include/asm/papr-sysparm.h b/arch/powerpc/include/asm/papr-sysparm.h
new file mode 100644
index 000000000000..f5fdbd8ae9db
--- /dev/null
+++ b/arch/powerpc/include/asm/papr-sysparm.h
@@ -0,0 +1,38 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef _ASM_POWERPC_PAPR_SYSPARM_H
+#define _ASM_POWERPC_PAPR_SYSPARM_H
+
+typedef struct {
+	const u32 token;
+} papr_sysparm_t;
+
+#define mk_papr_sysparm(x_) ((papr_sysparm_t){ .token = x_, })
+
+/*
+ * Derived from the "Defined Parameters" table in PAPR 7.3.16 System
+ * Parameters Option. Where the spec says "characteristics", we use
+ * "attrs" in the symbolic names to keep them from getting too
+ * unwieldy.
+ */
+#define PAPR_SYSPARM_SHARED_PROC_LPAR_ATTRS        mk_papr_sysparm(20)
+#define PAPR_SYSPARM_PROC_MODULE_INFO              mk_papr_sysparm(43)
+#define PAPR_SYSPARM_COOP_MEM_OVERCOMMIT_ATTRS     mk_papr_sysparm(44)
+#define PAPR_SYSPARM_TLB_BLOCK_INVALIDATE_ATTRS    mk_papr_sysparm(50)
+#define PAPR_SYSPARM_LPAR_NAME                     mk_papr_sysparm(55)
+
+enum {
+	PAPR_SYSPARM_MAX_INPUT  = 1024,
+	PAPR_SYSPARM_MAX_OUTPUT = 4000,
+};
+
+struct papr_sysparm_buf {
+	__be16 len;
+	char val[PAPR_SYSPARM_MAX_OUTPUT];
+};
+
+struct papr_sysparm_buf *papr_sysparm_buf_alloc(void);
+void papr_sysparm_buf_free(struct papr_sysparm_buf *buf);
+int papr_sysparm_set(papr_sysparm_t param, const struct papr_sysparm_buf *buf);
+int papr_sysparm_get(papr_sysparm_t param, struct papr_sysparm_buf *buf);
+
+#endif /* _ASM_POWERPC_PAPR_SYSPARM_H */
diff --git a/arch/powerpc/platforms/pseries/Makefile b/arch/powerpc/platforms/pseries/Makefile
index b63d7b4ba8fe..1133bee7980a 100644
--- a/arch/powerpc/platforms/pseries/Makefile
+++ b/arch/powerpc/platforms/pseries/Makefile
@@ -3,7 +3,7 @@ ccflags-$(CONFIG_PPC64)			:= $(NO_MINIMAL_TOC)
 ccflags-$(CONFIG_PPC_PSERIES_DEBUG)	+= -DDEBUG
 
 obj-y			:= lpar.o hvCall.o nvram.o reconfig.o \
-			   of_helpers.o rtas-work-area.o \
+			   of_helpers.o rtas-work-area.o papr-sysparm.o \
 			   setup.o iommu.o event_sources.o ras.o \
 			   firmware.o power.o dlpar.o mobility.o rng.o \
 			   pci.o pci_dlpar.o eeh_pseries.o msi.o \
diff --git a/arch/powerpc/platforms/pseries/papr-sysparm.c b/arch/powerpc/platforms/pseries/papr-sysparm.c
new file mode 100644
index 000000000000..2bb5c816399b
--- /dev/null
+++ b/arch/powerpc/platforms/pseries/papr-sysparm.c
@@ -0,0 +1,151 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#define pr_fmt(fmt)	"papr-sysparm: " fmt
+
+#include <linux/bug.h>
+#include <linux/init.h>
+#include <linux/kernel.h>
+#include <linux/printk.h>
+#include <linux/slab.h>
+#include <asm/rtas.h>
+#include <asm/papr-sysparm.h>
+#include <asm/rtas-work-area.h>
+
+struct papr_sysparm_buf *papr_sysparm_buf_alloc(void)
+{
+	struct papr_sysparm_buf *buf = kzalloc(sizeof(*buf), GFP_KERNEL);
+
+	return buf;
+}
+
+void papr_sysparm_buf_free(struct papr_sysparm_buf *buf)
+{
+	kfree(buf);
+}
+
+/**
+ * papr_sysparm_get() - Retrieve the value of a PAPR system parameter.
+ * @param: PAPR system parameter token as described in
+ *         7.3.16 "System Parameters Option".
+ * @buf: A &struct papr_sysparm_buf as returned from papr_sysparm_buf_alloc().
+ *
+ * Place the result of querying the specified parameter, if available,
+ * in @buf. The result includes a be16 length header followed by the
+ * value, which may be a string or binary data. See &struct papr_sysparm_buf.
+ *
+ * Since there is at least one parameter (60, OS Service Entitlement
+ * Status) where the results depend on the incoming contents of the
+ * work area, the caller-supplied buffer is copied unmodified into the
+ * work area before calling ibm,get-system-parameter.
+ *
+ * A defined parameter may not be implemented on a given system, and
+ * some implemented parameters may not be available to all partitions
+ * on a system. A parameter's disposition may change at any time due
+ * to system configuration changes or partition migration.
+ *
+ * Context: This function may sleep.
+ *
+ * Return: 0 on success, -errno otherwise. @buf is unmodified on error.
+ */
+
+int papr_sysparm_get(papr_sysparm_t param, struct papr_sysparm_buf *buf)
+{
+	const s32 token = rtas_token("ibm,get-system-parameter");
+	struct rtas_work_area *work_area;
+	s32 fwrc;
+	int ret;
+
+	might_sleep();
+
+	if (WARN_ON(!buf))
+		return -EFAULT;
+
+	if (token == RTAS_UNKNOWN_SERVICE)
+		return -ENOENT;
+
+	work_area = rtas_work_area_alloc(sizeof(*buf));
+
+	memcpy(rtas_work_area_raw_buf(work_area), buf, sizeof(*buf));
+
+	do {
+		fwrc = rtas_call(token, 3, 1, NULL, param.token,
+				 rtas_work_area_phys(work_area),
+				 rtas_work_area_size(work_area));
+	} while (rtas_busy_delay(fwrc));
+
+	switch (fwrc) {
+	case 0:
+		ret = 0;
+		memcpy(buf, rtas_work_area_raw_buf(work_area), sizeof(*buf));
+		break;
+	case -3: /* parameter not implemented */
+		ret = -EOPNOTSUPP;
+		break;
+	case -9002: /* this partition not authorized to retrieve this parameter */
+		ret = -EPERM;
+		break;
+	case -9999: /* "parameter error" e.g. the buffer is too small */
+		ret = -EINVAL;
+		break;
+	default:
+		pr_err("unexpected ibm,get-system-parameter result %d\n", fwrc);
+		fallthrough;
+	case -1: /* Hardware/platform error */
+		ret = -EIO;
+		break;
+	}
+
+	rtas_work_area_free(work_area);
+
+	return ret;
+}
+
+int papr_sysparm_set(papr_sysparm_t param, const struct papr_sysparm_buf *buf)
+{
+	const s32 token = rtas_token("ibm,set-system-parameter");
+	struct rtas_work_area *work_area;
+	s32 fwrc;
+	int ret;
+
+	might_sleep();
+
+	if (WARN_ON(!buf))
+		return -EFAULT;
+
+	if (token == RTAS_UNKNOWN_SERVICE)
+		return -ENOENT;
+
+	work_area = rtas_work_area_alloc(sizeof(*buf));
+
+	memcpy(rtas_work_area_raw_buf(work_area), buf, sizeof(*buf));
+
+	do {
+		fwrc = rtas_call(token, 2, 1, NULL, param.token,
+				 rtas_work_area_phys(work_area));
+	} while (rtas_busy_delay(fwrc));
+
+	switch (fwrc) {
+	case 0:
+		ret = 0;
+		break;
+	case -3: /* parameter not supported */
+		ret = -EOPNOTSUPP;
+		break;
+	case -9002: /* this partition not authorized to modify this parameter */
+		ret = -EPERM;
+		break;
+	case -9999: /* "parameter error" e.g. invalid input data */
+		ret = -EINVAL;
+		break;
+	default:
+		pr_err("unexpected ibm,set-system-parameter result %d\n", fwrc);
+		fallthrough;
+	case -1: /* Hardware/platform error */
+		ret = -EIO;
+		break;
+	}
+
+	rtas_work_area_free(work_area);
+
+	return ret;
+}

-- 
2.39.1

