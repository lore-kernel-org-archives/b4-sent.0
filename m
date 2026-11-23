From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/3] OnePlus 6 and 6T support for front and one of the back
 cameras
Date: Mon, 23 Nov 2026 02:21:45 +0100
Message-Id: <20261123-op6-upstream-cameras-v1-0-234fb3b7bb18@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnBdo6yiyVxk7xJppBmpJVATx3
 Ve343f4/wOMVdjgUR2gvInJPBX4WwVpoKlnlK4YggvR+xBwzhHXbIsyjZhoZCXDmpro6juxaxK
 UNCu/Zf9tn6+/bW0/nJbrBef5Be5tqgV4AAAA
X-Change-ID: 20261122-op6-upstream-cameras-3a86034ae08c
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, 
 Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=715; i=david@ixit.cz;
 h=from:subject:message-id; bh=EUtTl3VsRAoTueX0+mnNdBvhuxCaj+3BQqgT522isR8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrA5Uvjw6EttivUxmePLaYf24+QLuWCs4qGQZ4K
 jw4LD5lZ7OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawOVLwAKCRBgAj/E00kg
 crxQD/4u6z3rKZgQfw2Wk+FpWSFV0pEGcL28Jfp2ZToUj0lbHhaA1VT4eFVBNIAk/Yzkd+uQx40
 tFMYOC2/83W4hNcirE7z1Aqs1R3Ttkl8AICUIhayI+0Rr1JSjuxAHZf9aWOO/o/Tai8ATKep2YH
 JjO9ZxWi7v3uZxAF/5theQu56JplPd643joWRwK5t8lgDTofOW6IcW5v5LPhlmQwgKqmaoISF46
 NbQaBQy54OEe/h8wGS1XAjQlWEdmvT4oYaaVs1WB7plBARg6GNBcNTbQye3rJCKdynYh1qBPzGO
 uq2gqKEAyXXKDM4IZFc1Uuh8JALkg1MaVWYvwcSzgpXHqVWNEiM7v5DJIC87Azk+EqtDfYU+pMa
 zsvcBosMMXQbwZLEzWRwc1oyrzhzoPbI/7WoMW7F25oQxSdh+kFu00hDNbTy73OyHpi0mXk11Lr
 Z7CuSE56m3dEZb4KhvtU4TuFOg33rF7n7PQ6jjHTrTa7Ky1V2ltilvFcbxzVX/2kdJgXLsLv4cx
 qABTxRTWP3JUZc57SRGGawOAAy2aR6YOLlP7nkHdPgIWmvtjsPe155T+nniW7Q1ZIKvXWLnInDu
 sk9jSXvap9V2GFCncO0kGuaKPYQtEV05+UrEVqPYVfdoBI7Nk4nWQ8dyOJAreYz2CJz9Jfmnh47
 +ewapr9Ydat4KLQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both of these cameras are supported by generic MIPI CCS driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (3):
      media: dt-bindings: mipi-ccs: Allow 90 and 270 deg rotation
      media: dt-bindings: mipi-ccs: Support IMX371 and IMX376K
      arm64: dts: qcom: sdm845-oneplus: Enable front and back camera

 .../devicetree/bindings/media/i2c/mipi-ccs.yaml    |  11 +-
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 243 ++++++++++++++++++++-
 2 files changed, 249 insertions(+), 5 deletions(-)
---
base-commit: 3f78d2d48efe77c257284e9c7703612a1d1ec2e6
change-id: 20261122-op6-upstream-cameras-3a86034ae08c

Best regards,
--  
David Heidelberg <david@ixit.cz>

