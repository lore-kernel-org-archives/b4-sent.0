From: Ishu Brar <patches@brar.si>
Subject: [PATCH v3 0/6] drm/msm/dpu: Add SM7250 display support
Date: Fri, 13 Nov 2026 11:26:33 +0530
Message-Id: <20261113-dpu-sm7250-v3-0-30bdec59d204@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNwQ6CMBAFf4X0bE23pQKe/A/jYaGr1EQgLTQaw
 r/bogl6nOTNvJl5cpY8O2YzcxSst30XQe0y1rTY3YhbE5lJIQ8gpOJmmLh/FFILjgIQtSEwmLM
 oDI6u9rnGzpcP+6m+UzOmQlq01o+9e61vAdLuG1bwGw7ABQddXXOhqMmFPtUO3d5blrJBbiKA/
 BNlFEuqpEaFJRZmE5dleQMZR5gk7QAAAA==
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
 Krishna Manikandan <quic_mkrishn@quicinc.com>, Ishu Brar <patches@brar.si>, 
 Kuogee Hsieh <quic_khsieh@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794549395; l=3390;
 i=patches@brar.si; h=from:subject:message-id;
 bh=BSHS/Aji18Q8W6naE/wxA1UmN6lL7923+dY0DTqriYI=;
 b=dBiyCxc5HjyMaKY/TMBKI4ZKwvSDwtSLniowPAaiCVvwtW1AhyMjqTJY86FTWJ2StsLNRgRjE
 PRvaD9Ltr3KD44HcOlDV9BkciWRzEAlm1fEoFZgqalAJsx6hLy+nAzP
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add display support for the SM7250 (Snapdragon 765/765G/768G), which
has a DPU 6.1. The DPU node matches the SM8150/SM8250 schema, so only
its compatible is added there; the MDSS gets its own binding, modeled
on the SM8250 one.

The MDSS driver needs the SM7250 UBWC entry, already applied to the
Qualcomm tree:
https://lore.kernel.org/all/20261027-ubwc-sm7250-v1-1-e766b1e264cf@brar.si/

Tested on a OnePlus Nord (a 7.3 based tree).

---
Changes in v3:
- MDSS binding example: connect the DSI output endpoints to a panel
  and add data-lanes (Krzysztof)
- Collect review tags
- Link to v2: https://patch.msgid.link/20261112-dpu-sm7250-v2-0-8e925a3a8a7d@brar.si

Changes in v2:
- Use dpu_vig_sblk_qseed3_3_0 for the VIG SSPPs, as the other DPU 6.x
  catalogs do (Dmitry)
- Drop max_hdeci_exp and max_vdeci_exp from the caps, as the other DPU 6.x
  catalogs do (reported by sashiko-bot)
- New patch: add the SM7250 DP compatible to dp-controller.yaml, as the
  SoC has a single DisplayPort controller (Krzysztof, Konrad)
- MDSS binding: add the displayport-controller child, fix the
  description, drop blank lines (Krzysztof)
- Collect review tags
- v1 was sent three times by mistake, sorry for the noise; the reviews
  are on the last copy, linked below
- Link to v1: https://patch.msgid.link/20261031-dpu-sm7250-v1-0-159f403ec405@brar.si

To: Rob Clark <robin.clark@oss.qualcomm.com>
To: Dmitry Baryshkov <lumag@kernel.org>
To: Abhinav Kumar <abhinav.kumar@linux.dev>
To: Jessica Zhang <jesszhan0024@gmail.com>
To: Sean Paul <sean@poorly.run>
To: Marijn Suijten <marijn.suijten@somainline.org>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>
To: Maxime Ripard <mripard@kernel.org>
To: Thomas Zimmermann <tzimmermann@suse.de>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Krishna Manikandan <quic_mkrishn@quicinc.com>
To: Kuogee Hsieh <quic_khsieh@quicinc.com>
To: Ishu Brar <patches@brar.si>
Cc: linux-arm-msm@vger.kernel.org
Cc: dri-devel@lists.freedesktop.org
Cc: freedreno@lists.freedesktop.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Ishu Brar (6):
      dt-bindings: display/msm: dsi-controller-main: Add SM7250
      dt-bindings: display/msm: dpu: Document SM7250
      dt-bindings: display/msm: dp-controller: Add SM7250
      dt-bindings: display/msm: Add SM7250 MDSS
      drm/msm/dpu: Add SM7250 support
      drm/msm: mdss: Add SM7250 support

 .../bindings/display/msm/dp-controller.yaml        |   1 +
 .../bindings/display/msm/dsi-controller-main.yaml  |   2 +
 .../bindings/display/msm/qcom,sm7250-mdss.yaml     | 361 +++++++++++++++++++++
 .../bindings/display/msm/qcom,sm8150-dpu.yaml      |   1 +
 .../gpu/drm/msm/disp/dpu1/catalog/dpu_6_1_sm7250.h | 309 ++++++++++++++++++
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.c     |   1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h     |   1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c            |   1 +
 drivers/gpu/drm/msm/msm_mdss.c                     |   1 +
 9 files changed, 678 insertions(+)
---
base-commit: 198acaed3b84c91030a039ac5ab833432ec166ea
change-id: 20261023-dpu-sm7250-a01aa5de1da4

Best regards,
--  
Ishu Brar <patches@brar.si>

