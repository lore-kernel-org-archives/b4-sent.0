From: Awal Awal <awal.nova@gmail.com>
Date: Fri, 23 Oct 2026 10:08:45 +0200
Subject: [PATCH] platform/x86/amd/pmf: Fix memory leak in NPU metrics query
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-amd-pmf-npu-leak-v1-1-798e7161bfba@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTPJ0BKiXsWwqGWKo1KblhoSw
 t2psHyL/1dIHIUT3KoVIv8kydcXNHUF9mn8yChDMShSXUNKo5kGDJNDHzJ+2LzRte3V6IslTQQ
 lC5GdLMfy3p9O+fFiO/8/sG07ppGRFXQAAAA=
X-Change-ID: 20261023-amd-pmf-npu-leak-f449a38c0300
To: Shyam Sundar S K <Shyam-sundar.S-k@amd.com>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: Lizhi Hou <lizhi.hou@amd.com>, Mario Limonciello <superm1@kernel.org>, 
 platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Awal Awal <awal.nova@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792742928; l=2529;
 i=awal.nova@gmail.com; s=20261023; h=from:subject:message-id;
 bh=1bjGttJlIKK90PokbdtL9brjGLD+8hVegScmsmTQyH8=;
 b=qI5h+6XD1sXXYtGPyE9ijcPejx4iL2AwYuBs1zP7tlGEssCU9Ln+c3edzB+QHoiwKS44YIxC3
 cMv68bxQ6R7DxsHLeL29Xy4Kity9Z2S948WZaQK2CQFQ86L5ZZ8lBvu
X-Developer-Key: i=awal.nova@gmail.com; a=ed25519;
 pk=wrV+x9VJEgMwdldj38seKq88Gn1n1guE6xG6rtmR6Fs=
X-Endpoint-Received: by B4 Relay for awal.nova@gmail.com/20261023 with auth_id=1286
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amd_pmf_get_smu_metrics() calls amd_pmf_set_dram_addr() with
alloc_buffer set to true on every NPU metrics request. Each call
devm_kzalloc()s a new metrics table buffer and overwrites dev->buf with
it. The previous buffer stays on the devres list and is only released
when the device is unbound, so every request leaks one buffer.

amdxdna calls amd_pmf_get_npu_data() for its sensor query, so any
userspace monitor that polls NPU utilisation through
DRM_IOCTL_AMDXDNA_GET_INFO leaks memory for as long as it runs. On a
Ryzen AI 9 365 (family 1Ah model 20h) laptop with a system monitor
polling about 1.4 times per second, the kmalloc-512 cache grew to 5.8
million objects (2.8 GiB) over 38 days of uptime.

The buffer size depends only on the CPU ID, and the buffer is usually
already allocated by amd_pmf_init_metrics_table() or
amd_pmf_init_smart_pc(). Allocate it only if it does not exist yet and
keep reprogramming its address on every request as before.

Fixes: 118222e20d16 ("platform/x86/amd/pmf: Introduce new interface to export NPU metrics")
Cc: stable@vger.kernel.org
Signed-off-by: Awal Awal <awal.nova@gmail.com>
---
Tested on a Lenovo Yoga Pro 7 14ASP10 (Ryzen AI 9 365) with the
equivalent change applied to core.c of a 7.0.14 based kernel. With the
Resources app polling, the unpatched driver made 84 devm_kmalloc() calls
for 84 NPU metrics queries in 60 s. The patched driver served 106
queries in 60 s, all returning 0, with no devm_kmalloc() calls and a
flat kmalloc-512 cache.

Up to v7.2 this code lives in drivers/platform/x86/amd/pmf/core.c
(it moved to metrics.c in v7.3); the same one-line change applies to
amd_pmf_get_smu_metrics() there.
---
 drivers/platform/x86/amd/pmf/metrics.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/platform/x86/amd/pmf/metrics.c b/drivers/platform/x86/amd/pmf/metrics.c
index 5c0e368ec..6bad7a409 100644
--- a/drivers/platform/x86/amd/pmf/metrics.c
+++ b/drivers/platform/x86/amd/pmf/metrics.c
@@ -261,7 +261,7 @@ static int amd_pmf_get_smu_metrics(struct amd_pmf_dev *dev, struct amd_pmf_npu_m
 	switch (dev->cpu_id) {
 	case PCI_DEVICE_ID_AMD_1AH_M20H_ROOT:
 	case PCI_DEVICE_ID_AMD_1AH_M60H_ROOT:
-		ret = amd_pmf_set_dram_addr(dev, true);
+		ret = amd_pmf_set_dram_addr(dev, !dev->buf);
 		if (ret)
 			return ret;
 

---
base-commit: 893018d51f27ec0449155b0afe371aaf65380630
change-id: 20261023-amd-pmf-npu-leak-f449a38c0300

Best regards,
--  
Awal Awal <awal.nova@gmail.com>

