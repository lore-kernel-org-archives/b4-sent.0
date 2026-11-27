From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:39 +0200
Subject: [PATCH RFC 02/10] coresight: cpu-debug: Make the enable parameter
 read-only in sysfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-2-69d3ad1e0fc8@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1474; i=iav@iav.lv;
 h=from:subject:message-id; bh=S8ilSl3i/zzxTPiODOCucBWFSnR+cdlYr4OIODiodjE=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqgVMuWF/PGWT+AvTsqardj47+/nR+4lCX5hbnnMWf
 7gdKKTSUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACZiG8TwV3rmt9UpRv0Pd9Ws
 P7ztS/KNY/3+Vw88KTfNtmV8vCNBfSbDP0vN/9fiwxqPt7hFzWoov7lyH+capqehnkn3d52Vu61
 mzwoA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A write to /sys/module/coresight_cpu_debug/parameters/enable changes
debug_enable but takes no runtime PM reference, so the driver then
reads the debug registers with their clock and power domain possibly
off. A later write to the debugfs knob finds debug_enable already set
and does nothing.

Leave the parameter for the command line and for module load, and the
debugfs knob for run time, as the documentation describes. A set
callback that does what the knob does would also work, but one run-time
interface is enough.

Fixes: 2227b7c74634 ("coresight: add support for CPU debug module")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/hwtracing/coresight/coresight-cpu-debug.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index edccbd2fa5e2..f9e6e344ed59 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -109,7 +109,7 @@ static int debug_count;
 static struct dentry *debug_debugfs_dir;
 
 static bool debug_enable = IS_ENABLED(CONFIG_CORESIGHT_CPU_DEBUG_DEFAULT_ON);
-module_param_named(enable, debug_enable, bool, 0600);
+module_param_named(enable, debug_enable, bool, 0400);
 MODULE_PARM_DESC(enable, "Control to enable coresight CPU debug functionality");
 
 static void debug_os_unlock(struct debug_drvdata *drvdata)

-- 
2.43.0

