From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Introduce framebuffer for Oneplus 6 and 6T
Date: Sat, 06 Dec 2025 18:45:41 +0100
Message-Id: <20251206-sdm845-oneplus-fb-v1-0-19b666b27d6e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMVrNGkC/x3MwQpAQBCA4VfRnE2x7QivIgfLLFMs7URK3t3m+
 B3+/wHlKKzQZg9EvkRlDwllnsG4DGFmlCkZTGGoNEWFOm21JdwDH+up6B0SW2poJO8qC6k7Inu
 5/2fXv+8HiEz182MAAAA=
X-Change-ID: 20251206-sdm845-oneplus-fb-5e4595c5fb64
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sam Day <me@samcday.com>, 
 David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=762; i=david@ixit.cz;
 h=from:subject:message-id; bh=CtDjl9Ll7B/5YngbUltP1j/RQ93MbGy3LfdGklrzF4M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNGvI+l27B99XrsDAgoE3ZXy+foHpa+RsziqyT
 fR2yS/4SuqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTRryAAKCRBgAj/E00kg
 chMsD/9fiQz06dEn+/w6tyigbkoqUEFZjH3HXlNh4KllDeRf5wRzyeQk7xDysVmNVu6NTolWB6M
 PeVAgCDL+8OdfZCC71K6ih85EAyUQgcEs3j6vobYT5FHHMJPGgOWL3KlspJRBtx6nu3oa8VCw3N
 TlgLpwEPTwNs/Cx2zFYKZbBeh++XjpNdzP9BnyqZe+CX7w3jz4mB44XocwXPGI04Mm/c+otGcP9
 b0uPtLbVgiuJLpwrknRKUj6PipRfKsXBCOtCxSef+5rnwdR7WU8diB4Q+WohME4+ETb6qgyeVMA
 7WSetWoitL3c6ASiBy/APkXpoPbvCJ5INpCxPueC3WcrPs4n6RIJyoS6cGQP1q4/MqNIUUB1hQO
 3JuwtlcI9p8RauU5VIkTnMfElu+/HMQZWVj1NTqp1/oDdy2fvEXV+7o75DxBvFrE0189u0Hb0Es
 UeOfWrvvUAGDXey88f58CvQIVSrLYneQ4sP+uTL1nzSbWvypj41frme1+AKaOw5olAAuv3/AMlR
 CMHg7AFYp1YSg2pDd/ZMbQrTx2xeH6y+U2rxcSjxAH+RFYx5IWZ6VYfYnXhO7iqPfoor10csVwj
 gzLDHorwK4uZy1jsNNA1Ge852HkGteKvqMzVNmjNfmuu0aahlRiekEbo3YyaUcLHyVSMCQzIR9A
 IEi9IIg0/CtSHMg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unfinished bits of framebuffer support was laying long enough in
downstream forks, let's push it.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (1):
      arm64: qcom: sdm845-oneplus-enchilada: Sort nodes alphabetically

Sam Day (1):
      arm64: dts: qcom: sdm845-oneplus: Add framebuffer

 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi   | 18 ++++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts |  8 ++++++--
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts    |  4 ++++
 3 files changed, 28 insertions(+), 2 deletions(-)
---
base-commit: a5841f413dd0173a0648408827719fab7838a1c2
change-id: 20251206-sdm845-oneplus-fb-5e4595c5fb64

Best regards,
-- 
David Heidelberg <david@ixit.cz>

