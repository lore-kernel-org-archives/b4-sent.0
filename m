From: Ishu Brar <patches@brar.si>
Subject: [PATCH 0/5] drm/msm/dpu: Add SM7250 display support
Date: Sat, 31 Oct 2026 13:23:36 +0530
Message-Id: <20261031-dpu-sm7250-v1-0-159f403ec405@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSQqAMAxA0atI1hbaOoFXERfRRo3gQKMiiHe36
 vIt/r9AyDMJlNEFng4WXuYAE0fQDjj3pNgFg9U2N9omyq27kqmwmVaoDWLmyDhMIQSrp47Pb1b
 Vv2VvRmq39wD3/QD5iH8ObgAAAA==
X-Change-ID: 20261023-dpu-sm7250-a01aa5de1da4
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krishna Manikandan <quic_mkrishn@quicinc.com>, Ishu Brar <patches@brar.si>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793433218; l=1402;
 i=patches@brar.si; h=from:subject:message-id;
 bh=lImhQg5lCjPx2m766k1nCRU11627wdRxlLCIAzvpVMA=;
 b=lQgVyB1vnmMuNuCV0/N5dynx72wt6JHJiLqq2+O7zd9XMMBeTd6sEzgP+h6ktTOI91k+9E8R5
 BvsyNfCt69xDF3skqFW8/RWvZuSEcXgt94xWVqfbAEcFTUdeEW3Pptm
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add display support for the SM7250 (Snapdragon 765/765G/768G), which
has a DPU 6.1. The DPU node matches the SM8150/SM8250 schema, so only
its compatible is added there; the MDSS gets its own binding, modeled
on the SM8250 one.

The MDSS driver needs the SM7250 UBWC entry from:
https://lore.kernel.org/all/20261027-ubwc-sm7250-v1-1-e766b1e264cf@brar.si/

Tested on a OnePlus Nord (a 7.3 based tree).

---
Ishu Brar (5):
      dt-bindings: display/msm: dsi-controller-main: Add SM7250
      dt-bindings: display/msm: dpu: Document SM7250
      dt-bindings: display/msm: Add SM7250 MDSS
      drm/msm/dpu: Add SM7250 support
      drm/msm: mdss: Add SM7250 support

 .../bindings/display/msm/dsi-controller-main.yaml  |   2 +
 .../bindings/display/msm/qcom,sm7250-mdss.yaml     | 351 +++++++++++++++++++++
 .../bindings/display/msm/qcom,sm8150-dpu.yaml      |   1 +
 .../gpu/drm/msm/disp/dpu1/catalog/dpu_6_1_sm7250.h | 311 ++++++++++++++++++
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.c     |   1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h     |   1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c            |   1 +
 drivers/gpu/drm/msm/msm_mdss.c                     |   1 +
 8 files changed, 669 insertions(+)
---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261023-dpu-sm7250-a01aa5de1da4

Best regards,
--  
Ishu Brar <patches@brar.si>

