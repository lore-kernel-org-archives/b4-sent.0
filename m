From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:12:43 +0000
Subject: [PATCH] drm/msm: Use div64_u64() for the retired-submit GPU clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-drm-msm-retire-div64-v1-1-94d6981799d0@enser.io>
X-B4-Tracking: v=1; b=H4sIAMp5AmsC/yXMwQ7CIBAE0F9p9uxqoUjVXzEeCqx2TUrNUolJ0
 38X9PgmM7NCImFKcGlWEMqceI4FateAH4f4IORQDLrVVimt0RkMMuGUJhRaWAgDZ2tQqePp3Pa
 d6qyHsn4J3fnze77e/k5v9yS/1LvacEMidDJEP9ao8pD7vUHxGrbtC28RdYObAAAA
X-Change-ID: 20261122-b4-drm-msm-retire-div64-11589073136c
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>
Cc: Sean Paul <sean@poorly.run>, Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jordan Crouse <jordan@cosmicpenguin.net>, linux-arm-msm@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, freedreno@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324363; l=2454;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=Mv5vF8Oc99FZKnLAmD9sYhN9n2NgdGEHtxT8xvPHv9k=;
 b=8RCUs9bzCxX/GEB0D3HUaQ+guM16RHO+kqTUQCCGyfxj59dfKUi6VE0gUKqIhQsdbY1hCvUlo
 B7cYzZs8VnlADWgwc/F13bjCDvVt6sX5AdYfg0AW4KcfNteRjdqqTYU
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

retire_submit() derives the GPU clock from the CP cycle and always-on
counter deltas:

	if (elapsed) {
		clock = cycles * 1000;
		do_div(clock, elapsed);
	}

elapsed is a u64, but do_div() takes a 32-bit divisor, so it is silently
truncated. The guard tests all 64 bits while the division uses only the
low 32, so any elapsed value that is a non-zero multiple of 2^32 divides
by zero, and any value of 2^32 ns or more gives a wrong clock. On 32-bit
ARM the division by zero lands in __do_div64 and prints "Division by zero
in kernel" with a backtrace on every such retire.

Observed on an Adreno 330 (MSM8974, LG Nexus 5) running a downstream
6.16 kernel: the backtrace repeated every 0.3-0.9 s from the first GPU
submit, 232 times in 34 minutes. The faulting return address,
retire_submits+0x3dc, is the instruction after the only
non-constant-divisor __do_div64 call in the function. Why elapsed has
zero low 32 bits so often on this GPU was not investigated.

Use div64_u64(), which takes a 64-bit divisor.

Tested on the downstream postmarketOS 6.16.12 msm8974 kernel on a Nexus
5: no "Division by zero" over an 1850 s soak with about 30 minutes of
GPU load (before: 232 in 34 minutes). On this tree it is build-tested
only.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: 4241db42e474 ("drm/msm/gpu: Add trace events for tracking GPU submissions")
Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/gpu/drm/msm/msm_gpu.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/msm/msm_gpu.c b/drivers/gpu/drm/msm/msm_gpu.c
index 8319119041..8b99998e19 100644
--- a/drivers/gpu/drm/msm/msm_gpu.c
+++ b/drivers/gpu/drm/msm/msm_gpu.c
@@ -705,10 +705,8 @@ static void retire_submit(struct msm_gpu *gpu, struct msm_ringbuffer *ring,
 	cycles = stats->cpcycles_end - stats->cpcycles_start;
 
 	/* Calculate the clock frequency from the number of CP cycles */
-	if (elapsed) {
-		clock = cycles * 1000;
-		do_div(clock, elapsed);
-	}
+	if (elapsed)
+		clock = div64_u64(cycles * 1000, elapsed);
 
 	submit->queue->ctx->elapsed_ns += elapsed;
 	submit->queue->ctx->cycles     += cycles;

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-drm-msm-retire-div64-11589073136c

Best regards,
--  
EMCP333 <emcp@enser.io>

