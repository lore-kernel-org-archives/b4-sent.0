From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH v3 0/4] drm/msm/a5xx: Fix GPU stalls on A508, A509 and A512
Date: Sat, 07 Nov 2026 17:26:06 -0300
Message-Id: <20261107-a5xx-gpu-pm-v3-0-e2480408abea@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBQFr0K6tqa/BUFX3sO4aMsHaoSSFhoM4
 e62uHFhXE7yZt5KPDqDnlyylTgMxhs7RBCHjOhODi1SU0cmnPETMDhTWSwLbceZjj1tikrpHJG
 LqiTRGB02Ztlrt/uH/aweqKeUSIvO+Mm6134XIO1+lwNQRqFmWoCQkAO/tr00z6O2PUnlwP+4P
 Lp5UUrZKMWrWn6727a9AZjV/KP0AAAA
X-Change-ID: 20261019-a5xx-gpu-pm-f58bc4ee2387
To: Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Paul Sajna <sajattack@postmarketos.org>, 
 Fabricio Akio <fabricioakio@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794083169; l=3229;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=zOocD9OAKC3L83jqC67Z507icBwIJgZhFceeOcw6S5A=;
 b=cY1LOcQELddWUz203MSFnaz4UExS8C9q9xOC4CNgUatrCxYlHrIi9TxA5q7soOudPMxPi/5wA
 w0XJfQrp2t2BAECVe5wwqXko/m2PhlGMV6X0WiYUM2E8TowNGmuHEhd
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes to how the A508, A509 and A512 power up and down, found running
a phone shell on an SDM630 phone.

The second resets the GPU on every resume: on SDM630, SDM660 and
MSM8998 the device tree attaches the GPU's GX power domain to its SMMU,
so a GPU resumed soon after suspending keeps its state, and its CP runs
stale ringbuffer contents and hangs. The reset clears the busy counter
devfreq samples, so the first lets each GPU resume devfreq from its own
resume callback, and the second resumes it after the reset.

The third holds a CPU latency request while the GPU is powered, as the
downstream driver does: on SDM630 the GPU stops executing while the SoC
is in system-level power collapse, so a submission overlapping such a
state would stall and trip the hang detector. Mainline does not
describe that state yet, so the request blocks nothing until it does.
The fourth powers these GPUs down after downstream's 80 ms idle instead
of the A530's 250 ms, so the request is released when downstream
releases it.

Each patch builds on the one before it.

Tested on a Motorola Moto X4 (SDM630, A508), whose board file is not
in mainline yet, on sdm660-mainline's 7.2 kernel. The stall the third
patch prevents was measured with SDM630's system-level idle state from
a series not yet sent.

---
Changes in v3:
- New patch 1: resume devfreq from each GPU's resume callback (Akhil)
- Patch 2: say that the device tree attaches GX to the SMMU, whose own
  domain is CX (Konrad, Akhil); resume devfreq after the reset instead
  of taking its baseline again (Akhil); dropped Dmitry's Tested-by
- Patch 3: take 2336 us, which leaves every CPU and cluster idle state
  available, instead of downstream's 424 and 518 us, which also kept
  every CPU out of power collapse (Dmitry); drop the request on destroy
  after adreno_gpu_cleanup(), which stops runtime PM and the GPU
  worker, so nothing can take it again before it is freed (Sashiko)
- Link to v2: https://patch.msgid.link/20261019-a5xx-gpu-pm-v2-0-457aafbb28da@gmail.com

Changes in v2:
- Patch 1: take devfreq's busy-cycle baseline again after the reset,
  which clears the busy counter (Sashiko)
- Link to v1: https://patch.msgid.link/20261019-a5xx-gpu-pm-v1-0-1d0c313a1412@gmail.com

---
Fabricio Akio (4):
      drm/msm: Resume devfreq from each GPU's resume callback
      drm/msm/a5xx: Reset the GPU when resuming it
      drm/msm/a5xx: Hold a CPU latency request while the GPU is powered
      drm/msm/a5xx: Use the downstream GPU idle timeout on A508, A509 and A512

 drivers/gpu/drm/msm/adreno/a3xx_gpu.c     | 15 ++++++++++++++-
 drivers/gpu/drm/msm/adreno/a4xx_gpu.c     |  2 ++
 drivers/gpu/drm/msm/adreno/a5xx_catalog.c | 21 ++++++---------------
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c     | 29 +++++++++++++++++++++++++++++
 drivers/gpu/drm/msm/adreno/a5xx_gpu.h     |  4 ++++
 drivers/gpu/drm/msm/adreno/adreno_gpu.h   |  5 +++++
 drivers/gpu/drm/msm/msm_gpu.c             |  2 --
 7 files changed, 60 insertions(+), 18 deletions(-)
---
base-commit: a39c950806213f6861d00f90729acaaa21f2d95a
change-id: 20261019-a5xx-gpu-pm-f58bc4ee2387

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

