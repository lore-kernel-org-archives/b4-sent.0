From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Thu, 05 Nov 2026 19:24:20 +0530
Subject: [PATCH] drm/amdgpu: Don't report stale or empty vm_fault info in
 devcoredump
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-amdgpu-devcoredump-fault-info-v1-1-27c8165bfada@zohomail.in>
X-B4-Tracking: v=1; b=H4sIAIuK7GoC/yXMQQ7CIBAF0Ks0s3aSQsSoVzEuKHzqGAsESmPS9
 O5WXb7NW6miCCpdu5UKFqmS4g516Mg9bBzB4neT7vVJqd6wnfyYG3ssLhX4NmUOtr1mlhgSB3c
 5D0cYBaNpP3JBkPfvv93/rm14ws3flLbtA9Mg+5SBAAAA
X-Change-ID: 20261105-amdgpu-devcoredump-fault-info-fc98b4e51e52
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 Pierre-Eric Pelloux-Prayer <pierre-eric.pelloux-prayer@amd.com>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793886864; l=9011;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=pxJdK58/DE/CF4k68X1Ta99ypQMPKDBtaSO5Tn3JsCA=;
 b=OE30HWXc+saro0yTGSUaaaSebrlZ9EurHBZcEc2AhuW9pQxNJyOKpk8CGsD3YM9nHfv/Lend9
 L8u8R2METOvCWn0rlnGZdvv3YtgIa2Bm3c3ypDizJQevNwVFlI2svFU
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amdgpu_devcoredump_format() reads adev->vm_manager.fault_info unlocked
from the deferred worker and prints the page fault section
unconditionally. This races with new faults, emits a misleading address
0x0 / status 0x0 block when no fault occurred, and repeats stale faults
on subsequent non-fault timeouts.

Add amdgpu_vm_take_fault_info() to atomically snapshot and clear the
global fault cache under amdgpu_pasid_lock(). Call it before the slow
dump_ip_state() loop in amdgpu_job_do_core_dump() (or in
amdgpu_coredump() for non-job resets), store the snapshot in struct
amdgpu_coredump_info, and only print the fault section when
fault_info.status != 0.

Link: https://lore.kernel.org/amd-gfx/20250521094912.6714-2-pierre-eric.pelloux-prayer@amd.com/
Suggested-by: Pierre-Eric Pelloux-Prayer <pierre-eric.pelloux-prayer@amd.com>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Tested on Rembrandt / Yellow Carp (gfx1033) using IGT amd_deadlock:

1. amdgpu-gfx-illegal-reg-access (no VM fault): no fault block emitted
2. amdgpu-gfx-illegal-mem-access (VM fault): fault emitted (status 0x640c51)
3. amdgpu-gfx-illegal-reg-access (post-fault): stale fault cleared, no fault emitted

Note: Captures and clears fault_info under amdgpu_pasid_lock() before 
dump_ip_state() per Christian Konig's review on v1.
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.c | 24 +++++++++++++++++-------
 drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.h |  4 +++-
 drivers/gpu/drm/amd/amdgpu/amdgpu_device.c       |  3 ++-
 drivers/gpu/drm/amd/amdgpu/amdgpu_job.c          |  9 ++++++++-
 drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c           | 22 ++++++++++++++++++++++
 drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h           |  2 ++
 6 files changed, 54 insertions(+), 10 deletions(-)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.c
index 30a8b4c5591d..d93b426a87bb 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.c
@@ -30,7 +30,8 @@
 
 #ifndef CONFIG_DEV_COREDUMP
 void amdgpu_coredump(struct amdgpu_device *adev, bool skip_vram_check,
-		     bool vram_lost, struct amdgpu_job *job)
+		     bool vram_lost, struct amdgpu_job *job,
+		     const struct amdgpu_vm_fault_info *fault_info)
 {
 }
 void amdgpu_coredump_init(struct amdgpu_device *adev)
@@ -418,11 +419,15 @@ amdgpu_devcoredump_format(char *buffer, size_t count, struct amdgpu_coredump_inf
 	}
 
 	/* Add page fault information */
-	fault_info = &coredump->adev->vm_manager.fault_info;
-	drm_printf(&p, "\n[%s] Page fault observed\n",
-		   fault_info->vmhub ? "mmhub" : "gfxhub");
-	drm_printf(&p, "Faulty page starting at address: 0x%016llx\n", fault_info->addr);
-	drm_printf(&p, "Protection fault status register: 0x%x\n\n", fault_info->status);
+	fault_info = &coredump->fault_info;
+	if (fault_info->status != 0) {
+		drm_printf(&p, "\n[%s] Page fault observed\n",
+			   fault_info->vmhub ? "mmhub" : "gfxhub");
+		drm_printf(&p, "Faulty page starting at address: 0x%016llx\n",
+			   fault_info->addr);
+		drm_printf(&p, "Protection fault status register: 0x%x\n\n",
+			   fault_info->status);
+	}
 
 	/* dump the ip state for each ip */
 	drm_printf(&p, "IP Dump\n");
