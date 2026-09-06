From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC 0/4] Add modemsmem for Google phones
Date: Sun, 06 Sep 2026 02:41:11 +0200
Message-Id: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSwMz3dz8lNTc4tzUXF3LRMOUZEMDc4M08yQloPqCotS0zAqwWdFKQW7
 OSrEQweLSpKzU5BKQKUq1tQAKYQHUcgAAAA==
X-Change-ID: 20260906-modemsmem-9a1dc1070f7b
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Acayan <mailingradian@gmail.com>, Petr Vorel <petr.vorel@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1141; i=david@ixit.cz;
 h=from:subject:message-id; bh=eRvLe1XRVJ8TJbygbWAv61WmLhsSguAjpbdT8YXOflU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnLavI/xFthM9qoq5L8tR9KOe+uWdiqXgpmubn
 oboO6k4ciSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapy2rwAKCRBgAj/E00kg
 cu7KD/429ltHh5MLUGPQPw+neYzhaT/vOibNrQQ7hV4l36Fw1kRqtychUvN+zuVCr3voZDVvGz3
 iG3acvJPbPjrgo6/aqancRWolPgoqXPvmaR5IRXLB86jwvyora50tQXS6YLVXKLk8Hyc9AhmSOo
 tA7XP6U31FFv9CbroE/pMA84XihZTojdrzqcoh80t5KdvLi5KD4et8yMnPSm+iXMG61Bj7H0Iek
 ZwyhbQ5J5I4/w+2U3nj3b2q/PPtVjnO05jjm2EtPE6wlnyLJLZwTJp7wpJW6Nnph1YWGTVVjaiv
 fPt99lX+ncJ8Y3JoSzQi4bQ/0uyQl2Nm9xB0toH/7GCxVAt5WkBVSv79vD8ewoK8+/GBbcHFPLG
 OeB0PARBkOyeGstFGXk/FZbKnvak34f++YOCvCK9G3MunYKzl5iw7a/pe1bOoSNqoZXi8z227NH
 5gfe/O630JicZ0Myd56ws2FV64jiOcw6IDnB2AsmN+bpyx+ejzn0/5x88AaagJ/t1JZXMwZd8aR
 a7HOqvmtVD/p4I0bC6iCf//vF87extyqoclzC0dYGeD1YD7s7O4A8gHNgIQ4B7tcPyWS2cfRTII
 XoXoco7gX0wtRYEmslGGBGvrew4PlMKrsQkDBqzMskQzFvkaikIeVTzwJjPnqqoci6FeTO0zmrL
 Mh90CNDthUoA03w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Q:
Where do these types of drivers go? This driver is probably providing
info to vendor code in the modem firmware, so it might not belong in
drivers/soc/qcom/.

Maybe it should go in another directory, like drivers/misc or firmware?

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      dt-bindings: soc: google: Add modemsmem
      arm64: dts: qcom: sdm845-google: Add modemsmem

Richard Acayan (2):
      soc: qcom: Add modemsmem for Google phones
      arm64: dts: qcom: sdm670-google: Add modemsmem

 .../bindings/soc/google/google,modemsmem.yaml      | 39 +++++++++
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi |  5 ++
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |  5 ++
 drivers/soc/qcom/Kconfig                           | 14 ++++
 drivers/soc/qcom/Makefile                          |  1 +
 drivers/soc/qcom/modemsmem.c                       | 98 ++++++++++++++++++++++
 6 files changed, 162 insertions(+)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260906-modemsmem-9a1dc1070f7b

Best regards,
--  
David Heidelberg <david@ixit.cz>

