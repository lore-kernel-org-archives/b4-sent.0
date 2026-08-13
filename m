From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/2] coresight: etm-perf: fix resume AUX leak and
 exclude_kernel bypass
Date: Thu, 13 Aug 2026 20:47:15 +0800
Message-Id: <20260813-coresight-fixes-v1-0-7411a73cd496@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANO8fWoC/x3LSwqAMAwA0atI1hZiFX9XERfSxDabKo2IULy7x
 eVjmAzKSVhhrjIkvkXliAVNXYELW/RshIrBou1xbFrjjsQqPlxml4fVDDQhoe2QaINynYn/UKZ
 lfd8PGvv9s2EAAAA=
X-Change-ID: 20260813-coresight-fixes-7d90d0240dda
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1493;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=VpG4nwidpgDqllXzLatya6ZM559BrQia13sMRj/SAJg=;
 b=kA0DAAoWceg4UIuO8EAByyZiAGp9vNSjHQlEcb9EjdLpv+Fnx2ZHfkz4l9Q3T+XGlV9mSIcAh
 Yh1BAAWCgAdFiEEx3DS9jhNtC20TLRjceg4UIuO8EAFAmp9vNQACgkQceg4UIuO8EDvZwEAnaw5
 wS8HmZVvjl7Z/YhUflgIhG8lLALa73Cq983JJgIA/2r6v15+IanMe3rftVpzLwidlGuVhwgCozh
 ut7ZF6/kO
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two independent fixes for coresight-etm-perf.c, both tagged for stable.

Patch 1: etm_event_start() shares one error label between the initial
start and the PERF_EF_RESUME path. Taking it on resume skips
fail_end_stop, leaving the AUX transaction from the earlier successful
start outstanding while the event is marked PERF_HES_STOPPED.
etm_event_stop() then returns early, so the AUX handle, the sink, the
remaining path elements and the trace ID are all leaked.

Patch 2: etm_event_init() accepts events with both attr.exclude_kernel
and attr.exclude_user set. Neither config parser ORs the mode bits, so
ETM_MODE_EXCL_KERN is overwritten by ETM_MODE_EXCL_USER and the tracer
is programmed to trace the kernel instead. perf_event_open() skips
perf_allow_kernel() when attr.exclude_kernel is set, so an unprivileged
caller can reach this.

Build tested for arm64. I have no CoreSight hardware, so neither fix has
been exercised at runtime.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (2):
      coresight: etm-perf: don't leak the AUX handle on failed resume
      coresight: etm-perf: reject events that exclude both kernel and user space

 drivers/hwtracing/coresight/coresight-etm-perf.c | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)
---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260813-coresight-fixes-7d90d0240dda

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

