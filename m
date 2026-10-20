From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH v2 0/3] drm/msm/a5xx: Fix GPU stalls on A508, A509 and A512
Date: Mon, 19 Oct 2026 23:05:07 -0300
Message-Id: <20261019-a5xx-gpu-pm-v2-0-457aafbb28da@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0Jm7ZhOAUVX3sOwKGWAMUJJCwRDu
 LuAW5cvef/9BQJ74QD3aAHPkwRx3Qb6FIFtTFczSrkxaKUvpOiGJp1nrPsR+xarNCtswqzj7Ar
 bovdcyXzUnvmPw1i82A57YjcaCYPzn+Nuot37X54IFVKpbEyxoYT0o26NvM/WtZCv6/oFp/nJf
 LgAAAA=
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
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792461909; l=2141;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=ww0IS2pCRUm3JGopuPyKyAKswNjkjXYoL6LMxImCPLY=;
 b=FcYj4QkL2ZkDvAG/1XX6YtqZNjPmzKQjMCcPsoJy3GwSKkVWM0lsnLQa6pROcr7rYbeH8HamE
 5jP5k7O8TidDRseXvttzlFya7N15nfc4+p5QZQEoNTAlxi7MQBMDxcD
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three changes to how the A508, A509 and A512 power up and down, found
running a phone shell on an SDM630 phone. The first resets the GPU on
every resume: on SDM630, SDM660 and MSM8998 the GPU's GX power domain
belongs to its SMMU, so a GPU resumed soon after suspending keeps its
state, and its CP runs stale ringbuffer contents and hangs. The second
holds a CPU latency request while the GPU is powered, as the
downstream driver does: on SDM630 the GPU stops executing while the
SoC is in system-level power collapse, so a submission overlapping
such a state would stall and trip the hang detector. The third powers
these GPUs down after downstream's 80 ms idle instead of the A530's
250 ms, so the request is released when downstream releases it.

The second patch adds code next to the first's, and the third sits on
the second.

Tested on a Motorola Moto X4 (SDM630, A508), whose board file is not
in mainline yet, on sdm660-mainline's 7.2 kernel. The stall the second
patch prevents was measured with an SDM630 system-level idle state
that is not in mainline.

---
Changes in v2:
- Patch 1: take devfreq's busy-cycle baseline again after the reset,
  which clears the busy counter (Sashiko)
- Link to v1: https://patch.msgid.link/20261019-a5xx-gpu-pm-v1-0-1d0c313a1412@gmail.com

---
Fabricio Akio (3):
      drm/msm/a5xx: Reset the GPU when resuming it
      drm/msm/a5xx: Hold a CPU latency request while the GPU is powered
      drm/msm/a5xx: Use the downstream GPU idle timeout on A508, A509 and A512

 drivers/gpu/drm/msm/adreno/a5xx_catalog.c | 21 ++++++---------------
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c     | 28 ++++++++++++++++++++++++++++
 drivers/gpu/drm/msm/adreno/a5xx_gpu.h     |  4 ++++
 drivers/gpu/drm/msm/adreno/adreno_gpu.h   |  5 +++++
 drivers/gpu/drm/msm/msm_gpu.h             |  1 +
 drivers/gpu/drm/msm/msm_gpu_devfreq.c     | 17 +++++++++++++++++
 6 files changed, 61 insertions(+), 15 deletions(-)
---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20261019-a5xx-gpu-pm-f58bc4ee2387

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

