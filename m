From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:38 +0200
Subject: [PATCH RFC 01/10] Documentation: coresight: cpu-debug: Fix the
 module parameter name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-1-69d3ad1e0fc8@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1068; i=iav@iav.lv;
 h=from:subject:message-id; bh=tdkUlwej4U5iLMdBPWEh+RWe3oS9OYaUeonOCJ3l0xI=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqgXMe7kLxNqEDh488fXZ4aTVtU1rNjzgzmiv/RYz/
 5P8cu3ZHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiSqsY/vtP3ZcafkX8Xciv
 0mdPOv42OHg5yt1XvVByRK0re8U1Hm2Gf4bMJ1VZYpJ/zHXg/hPZfyCqqrzFM/Twzrlzd0b6OXz
 nZgIA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The parameter that enables the debugging is "enable"; the module has no
"debug" parameter.

Fixes: 0cd555c35131 ("doc: Add documentation for Coresight CPU debug")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 Documentation/trace/coresight/coresight-cpu-debug.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/trace/coresight/coresight-cpu-debug.rst b/Documentation/trace/coresight/coresight-cpu-debug.rst
index 836b35532667..32fbae244524 100644
--- a/Documentation/trace/coresight/coresight-cpu-debug.rst
+++ b/Documentation/trace/coresight/coresight-cpu-debug.rst
@@ -130,7 +130,7 @@ If you want to enable debugging functionality at boot time, you can add
 The driver also can work as module, so can enable the debugging when insmod
 module::
 
-  # insmod coresight_cpu_debug.ko debug=1
+  # insmod coresight_cpu_debug.ko enable=1
 
 When boot time or insmod module you have not enabled the debugging, the driver
 uses the debugfs file system to provide a knob to dynamically enable or disable

-- 
2.43.0

