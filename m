From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Nov 2025 15:26:24 +0100
Subject: [PATCH v2 1/3] dt-bindings: wireless: ath10k: Introduce quirk to
 skip host cap QMI requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-skip-host-cam-qmi-req-v2-1-0daf485a987a@ixit.cz>
References: <20251110-skip-host-cam-qmi-req-v2-0-0daf485a987a@ixit.cz>
In-Reply-To: <20251110-skip-host-cam-qmi-req-v2-0-0daf485a987a@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath10k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Amit Pundir <amit.pundir@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1103; i=david@ixit.cz;
 h=from:subject:message-id; bh=eDK/4tDlTIOnXZQxvVBLLpr0TJmEnv0tcxiF4I9sY4E=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEfYSfLM7kuds/BZ5AbbeeHF6crfp64r5Gw046
 zUV8PnwV9KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRH2EgAKCRBgAj/E00kg
 cjTfD/9EshPGakS5iAT+22AYaa3mUXdiTUXN8PKvCgc3+hZCwvKI4Zijj0/VN2vhn3ZJhmaU4Tq
 7mzRv9Z5VAP2p4+LImDkyXb5H6jGqU/0SlyqwAIA9kNqrFn03CG3sdC8pnPj0KHs+u1S+dFJdOS
 KB4hffPdH98RYUtp7vhDwAQtiFZQt2CoSGrscADWqlAGFQ3bgfOWbha4iQD/PjACPbn1MheIVLn
 CkMZG7Ve9nD9oDJbqFVwTlxQqwne/D7yk9skToP6XafkpGCIdyqCK0hMjpimhZb944MXGkJOKyN
 L7XHGtDEz0LTntEwRe7pgJjMERFmJ2YOBgKPlVcqWBp1edtUlbgF6JdKZPWQ1vUGRZOaxOtU86j
 s6DJGJZInmX273a4Lnw6LCF1TBjgwm4fvOUctg+0m0ZcRomT9tNP8w3IWafmiI+LQ7p1m7uUKlM
 VEXMHv9XpFMTnZB7LhHHdhgZhrj0XfGNowKeczunS+sIlnArvXSuVUbTDx+hL6GjHTl75I7RQaK
 5oPRJZaR2zYi/z9fqfQNemJnqrdcf/gWanc11bdy79WG6OTdBwjcZpJ1sVMg5Zq7vGy3T5uOHz4
 PdG3E8eH94Su9ICXmvy9wK5Fl5jE/QHgOUYQ7u4XXm7ZZ0OXAPt0qe79FC2DwoAtk1SJlj7ro2v
 d6E+GbkHdDCDydw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

Introducing this quirk to skip host capability QMI request for the firmware
versions which do not support this feature.

Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml b/Documentation/devicetree/bindings/net/wireless/qcom,ath10k.yaml
index f2440d39b7ebc..5120b3589ab57 100644
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

-- 
2.51.0

