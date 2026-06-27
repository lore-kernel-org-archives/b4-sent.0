From: David Heidelberg <david@ixit.cz>
Date: Sat, 27 Jun 2026 19:50:15 +0200
Subject: [PATCH v2 1/2] dt-bindings: arm: qcom,ids: Add SoC ID for
 Snapdragon SDM 850
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260627-sda850-v2-1-44bf46ade42e@ixit.cz>
References: <20260627-sda850-v2-0-44bf46ade42e@ixit.cz>
In-Reply-To: <20260627-sda850-v2-0-44bf46ade42e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=959; i=david@ixit.cz;
 h=from:subject:message-id; bh=Bm10A2IWOMTZFdIbMpHs4iv+z7ELDsn9bEjGsrnPnhg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqQA1ZEz5uBgL6oDUKQ7CKCqw/mHk4X73KlID2T
 11ntBZO48qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakANWQAKCRBgAj/E00kg
 cskcD/9BkgBphaSEH16x9zs+K/eXAf+cGtnNMb0LtrQdHt8j2Q+1ilCvKnRRyBNSKA2WRpm6PNL
 UXLzwIMiSLnlOsISfXT2knEdXk35Ot+SKCN4oQpy8VK0lJtdQ4r8FfKNFW19efDv7eqdJqONkDJ
 U2IQF33e9W1NDOmRoLzfMp8VVOCbQkEx9yswpgiu9T32IfuUD5ZviWpj/ARBrioQ7F4VM5RT3Uc
 LUZPnlvRWUzPoJURtb02vKIXF6U30jjrNPGNDGFOM614Wa1AAoqQXCWfbu7HYHPHB8oaq3lc90r
 kDqdLFmGQLp2rQU3dcet4oOF88pvd3WIvhv0iSpPxelXZ7rczsduV/k3XhKx1o75l7gBsvW20h5
 u7edyTSU34CSu1IHv6gu5sKNo96g/uoj/3mADsX7Lm2OOD2B6rEJHIW8fJuWD+gU+4A8sa2yZqO
 K8Enb4QfcGf2DnmgYXQ6bu/kWzSfrIJgCxsFfcGt8b4mHYPjIYaqoTbEJyUadBfIGSiMiJZewft
 Pr+OpZ9Uh1xtuQ3JVYCpfjXAQxAav0VjqUIuYg7F3QSFC+bzE0GaQD53hJyZFjQe6i0HWjW6sPb
 MN3i1L+G+AnT6yUdAsmiPNiNJ24+B02UGWjYmb2pXz3RFiAH54qILs8QMxsnZVKlCNKUHWTQi76
 TpYR4GzQZK+sJkg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SoC ID for Qualcomm Snapdragon SDM850.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 include/dt-bindings/arm/qcom,ids.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/dt-bindings/arm/qcom,ids.h b/include/dt-bindings/arm/qcom,ids.h
index 1af73c0ad41cd..2cf433f61d5e7 100644
--- a/include/dt-bindings/arm/qcom,ids.h
+++ b/include/dt-bindings/arm/qcom,ids.h
@@ -179,16 +179,17 @@
 #define QCOM_ID_SDM450			338
 #define QCOM_ID_SM8150			339
 #define QCOM_ID_SDA845			341
 #define QCOM_ID_IPQ8072			342
 #define QCOM_ID_IPQ8076			343
 #define QCOM_ID_IPQ8078			344
 #define QCOM_ID_SDM636			345
 #define QCOM_ID_SDA636			346
+#define QCOM_ID_SDM850			348
 #define QCOM_ID_SDM632			349
 #define QCOM_ID_SDA632			350
 #define QCOM_ID_SDA450			351
 #define QCOM_ID_SDM439			353
 #define QCOM_ID_SDM429			354
 #define QCOM_ID_SM8250			356
 #define QCOM_ID_SA8155			362
 #define QCOM_ID_SDA439			363

-- 
2.53.0

