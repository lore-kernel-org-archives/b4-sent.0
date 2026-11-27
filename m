From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:47 +0200
Subject: [PATCH RFC 10/10] coresight: cpu-debug: Print the dump at the
 warning level
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-10-69d3ad1e0fc8@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3896; i=iav@iav.lv;
 h=from:subject:message-id; bh=GCm7+tmPZo0cIkK8iPjB0jGTJ009NE8OZzHsJ6RWlHA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqiXz/09TsGsyPXvvBUfXipd7OoqmvfQ19tR3f7m79
 B535MvZHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiAf6MDPdqecSNy8X+Py/T
 LEy7fChNt6qdJf33/f9f3TWmXgnf9YWRocF6R198nnRh7No5vtP0RSa8sn51VaNsa3BpUbO4pvY
 UNgA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dump comes from backtrace requests, which also happen on a system
that keeps running, for example on SysRq-l or on an RCU stall warning.

Print it at the warning level, like the "these CPUS still haven't
responded" line it follows.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/hwtracing/coresight/coresight-cpu-debug.c | 44 +++++++++++------------
 1 file changed, 22 insertions(+), 22 deletions(-)

diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index 5c5a1f6a6e33..860c31b4e025 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -321,8 +321,8 @@ static unsigned long debug_adjust_pc(struct debug_drvdata *drvdata)
 	 * case and print info for notice.
 	 */
 	if (pc & BIT(1))
-		dev_emerg(drvdata->dev,
-			  "Instruction offset is implementation defined\n");
+		dev_warn(drvdata->dev,
+			 "Instruction offset is implementation defined\n");
 	else
 		pc = (pc & EDPCSR_ARM_INST_MASK) - arm_inst_offset;
 
@@ -335,38 +335,38 @@ static void debug_dump_regs(struct debug_drvdata *drvdata)
 	struct device *dev = drvdata->dev;
 	unsigned long pc;
 
-	dev_emerg(dev, " EDPRSR:  %08x (Power:%s Reset:%s DLK:%s)\n",
-		  drvdata->edprsr,
-		  drvdata->edprsr & EDPRSR_PU ? "On" : "Off",
-		  drvdata->edprsr & EDPRSR_R ? "Yes" : "No",
-		  drvdata->edprsr & EDPRSR_DLK ? "Lock" : "Unlock");
+	dev_warn(dev, " EDPRSR:  %08x (Power:%s Reset:%s DLK:%s)\n",
+		 drvdata->edprsr,
+		 drvdata->edprsr & EDPRSR_PU ? "On" : "Off",
+		 drvdata->edprsr & EDPRSR_R ? "Yes" : "No",
+		 drvdata->edprsr & EDPRSR_DLK ? "Lock" : "Unlock");
 
 	if (!debug_access_permitted(drvdata)) {
-		dev_emerg(dev, "No permission to access debug registers!\n");
+		dev_warn(dev, "No permission to access debug registers!\n");
 		return;
 	}
 
 	if (drvdata->edpcsr == EDPCSR_PROHIBITED) {
-		dev_emerg(dev, "CPU is in Debug state or profiling is prohibited!\n");
+		dev_warn(dev, "CPU is in Debug state or profiling is prohibited!\n");
 		return;
 	}
 
 	pc = debug_adjust_pc(drvdata);
-	dev_emerg(dev, " EDPCSR:  %pS\n", (void *)pc);
+	dev_warn(dev, " EDPCSR:  %pS\n", (void *)pc);
 
 	if (drvdata->edcidsr_present)
-		dev_emerg(dev, " EDCIDSR: %08x\n", drvdata->edcidsr);
+		dev_warn(dev, " EDCIDSR: %08x\n", drvdata->edcidsr);
 
 	if (drvdata->edvidsr_present)
-		dev_emerg(dev, " EDVIDSR: %08x (State:%s Mode:%s Width:%dbits VMID:%x)\n",
-			  drvdata->edvidsr,
-			  drvdata->edvidsr & EDVIDSR_NS ?
-			  "Non-secure" : "Secure",
-			  drvdata->edvidsr & EDVIDSR_E3 ? "EL3" :
+		dev_warn(dev, " EDVIDSR: %08x (State:%s Mode:%s Width:%dbits VMID:%x)\n",
+			 drvdata->edvidsr,
+			 drvdata->edvidsr & EDVIDSR_NS ?
+			 "Non-secure" : "Secure",
+			 drvdata->edvidsr & EDVIDSR_E3 ? "EL3" :
 				(drvdata->edvidsr & EDVIDSR_E2 ?
 				 "EL2" : "EL1/0"),
-			  drvdata->edvidsr & EDVIDSR_HV ? 64 : 32,
-			  drvdata->edvidsr & (u32)EDVIDSR_VMID);
+			 drvdata->edvidsr & EDVIDSR_HV ? 64 : 32,
+			 drvdata->edvidsr & (u32)EDVIDSR_VMID);
 }
 
 static void debug_init_arch_data(void *info)
@@ -441,18 +441,18 @@ static int debug_stall_notifier_call(struct notifier_block *self,
 			continue;
 
 		if (!banner) {
-			pr_emerg("ARM external debug module:\n");
+			pr_warn("ARM external debug module:\n");
 			banner = true;
 		}
 
 		idle = cpumask_test_cpu(cpu, stall->idle);
 		if (idle && READ_ONCE(debug_skip_idle)) {
-			dev_emerg(drvdata->dev, "CPU[%d]: idle, not sampled\n",
-				  drvdata->cpu);
+			dev_warn(drvdata->dev, "CPU[%d]: idle, not sampled\n",
+				 drvdata->cpu);
 			continue;
 		}
 
-		dev_emerg(drvdata->dev, "CPU[%d]:\n", drvdata->cpu);
+		dev_warn(drvdata->dev, "CPU[%d]:\n", drvdata->cpu);
 
 		if (idle)
 			debug_read_regs(drvdata);

-- 
2.43.0

