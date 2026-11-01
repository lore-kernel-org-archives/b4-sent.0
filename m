From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 31 Oct 2026 23:30:55 -0300
Subject: [PATCH] drm/msm/a5xx: Write CP_RB_WPTR under the ring's
 preempt_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-a5xx-wptr-lock-v1-1-fa7d7b9a7fbe@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ5EMBCA4VeROZvEtKmDV9k4UFMGQVq7moh31
 +X4Hf7/hMBeOECVneD5J0HWJYHyDOzQLD2jdMmgClVSoQkbEyMe2+5xXu2ExrRkSGvlrIMUbZ6
 dxGf4qV+Hbzuy3f8XuK4bHMQP9nIAAAA=
X-Change-ID: 20261031-a5xx-wptr-lock-55b151332fcf
To: Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jordan Crouse <jordan@cosmicpenguin.net>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793500256; l=3913;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=SUNATcfAyOfKteGeuYntWXBBaaQFnfxYwXjBjp6a+vU=;
 b=ZMKnqzhG6IvyxdK/sCwhtNHfQiyo+Tuzwg7/AsYhB8BROSd9CZjCN4WCviZhiZo7TMnoFkvci
 T5kHFg5BUdxDhvD0Tc0/R4AjvSBNoSiRgbkW89xgsE+Now3SbyqgGRt
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CP_RB_WPTR tells the CP how far the ring has been filled. Two functions
write it: a5xx_flush(), after a submit is added to the ring, and
update_wptr(), which a5xx_preempt_trigger() calls from the IRQ handler
each time a submit completes, whenever there is more than one ring,
even when no ring switch follows. Both read the ring's wptr holding
ring->preempt_lock, but write the register after releasing it, so the
two writes can land in the wrong order:

  CPU A, IRQ:   update_wptr() reads wptr N
  CPU B, flush: a5xx_flush() reads wptr N+1, writes N+1
  CPU A, IRQ:   update_wptr() writes N

CP_RB_WPTR then points behind the last submit. If the CP has already
read past N, it treats the ring as nearly full and executes the
commands left over from its previous pass through the ring. This shows
up as CP opcode errors, and the old submits write old fences, so the
fence in memptrs goes backwards. Recovery then finds no submit to
blame and does not reset the GPU, which stays hung until reboot.

Write the register before releasing the lock in both places, so the
last value written is always the newest, as a6xx_flush() does.

Fixes: b1fc2839d2f9 ("drm/msm: Implement preemption for A5XX targets")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on A508 (SDM630), with piglit's texelfetch tests run in
parallel: CP opcode errors in each of seven one-minute runs, the
seventh ending in a hang that never recovers; with this, none in 25.

The downstream driver writes the register holding the ring's
preempt_lock in both of its places:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno_ringbuffer.c#L104
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno_a5xx_preempt.c#L25
---
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c     | 10 +++++++---
 drivers/gpu/drm/msm/adreno/a5xx_preempt.c |  3 +--
 2 files changed, 8 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index 16c7335c4b1f..63b313328979 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -53,14 +53,18 @@ void a5xx_flush(struct msm_gpu *gpu, struct msm_ringbuffer *ring,
 	/* Make sure to wrap wptr if we need to */
 	wptr = get_wptr(ring);
 
-	spin_unlock_irqrestore(&ring->preempt_lock, flags);
-
 	/* Make sure everything is posted before making a decision */
 	mb();
 
-	/* Update HW if this is the current ring and we are not in preempt */
+	/*
+	 * Update HW if this is the current ring and we are not in preempt.
+	 * Under the lock, so that update_wptr() cannot write an older wptr
+	 * after this one.
+	 */
 	if (a5xx_gpu->cur_ring == ring && !a5xx_in_preempt(a5xx_gpu))
 		gpu_write(gpu, REG_A5XX_CP_RB_WPTR, wptr);
+
+	spin_unlock_irqrestore(&ring->preempt_lock, flags);
 }
 
 static void a5xx_submit_in_rb(struct msm_gpu *gpu, struct msm_gem_submit *submit)
diff --git a/drivers/gpu/drm/msm/adreno/a5xx_preempt.c b/drivers/gpu/drm/msm/adreno/a5xx_preempt.c
index e4924b5e1c48..0deac58bc22e 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_preempt.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_preempt.c
@@ -47,9 +47,8 @@ static inline void update_wptr(struct msm_gpu *gpu, struct msm_ringbuffer *ring)
 
 	spin_lock_irqsave(&ring->preempt_lock, flags);
 	wptr = get_wptr(ring);
-	spin_unlock_irqrestore(&ring->preempt_lock, flags);
-
 	gpu_write(gpu, REG_A5XX_CP_RB_WPTR, wptr);
+	spin_unlock_irqrestore(&ring->preempt_lock, flags);
 }
 
 /* Return the highest priority ringbuffer with something in it */

---
base-commit: a39c950806213f6861d00f90729acaaa21f2d95a
change-id: 20261031-a5xx-wptr-lock-55b151332fcf

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

