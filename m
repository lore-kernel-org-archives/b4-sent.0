From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 24 Nov 2026 04:39:15 +0000
Subject: [PATCH] drm/lima: Drop the BO references if drm_sched_job_init()
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-lima-task-init-v1-1-2f6129257703@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPIUBWsC/yXMQQ6CMBBG4auQWTuJbaSJXoWwaOFXB6SYTjEmh
 LtbcPkt3ltJkQRKt2qlhI+ozLHAnCrqnj4+wNIXkz1bZ4y98Esmz9nryBIlc+1wdQGhhwWV6J1
 wl+8xbNq/dQkDurxfaNt+W2MAHHIAAAA=
X-Change-ID: 20261124-lima-task-init-56e96bebde2e
To: mripard@kernel.org, maarten.lankhorst@linux.intel.com, 
 airlied@gmail.com, tzimmermann@suse.de, simona@ffwll.ch, yuq825@gmail.com
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 lima@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795495155; l=1654;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=/psVm8KZ+NeNNkX1NAHNJo3pQfX2J9S1jdpWT36nW1c=;
 b=D9Y+EJAIZAEfI2n5DQLlisXJ/b+PO18rZa6q9Leh9qSy6G8ULP9bTgAOY81dFvUWiZWyL/8Qs
 2Ghk91cvyYIBUoUlVlSz+vCuekbT2Sw5o2rL8LdZZ2qaGZOPtxGGYlA
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

lima_sched_task_init() takes a reference on every BO of the task before
it calls drm_sched_job_init():

	for (i = 0; i < num_bos; i++)
		drm_gem_object_get(&bos[i]->base.base);

	err = drm_sched_job_init(&task->base, &context->base, 1, vm,
				 drm_client_id);
	if (err) {
		kfree(task->bos);
		return err;
	}

If drm_sched_job_init() fails (it can return -ENOMEM), only the array is
freed. lima_gem_submit() then goes to err_out1, which does not call
lima_sched_task_fini(), so these extra references are never dropped and
the BOs are not freed even after all other references are gone. This
can happen on every submit ioctl.

Put the references before freeing the array.

Found with a static analysis tool and checked by hand.

Fixes: a1d2a6339961 ("drm/lima: driver for ARM Mali4xx GPUs")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm64 (W=1). I don't have the hardware.
---
 drivers/gpu/drm/lima/lima_sched.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/lima/lima_sched.c b/drivers/gpu/drm/lima/lima_sched.c
index fee595b9629a..53d597850782 100644
--- a/drivers/gpu/drm/lima/lima_sched.c
+++ b/drivers/gpu/drm/lima/lima_sched.c
@@ -130,6 +130,8 @@ int lima_sched_task_init(struct lima_sched_task *task,
 	err = drm_sched_job_init(&task->base, &context->base, 1, vm,
 				 drm_client_id);
 	if (err) {
+		for (i = 0; i < num_bos; i++)
+			drm_gem_object_put(&bos[i]->base.base);
 		kfree(task->bos);
 		return err;
 	}



