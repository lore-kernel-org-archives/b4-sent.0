From: Junrui Luo <moonafterrain@outlook.com>
Date: Thu, 13 Aug 2026 20:47:17 +0800
Subject: [PATCH 2/2] coresight: etm-perf: reject events that exclude both
 kernel and user space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-coresight-fixes-v1-2-7411a73cd496@outlook.com>
References: <20260813-coresight-fixes-v1-0-7411a73cd496@outlook.com>
In-Reply-To: <20260813-coresight-fixes-v1-0-7411a73cd496@outlook.com>
To: Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@arm.com>, James Clark <james.clark@linaro.org>, 
 Leo Yan <leo.yan@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2362;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=+tTlNVRe/rbkdxYJBnqH+Npz+BDYLaVAW6dG0DYxOHA=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrNo9V/8qvdfao3WvtOtYdOAkb6uwnkvsZyatrJ4vd
 rCYbatm74yOUhYGMS4GWTFFluMFl75Z+G7R3eKzJRlmDisTyBAGLk4BmIhJECPDgc9vbmQpNtmJ
 XTD+v6jq2sPba0Imm7hN2/zNkvN825NyVoZ/RjNW9jxpMdl84rbL75Dmz9v09B4ufSz9eJNcXlz
 q3EcmTAC2ok/O
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

etm_event_init() validates only attr.type, so a cs_etm event can be
opened with both attr.exclude_kernel and attr.exclude_user set. Both
config parsers assign rather than OR the mode bits, so
ETM_MODE_EXCL_KERN is discarded and only ETM_MODE_EXCL_USER survives.
A request to exclude the kernel therefore programs the tracer to
exclude user space and trace the kernel instead.

config->mode has several downstream consumers -- on ETMv4 the TRCVICTLR
ViewInst filter and the FEAT_TRF controls that exist to backstop it, on
ETMv3 the address comparator access type -- and they all derive that
same configuration from it. Since perf_event_open() skips
perf_allow_kernel() when attr.exclude_kernel is set, this potentially
lets an unprivileged user collect an instruction trace of kernel
execution in a per-task event's AUX buffer. The existing guards do not
catch it: etm4_config_trace_mode() warns on the combination but is
reachable only from sysfs, and the early return in
etm_config_trace_mode() can never fire because mode never holds both
bits.

Reject the combination in etm_event_init(), covering both tracer
generations at the single perf entry point.

Fixes: 882d5e112491 ("coresight: etm3x: implementing perf_enable/disable() API")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/hwtracing/coresight/coresight-etm-perf.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/hwtracing/coresight/coresight-etm-perf.c b/drivers/hwtracing/coresight/coresight-etm-perf.c
index af0295eab143..9cc93d48e970 100644
--- a/drivers/hwtracing/coresight/coresight-etm-perf.c
+++ b/drivers/hwtracing/coresight/coresight-etm-perf.c
@@ -185,6 +185,17 @@ static int etm_event_init(struct perf_event *event)
 		goto out;
 	}
 
+	/*
+	 * Excluding both kernel and user space is not a configuration the
+	 * tracers can express: etm_parse_event_config() and
+	 * etm4_parse_event_config() overwrite ETM_MODE_EXCL_KERN with
+	 * ETM_MODE_EXCL_USER, which ends up tracing the kernel instead.
+	 */
+	if (event->attr.exclude_kernel && event->attr.exclude_user) {
+		ret = -EINVAL;
+		goto out;
+	}
+
 	ret = etm_addr_filters_alloc(event);
 	if (ret)
 		goto out;

-- 
2.51.2

