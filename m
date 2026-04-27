From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] ath10k: Enable a devicetree quirk to skip host cap QMI
 requests
Date: Mon, 27 Apr 2026 08:44:40 +0200
Message-Id: <20260427-b4-skip-host-cam-qmi-req-fixup-v1-0-4398e94bde70@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANgF72kC/x2NwQqDQAwFf0Vy7gMNKthfkR50zWoo6rpREcR/7
 9LjMDBzk0lUMXpnN0U51XRdEhSvjNzULaNAh8TEOdd5yYy+hH01YFpth+tmbLMiygav1xHQCw+
 Vd7WvXEMpEqIk8R+0n+f5AUsdjQ1wAAAA
X-Change-ID: 20260422-b4-skip-host-cam-qmi-req-fixup-be2d5fc6f5c9
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Amit Pundir <amit.pundir@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Konrad Dybcio <konradybcio@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=877; i=david@ixit.cz;
 h=from:subject:message-id; bh=DSG6jbCu4oeRHDhh05kVDO3v1KJAR3GMyHcDQRH5gvw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp7wXZB2djAp33JI6nOSwBeBA6nayuUvr0YUotS
 dYAt6ilGyuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCae8F2QAKCRBgAj/E00kg
 cjSUEACYqu4zoysbcjYYSgzNDznlJQxcA5/D6k3YKGrAAQ7qqWSkU987WruefjVuIMMBXAhrHJ9
 HyHUbsWo8BWUUDRD+oGWykaH2PozeNKWrKRIKmT18VOidbolJUizz1Wy6+3PQY4sXcCUQr4+Jzm
 1zWhjFhl2pCNJWCDUk9uWe9tvEmBJyK07ympJCJZgezOXdbEVKtKv1FNOfKXtzQOw+GWjwq5/yZ
 gqaXUw/nPHefcq3XCw7C80qiMTEw2VJpi9zJ8aQ7emU1dP+7YLWFu4uhrwTizmP1BK+U4dnpG/s
 lpok6X0P/IP8blfXw2htcRQZFO6WDW73n2+9gs90nG1AwuBr2rWUG0pbBEsyY/rknBWOpFwNQ9S
 OrQpJF3Z5cubSsEUWX+ksD5Gok6hf74wlPq3yw1ONSIdxeDudBh4YBespv9dtSluAXt0VVtU6rE
 QzcR30tMj9b3WPnqoOsE79oClxuLR0i7JJMKihswfYKOuS7K4wtOD4D6JAk0FOwsgn5Y9WWMgXu
 WJKN1OFTNgQlWJFuFegdMCMJ02lyegSRklJKnHyCjn+8tmZrF8DS+uOvgm+qRuchaz14PPNtceO
 JOVfa5titOPR3zIhfNmHMaOR23cnOtSCIrDvaLxx45ihj3r3RZz17MotvX2Jon3mMczkuu6nOS2
 7D+cVZwoAGSYmqQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This quirk is used so far used on:
- LG G7 ThinQ
- LG V35 ThinQ
- Xiaomi Poco F1

The quirk was accepted into the kernel, but the device-tree part was omitted.
We need apply the fix to the device-trees, so the affected devices will use
the quirk and WiFi works.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Amit Pundir (1):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable ath10k host-cap skip quirk

Paul Sajna (1):
      arm64: dts: qcom: sdm845-lg: Enable qcom,snoc-host-cap-skip-quirk

 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi               | 2 ++
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 1 +
 2 files changed, 3 insertions(+)
---
base-commit: 254f49634ee16a731174d2ae34bc50bd5f45e731
change-id: 20260422-b4-skip-host-cam-qmi-req-fixup-be2d5fc6f5c9

Best regards,
-- 
David Heidelberg <david@ixit.cz>

