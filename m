From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:42 +0200
Subject: [PATCH RFC 05/10] coresight: cpu-debug: Do not sample a core that
 is in reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-5-69d3ad1e0fc8@iav.lv>
References: <20261127-b4-coresight-cpu-debug-lockup-v1-0-69d3ad1e0fc8@iav.lv>
In-Reply-To: <20261127-b4-coresight-cpu-debug-lockup-v1-0-69d3ad1e0fc8@iav.lv>
To: Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@arm.com>, James Clark <james.clark@linaro.org>, 
 Leo Yan <leo.yan@arm.com>, Andrew Morton <akpm@linux-foundation.org>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>
Cc: coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Douglas Anderson <dianders@chromium.org>, Petr Mladek <pmladek@suse.com>, 
 Feng Tang <feng.tang@linux.alibaba.com>, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3674; i=iav@iav.lv;
 h=from:subject:message-id; bh=tmVd95P84NWuwX8kkEkvDAkpADpu+/ySXwvKuYqsquA=;
 b=kA0DAAoWMpeVi+pfeQMByyZiAGsJJXKg9FySgRgbmMFUWOvWYE0orsAY00k/u3+touPMlk4B5
 Ih1BAAWCgAdFiEEkMIo2mik1f1PSDfgMpeVi+pfeQMFAmsJJXIACgkQMpeVi+pfeQMN1wD/UpEA
 FZm0PvjJa04cuKMqqOm4nD33RYPU2BkA8Wmw6EUA/1/s6XKuTmM6gF+QdwdvAb1B58oTyOLXyNZ
 t1hM4TAoG
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

debug_access_permitted() lets the driver read the sampling registers
when EDPRSR shows the core powered and the OS Double Lock clear. A core
can be powered and held in reset: an idle Cortex-A72 on RK3399 reads
PU = 1, R = 1, and a read of its EDPCSR aborts.

Treat a core that EDPRSR reports in reset as not accessible, and print
the bit in the dump.

debug_read_regs() writes EDOSLAR before it reads EDPRSR, and on RK3399
that write already faults for such a core. The check covers the path
added later in this series, which reads EDPRSR first.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 Documentation/trace/coresight/coresight-cpu-debug.rst | 4 ++--
 drivers/hwtracing/coresight/coresight-cpu-debug.c     | 9 ++++++++-
 2 files changed, 10 insertions(+), 3 deletions(-)

diff --git a/Documentation/trace/coresight/coresight-cpu-debug.rst b/Documentation/trace/coresight/coresight-cpu-debug.rst
index 32fbae244524..04bfd318cb2b 100644
--- a/Documentation/trace/coresight/coresight-cpu-debug.rst
+++ b/Documentation/trace/coresight/coresight-cpu-debug.rst
@@ -182,12 +182,12 @@ Here is an example of the debugging output format::
 
   ARM external debug module:
   coresight-cpu-debug 850000.debug: CPU[0]:
-  coresight-cpu-debug 850000.debug:  EDPRSR:  00000001 (Power:On DLK:Unlock)
+  coresight-cpu-debug 850000.debug:  EDPRSR:  00000001 (Power:On Reset:No DLK:Unlock)
   coresight-cpu-debug 850000.debug:  EDPCSR:  handle_IPI+0x174/0x1d8
   coresight-cpu-debug 850000.debug:  EDCIDSR: 00000000
   coresight-cpu-debug 850000.debug:  EDVIDSR: 90000000 (State:Non-secure Mode:EL1/0 Width:64bits VMID:0)
   coresight-cpu-debug 852000.debug: CPU[1]:
-  coresight-cpu-debug 852000.debug:  EDPRSR:  00000001 (Power:On DLK:Unlock)
+  coresight-cpu-debug 852000.debug:  EDPRSR:  00000001 (Power:On Reset:No DLK:Unlock)
   coresight-cpu-debug 852000.debug:  EDPCSR:  debug_notifier_call+0x23c/0x358
   coresight-cpu-debug 852000.debug:  EDCIDSR: 00000000
   coresight-cpu-debug 852000.debug:  EDVIDSR: 90000000 (State:Non-secure Mode:EL1/0 Width:64bits VMID:0)
diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index 9a8ce85fc468..64b5abe33aa8 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -51,6 +51,7 @@
 
 /* bits definition for EDPRSR */
 #define EDPRSR_DLK			BIT(6)
+#define EDPRSR_R			BIT(2)
 #define EDPRSR_PU			BIT(0)
 
 /* bits definition for EDVIDSR */
@@ -129,6 +130,7 @@ static void debug_os_unlock(struct debug_drvdata *drvdata)
  * registers to avoid lockup issue:
  *
  * - CPU power domain is powered off;
+ * - The CPU is in reset;
  * - The OS Double Lock is locked;
  *
  * By checking EDPRSR can get to know if meet these conditions.
@@ -139,6 +141,10 @@ static bool debug_access_permitted(struct debug_drvdata *drvdata)
 	if (!(drvdata->edprsr & EDPRSR_PU))
 		return false;
 
+	/* CPU is in reset */
+	if (drvdata->edprsr & EDPRSR_R)
+		return false;
+
 	/* The OS Double Lock is locked */
 	if (drvdata->edprsr & EDPRSR_DLK)
 		return false;
@@ -293,9 +299,10 @@ static void debug_dump_regs(struct debug_drvdata *drvdata)
 	struct device *dev = drvdata->dev;
 	unsigned long pc;
 
-	dev_emerg(dev, " EDPRSR:  %08x (Power:%s DLK:%s)\n",
+	dev_emerg(dev, " EDPRSR:  %08x (Power:%s Reset:%s DLK:%s)\n",
 		  drvdata->edprsr,
 		  drvdata->edprsr & EDPRSR_PU ? "On" : "Off",
+		  drvdata->edprsr & EDPRSR_R ? "Yes" : "No",
 		  drvdata->edprsr & EDPRSR_DLK ? "Lock" : "Unlock");
 
 	if (!debug_access_permitted(drvdata)) {

-- 
2.43.0

