From: David Heidelberg <david@ixit.cz>
Date: Tue, 07 Apr 2026 08:43:54 +0200
Subject: [PATCH v5 1/3] dt-bindings: wireless: ath10k: Add quirk to skip
 host cap QMI requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-skip-host-cam-qmi-req-v5-1-dfa8a05c6538@ixit.cz>
References: <20260407-skip-host-cam-qmi-req-v5-0-dfa8a05c6538@ixit.cz>
In-Reply-To: <20260407-skip-host-cam-qmi-req-v5-0-dfa8a05c6538@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Vasanthakumar Thiagarajan <vasanthakumar.thiagarajan@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1497; i=david@ixit.cz;
 h=from:subject:message-id; bh=1luENuPnPeyXu5VeZAHgXAvwbtbY0TaE2mQPU89+fLM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1KeuDBmYFxoMD+Feuzgv5t7+yMPiKxBLPkhjo
 BOciIS9EeuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadSnrgAKCRBgAj/E00kg
 crJnD/92pJEinb9W7xjyVfljYpzqTfNMPOo4pEvNwTgGCTm7Lq34y5I0iufUO/SBAILukgfj4bb
 j2XQd7yv00r8KhhrdbzXhg43Fj7/rKuSJMCENJBB4kDfverQ/wB7towGcS5lqeXym3D7XU6PS+S
 3uNXhdVG1ok4ZWliDtim/MWXWO3fiGzC+OIijYJX8dGYbmItcmRtfNbVJdQKyoAwAOGQM8jy1n0
 f0ip71zbZYbCIP8BqBXYf+iB0xSlIvY+9phdX2vQW8uwKpsqtIhsFyAde7pMBWYNV7GDPF3l6bL
 4Ge9GhFGiOKQowqoJKTmVZG9Pbq3HTyCebiJd/8WIAjUYEEAZO+4YRZjPXgbxshXDYsSGWDBP58
 Dtik0XR6CTDTMRDlRYIB9n3TGDmWXEJWBFWbIzNhoX5WV9aRVaSkop9wGziturc8MZQLXTotpyQ
 MIktNTjigI8p/KIv2wNQZPUJPKCcToYK3JWXgQ4FWSTSwmuzlCBLxyYlM/oVffbdkyGbrKwkZzE
 de7bXE/i06hqwv/4d0jptGDlzTUK4p8UPNPRVB1b4/qS3vPFUBbpAdwc1D4yne0DTMioKc5yXF2
 9EqOwclRLK6fo2OAo4H/kT9eiZCv69kjKoVShGU9PuEu8Fk+GJLHPFZyGfd6IFLPoFVClrYfwbP
 9SluheIL9DVDPJg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

Some firmware versions do not support the host-capability QMI request.
Since this request occurs before firmware and board files are loaded,
the quirk cannot be expressed in the firmware itself and must be described
in the device tree.

Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/net/wireless/qcom,ath10k.yaml         | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml b/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml
index f2440d39b7ebc..c21d66c7cd558 100644
--- a/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml
@@ -171,6 +171,12 @@ properties:
       Quirk specifying that the firmware expects the 8bit version
       of the host capability QMI request
 
+  qcom,snoc-host-cap-skip-quirk:
+    type: boolean
+    description:
+      Quirk specifying that the firmware wants to skip the host
+      capability QMI request
+
   qcom,xo-cal-data:
     $ref: /schemas/types.yaml#/definitions/uint32
     description:
@@ -292,6 +298,11 @@ allOf:
       required:
         - interrupts
 
+  - not:
+      required:
+        - qcom,snoc-host-cap-8bit-quirk
+        - qcom,snoc-host-cap-skip-quirk
+
 examples:
   # SNoC
   - |

-- 
2.53.0