@@ -542,7 +547,8 @@ static void amdgpu_devcoredump_deferred_work(struct work_struct *work)
 }
 
 void amdgpu_coredump(struct amdgpu_device *adev, bool skip_vram_check,
-		     bool vram_lost, struct amdgpu_job *job)
+		     bool vram_lost, struct amdgpu_job *job,
+		     const struct amdgpu_vm_fault_info *fault_info)
 {
 	struct drm_device *dev = adev_to_drm(adev);
 	struct amdgpu_coredump_info *coredump;
@@ -565,6 +571,10 @@ void amdgpu_coredump(struct amdgpu_device *adev, bool skip_vram_check,
 
 	coredump->skip_vram_check = skip_vram_check;
 	coredump->reset_vram_lost = vram_lost;
+	if (fault_info)
+		coredump->fault_info = *fault_info;
+	else
+		amdgpu_vm_take_fault_info(adev, &coredump->fault_info);
 
 	if (job && job->pasid) {
 		struct amdgpu_task_info *ti;
diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.h b/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.h
index cb874d8c3394..85d476828473 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.h
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_dev_coredump.h
@@ -50,6 +50,7 @@ struct amdgpu_coredump_info {
 
 	bool                            skip_vram_check;
 	bool                            reset_vram_lost;
+	struct amdgpu_vm_fault_info     fault_info;
 	struct amdgpu_ring              *ring;
 
 	struct amdgpu_coredump_ring	*rings;
@@ -69,7 +70,8 @@ struct amdgpu_coredump_info {
 #endif
 
 void amdgpu_coredump(struct amdgpu_device *adev, bool skip_vram_check,
-		     bool vram_lost, struct amdgpu_job *job);
+		     bool vram_lost, struct amdgpu_job *job,
+		     const struct amdgpu_vm_fault_info *fault_info);
 void amdgpu_coredump_init(struct amdgpu_device *adev);
 void amdgpu_coredump_fini(struct amdgpu_device *adev);
 #endif
diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_device.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_device.c
index bcaa59da2369..95fded3757f9 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_device.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_device.c
@@ -5218,7 +5218,8 @@ int amdgpu_device_reinit_after_reset(struct amdgpu_reset_context *reset_context)
 				vram_lost = amdgpu_device_check_vram_lost(tmp_adev);
 
 				if (!test_bit(AMDGPU_SKIP_COREDUMP, &reset_context->flags))
-					amdgpu_coredump(tmp_adev, false, vram_lost, reset_context->job);
+					amdgpu_coredump(tmp_adev, false, vram_lost,
+							reset_context->job, NULL);
 
 				if (vram_lost) {
 					dev_info(
diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_job.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_job.c
index 9cc210198fa4..c808f59dbe05 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_job.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_job.c
@@ -36,8 +36,15 @@
 static void amdgpu_job_do_core_dump(struct amdgpu_device *adev,
 				    struct amdgpu_job *job)
 {
+	struct amdgpu_vm_fault_info fault_info;
 	int i;
 
+	/*
+	 * The IP state dump below can take seconds.  Take the snapshot before
+	 * it, while holding the same lock as the interrupt handler.
+	 */
+	amdgpu_vm_take_fault_info(adev, &fault_info);
+
 	dev_info(adev->dev, "Dumping IP State\n");
 	for (i = 0; i < adev->num_ip_blocks; i++)
 		if (adev->ip_blocks[i].version->funcs->dump_ip_state)
@@ -45,7 +52,7 @@ static void amdgpu_job_do_core_dump(struct amdgpu_device *adev,
 				->dump_ip_state((void *)&adev->ip_blocks[i]);
 	dev_info(adev->dev, "Dumping IP State Completed\n");
 
-	amdgpu_coredump(adev, true, false, job);
+	amdgpu_coredump(adev, true, false, job, &fault_info);
 }
 
 static void amdgpu_job_core_dump(struct amdgpu_device *adev,
diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c
index 2bd07007def4..ac9bf1991e28 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c
@@ -3274,6 +3274,28 @@ void amdgpu_vm_update_fault_cache(struct amdgpu_device *adev,
 	amdgpu_pasid_unlock(flags);
 }
 
+/**
+ * amdgpu_vm_take_fault_info - snapshot and clear the global fault cache
+ * @adev: amdgpu device pointer
+ * @fault_info: destination for the fault information
+ *
+ * The fault cache is updated by amdgpu_vm_update_fault_cache() under the
+ * PASID lock.  Take the snapshot and clear the cache in the same critical
+ * section so that a fault arriving after the snapshot is not overwritten,
+ * and a consumed fault is not reported again in a later timeout.
+ */
+void amdgpu_vm_take_fault_info(struct amdgpu_device *adev,
+			       struct amdgpu_vm_fault_info *fault_info)
+{
+	unsigned long flags;
+
+	amdgpu_pasid_lock(&flags);
+	*fault_info = adev->vm_manager.fault_info;
+	memset(&adev->vm_manager.fault_info, 0,
+	       sizeof(adev->vm_manager.fault_info));
+	amdgpu_pasid_unlock(flags);
+}
+
 void amdgpu_vm_print_task_info(struct amdgpu_device *adev,
 			       struct amdgpu_task_info *task_info)
 {
diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h b/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h
index 8e478d3bda1a..f89596ce3879 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h
@@ -575,6 +575,8 @@ void amdgpu_vm_update_fault_cache(struct amdgpu_device *adev,
 				  uint64_t addr,
 				  uint32_t status,
 				  unsigned int vmhub);
+void amdgpu_vm_take_fault_info(struct amdgpu_device *adev,
+			       struct amdgpu_vm_fault_info *fault_info);
 void amdgpu_vm_tlb_fence_create(struct amdgpu_device *adev,
 				 struct amdgpu_vm *vm,
 				 struct dma_fence **fence);

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261105-amdgpu-devcoredump-fault-info-fc98b4e51e52

Best regards,
--  
Shivam Kalra <shivamkalra98@zohomail.in>

