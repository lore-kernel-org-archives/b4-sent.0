From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Oct 2025 15:16:28 +0200
Subject: [PATCH 1/2] Documentation: dt-bindings: arm: qcom: Add Pixel 3 and
 3 XL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251005-pixel-3-v1-1-ab8b85f6133f@ixit.cz>
References: <20251005-pixel-3-v1-0-ab8b85f6133f@ixit.cz>
In-Reply-To: <20251005-pixel-3-v1-0-ab8b85f6133f@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=833; i=david@ixit.cz;
 h=from:subject:message-id; bh=Zry9Oute08PFuXgBMRua9g6F4WxR5JBtWztXJ669S68=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo4m+vK70PPnFXmDPGBCf5VTogIOdQHpFgOaXxM
 vqQ1sgP7w+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaOJvrwAKCRBgAj/E00kg
 cgAFEACHgszhLKeosOPDnyoFJqBM5TQyoKCtzrdGs41wPHJGFQ5c8lbr+lYrSGM3j9Bnjw6te1x
 ryIlTAcE3dYnbJPIRuvr9WzeTcQL5cwwoHDpetnwjP9R6udiAy/Do2jsQxIS7D2xO18Am2xjXea
 MQ9xN5vGvg20068e9WMjnGw3uriE2rcWeu8m0JaGCz5VTKt+zFuFTmII/OFOQlisbnHTvz0rs9N
 woEk4nrQsf6G6bAbsxBCFjW85z1jF0H1NEoc1UOGRt+j2+3I0HJQeYeJ7XRkgHT4tOTgYbZJq1U
 +XiJVWDSISfxgkE1IqfhunoHHMmRjUlWZH5ZQbR2i0cWfF8z3YXkIhs/o/fapbRu4t0yIOF2eQF
 0smtA24wRGWPW75zvpYrqW9dQGuDMPhnCey4tdfYiXbM7jZtzj9io1HXBj354qBWTZ4fvJ1pEFq
 5A5khvO8ZO5tUwz9rTl5Cse38aqdvg/yNWVGR3M3lx/hXmHHxeK9yuvar9xoEoGtKzc2NSV+Tae
 onSIwxAADzRUU3agWJXwL02VIkuHqNl8XMzI5rtzY7kF3gqiyVNVD/8Rzhi0zobf1roPgDFrbgC
 pmbAcbyCG41fJys8NTgBr+RUXZ24Enwt9HkVq6eL7baZ660g6mhj65Ytc0SD+UFmwePbN+qCHAv
 OOGu6gVhuF3dFkw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the bindings for the Pixel 3 and 3 XL.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ae43b35565808..2190c5b409748 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -976,9 +976,8 @@ properties:
 
       - items:
           - enum:
-              - google,cheza
-              - google,cheza-rev1
-              - google,cheza-rev2
+              - google,blueline
+              - google,crosshatch
               - lenovo,yoga-c630
               - lg,judyln
               - lg,judyp

-- 
2.51.0

