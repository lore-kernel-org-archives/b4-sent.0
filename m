From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC 0/2] sdm845: describe the Wi-Fi hardware properly
Date: Fri, 27 Mar 2026 14:07:07 +0100
Message-Id: <20260327-wcn3990-pwrctl-sdm845-v1-0-3f5c34e3fdd0@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPuAxmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYyMz3fLkPGNLSwPdgvKi5JIc3eKUXAsTU90Uo6Q042TzJEuLlBQloN6
 CotS0zAqwudFKQW7OSrG1tQCPiFHebAAAAA==
X-Change-ID: 20260326-wcn3990-pwrctl-sdm845-d2bf3c7b98dd
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Paul Sajna <sajattack@postmarketos.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=799; i=david@ixit.cz;
 h=from:subject:message-id; bh=vsEQH3xLzfJZOCoZLqMwel3/ksZeTratODrtl3DPNtU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxoD8IpkxMGoq6cpKR5s5N/44xF52VjlkQ+zjr
 +IB66I0/OeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacaA/AAKCRBgAj/E00kg
 cmHTD/9nbrFgmtlPh+iWpXlZB8fvvhSOelws+rARRGqUxVo6wvyyqJSL1hKB9BmWlzsi2pklQ03
 f9XSjt6hha2FgxKuotBQ5csZPS3gXkSfBdqyewwBVNuB5ed0C6hvdFn9Jso16LQWb2fJDN9PnMm
 FBPtVaUvWK4lQMaRpMSaVp84VYJ4b2BKDo8waYGzzLzjLe5bPkWbtBlrOw7DQF2fYJql5Ke1EkD
 xUjFNChniPQHJePcWhqlWSnVqnR/bC+1+Hhzx93Q+RoKM6YxdPzVeOP9wl3sKbYay+t8qs62tha
 XtZMVRhHX3FXsVaHqTzcO4qM2Yg5V4boGkSC5OlXeNEB5W7M8Fc7rOoC6+CbN0heBqqrFkiifk8
 phFFmxzFTGT2Y+d0N6l8AtFOV6yZezQbNJU4jMYVCYz6qIum1bIS7MxovDMoZrfFi3Oyg8aVLLU
 yxxq2FvY7XVZOrhXDHlRLEONPsK1UjccaykGfkAM4rMzRFK5EA1JipJ2cKKaY/GD3h97kPPDI3S
 HHOGLO93shS9TtFNPMey+8ziZLJYldKeAfJxYIlwB4flRz5ZOOgLk+DDtyb6lMsh2Br7nvO3ee/
 ASDifVOxbb4SENmqsA2tQCxaHsBzw141KHbsDRawU7MVHC2FSrgD/tdMD/Pmq3Jj5HOupH8D+6M
 Q5EKQW+PQUov/Rg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Question here is, if the most of the wcn3990-pmu shouldn't rather go to
sdm845.dtsi? At least the regulators seems to be same.

When agreed, I'll sent include all other sdm845 phones in the patchset.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      arm64: dts: qcom: sdm845-google: Describe Wi-Fi/BT properly
      arm64: dts: qcom: sdm845-oneplus: Describe Wi-Fi/BT properly

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 42 +++++++++++---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 65 +++++++++++++++++++---
 2 files changed, 91 insertions(+), 16 deletions(-)
---
base-commit: e77a5a5cfe43b4c25bd44a3818e487033287517f
change-id: 20260326-wcn3990-pwrctl-sdm845-d2bf3c7b98dd

Best regards,
-- 
David Heidelberg <david@ixit.cz>

