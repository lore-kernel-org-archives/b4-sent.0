From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH 0/2] drm/msm: Per-submission GPU time on A5xx
Date: Sat, 31 Oct 2026 23:32:49 -0300
Message-Id: <20261031-a5xx-submit-stats-v1-0-16a67ac96edd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBCF4auEWTuQxBqqV5Eu0nSiIxglk0qg5
 O6NuvzgvX8DocwkcFEbZPqw8Ct1mIOCcPfpRshLN1htndFHg/5UK8o6P7mgFF8EYzB6dONwttZ
 D/70zRa6/5nX6u+8fFMo3BK3tgJl58XUAAAA=
X-Change-ID: 20261031-a5xx-submit-stats-fc108684922a
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793500370; l=1367;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=FIfxXWiFD0YIv3SO2+3QXWoICX9owaYVS7SChP2aNT4=;
 b=IIm+EseArzjRGMLKA2hIomTqh4OxcVfh7EFqozoGolMBZe01X5fdBfXHooOUDOdtFcAOEsJDw
 D7wHTb4letUBmAaPSU7xu/4cNPG5gMF0kzn6I0z31hgwSk9nrX2qmiP
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPU time and cycles msm records for each submission, reported in
the msm_gpu_submit_retired trace event and added to fdinfo, read zero
on A5xx, whose submit path never copies the counters they come from.
The second patch adds those copies, as a6xx has them.

The first fixes what is recorded for a submit killed by hangcheck, on
every generation that has these counters: its end stamps may never
have been written, and about three years of GPU time is then added to
the process's fdinfo. With the second patch alone, A5xx would start
reporting that.

Tested on a Motorola Moto X4 (SDM630, A508), whose board file is not
in mainline yet, on sdm660-mainline's 7.2 kernel with commit
b303e1d52811 ("drm/msm: Recover HW before retire hung submit"), which
the first patch needs. Its code is shared with a6xx and later, not
tested there.

---
Fabricio Akio (2):
      drm/msm: Report no GPU time for a submit killed by hangcheck
      drm/msm/a5xx: Record per-submission GPU time and cycles

 drivers/gpu/drm/msm/adreno/a5xx_gpu.c | 22 ++++++++++++++++++++++
 drivers/gpu/drm/msm/msm_gpu.c         | 15 ++++++++++++++-
 2 files changed, 36 insertions(+), 1 deletion(-)
---
base-commit: a39c950806213f6861d00f90729acaaa21f2d95a
change-id: 20261031-a5xx-submit-stats-fc108684922a

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

