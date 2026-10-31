From: Ishu Brar <patches@brar.si>
Date: Sat, 31 Oct 2026 13:23:38 +0530
Subject: [PATCH 2/5] dt-bindings: display/msm: dpu: Document SM7250
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-dpu-sm7250-v1-2-159f403ec405@brar.si>
References: <20261031-dpu-sm7250-v1-0-159f403ec405@brar.si>
In-Reply-To: <20261031-dpu-sm7250-v1-0-159f403ec405@brar.si>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793433218; l=1025;
 i=patches@brar.si; h=from:subject:message-id;
 bh=jNRne+T5TGHiLh6XT+g5uA/MzROZisRFWcFsqwWvKA0=;
 b=5E0KLCkUdM8e1q0zy2UQ/f4e+Hc9+wMor03N7R/MTw5Q9SZSdw4ZzoiuCm3RodBRENCisgfJS
 Xg+F+rESVFTCGUKHJpxElU8h4Sz+JaARysiUo1qVhM7YEZ8NYbWOb2B
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM7250 DPU node has the same register regions (mdp, vbif) and the
same four clocks (iface, bus, core, vsync) as the SM8150 and SM8250
ones, so add its compatible to the existing qcom,sm8150-dpu.yaml
instead of creating a new schema. qcom,sm7150-dpu.yaml is not a fit, it
describes six clocks including rot and lut.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 Documentation/devicetree/bindings/display/msm/qcom,sm8150-dpu.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/display/msm/qcom,sm8150-dpu.yaml b/Documentation/devicetree/bindings/display/msm/qcom,sm8150-dpu.yaml
index a88d22f30a60..d779d3008c1f 100644
--- a/Documentation/devicetree/bindings/display/msm/qcom,sm8150-dpu.yaml
+++ b/Documentation/devicetree/bindings/display/msm/qcom,sm8150-dpu.yaml
@@ -14,6 +14,7 @@ $ref: /schemas/display/msm/dpu-common.yaml#
 properties:
   compatible:
     enum:
+      - qcom,sm7250-dpu
       - qcom,sm8150-dpu
       - qcom,sm8250-dpu
 

-- 
2.56.0

