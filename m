From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Fri, 20 Nov 2026 21:22:37 +0530
Subject: [PATCH v2 1/2] dt-bindings: display/msm/gmu: Document Adreno 829
 GMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-molokai-a829-v2-1-c63c268d5ab3@yahoo.com>
References: <20261120-molokai-a829-v2-0-c63c268d5ab3@yahoo.com>
In-Reply-To: <20261120-molokai-a829-v2-0-c63c268d5ab3@yahoo.com>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795189956; l=903;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=fWx8B8EVRHaa/QjmI//OdB1UeHRHRMAyCbcwF2whEXA=;
 b=1bTZmN2D/D8obhEtn5O3YNXSXlkGtc/C3KCjY52B9UBG1bJTa+MOLZDfgjP8rg2gPPzhmKicK
 E6DdQPy65G3BFBGBkSGOqDBeh6lcYwIRR9D1Habl8tBcXgepoa0ieEf
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GMU of the Adreno 829 found on the Qualcomm Molokai (SM8845) SoC uses
the same registers and clocks as the Adreno 840 one.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 Documentation/devicetree/bindings/display/msm/gmu.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/display/msm/gmu.yaml b/Documentation/devicetree/bindings/display/msm/gmu.yaml
index 07f0e547b43c..2599eca08a36 100644
--- a/Documentation/devicetree/bindings/display/msm/gmu.yaml
+++ b/Documentation/devicetree/bindings/display/msm/gmu.yaml
@@ -337,7 +337,9 @@ allOf:
       properties:
         compatible:
           contains:
-            const: qcom,adreno-gmu-840.1
+            enum:
+              - qcom,adreno-gmu-829.0
+              - qcom,adreno-gmu-840.1
     then:
       properties:
         reg:

-- 
2.56.1

