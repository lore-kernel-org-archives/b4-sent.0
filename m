From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] soc: qcom: socinfo: Add CQ8725S SoC ID
Date: Fri, 05 Jun 2026 16:49:06 -0500
Message-Id: <20260605-cq8725s-soc-id-v1-0-bb1ef93de649@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7TlCjsr4SHdS22ouWCxGIf086D
 sNMBsZEyDA3GRI+xBRDBdU24E8bDhS0VQYt9SAH2Qt/m1H3LDj6qsSmzSSddd2uDNToSrjT+w+
 XtZQPF92zc2AAAAA=
X-Change-ID: 20260605-cq8725s-soc-id-d2890bab3f18
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780696163; l=480;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=p+Ek4rtYC2lXzkvKxdIQpewdKguYwiuJOF/vElMhShY=;
 b=4IQGpS/+vWwVGbSvaKXxjk2BzAENzxZcpV3aSiI2I/4sS9LgotzmWo3Z1mGbS0/lDM+oX3OXI
 8o3TSMXH3l5C/rQbrDk3PpARetVSzqW+es6YlSdptswWvMRkKezXhh5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ID for the CQ8725S which is a variant of SM8750.

---
Teguh Sobirin (2):
      dt-bindings: arm: qcom,ids: Add SoC ID for CQ8725S
      soc: qcom: socinfo: Add CQ8725S SoC ID

 drivers/soc/qcom/socinfo.c         | 1 +
 include/dt-bindings/arm/qcom,ids.h | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: 6e845bcb78c95af935094040bd4edc3c2b6dd784
change-id: 20260605-cq8725s-soc-id-d2890bab3f18

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

