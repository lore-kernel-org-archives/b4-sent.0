From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Add framebuffer on Xiaomi Poco F1 and disable the MDSS
 on tianma panel variant
Date: Wed, 11 Mar 2026 19:44:28 +0100
Message-Id: <20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAy4sWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQwNz3aTUosqcnMzSXN20JN0U41QL86RkI4OkVAMloJaCotS0zAqwcdG
 xtbUA/dmuaV4AAAA=
X-Change-ID: 20260107-beryllium-fb-d3e87bc20be0
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=828; i=david@ixit.cz;
 h=from:subject:message-id; bh=8+88lGJnGD+j6NV1gC42NaIw5lR/TlH0YzC8mNmFOl8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpsbgOMYYduiFV4B7jZjUm5CNR6u5lX/4g4QjfR
 TMWRIBeuB2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabG4DgAKCRBgAj/E00kg
 cpAdD/0YQ3QBWu+MFBZKBkilMx/g8Zg9tUGg4rfcYJN62QamaydFWZUXD4apwX6a2DGZ1ror9/N
 l10tC1PjDTt8c6L0MWwrTuc3OMQaUA/EtkFyy7n4ho+ehJ4C4OkRKLxRfu1RSu6hFgXvHirp8B1
 4a2G6gPwyvGkdytzZBPKzCuOAYJnCCbQUfZK3qBYEwM+X4arhlePM0JUHebFK7DQACqanVA9jdl
 7ReFnam0bbabxMcThcBXxNS/TWenURnR8xJ8vonUFVBNhhsfr9Ex9LLfwfWafZ0lDYey9dP3uqo
 Lj3zzNeg4HX5Ksc9MfnNMw6vFmQslKKluAUSbaerxUgHvlllF/Pq+7TQQ2BH2hSgKJ0hHToj/wf
 rBne2lB1c8BAxvGr5HPxj0JWgXHuwPhAkKhlvD66SOptJXyDBFVUZMYjgigkwkMN+DSEo1QNcHh
 m05Xuhdt58wpFKJM8NquRtPoYMnsAqZYg4+8pNWUivagsbY16wIOlKn9oVlYT8mKYDO2nvkq6zZ
 DTM1o8TqFOTsMERicW74UkWHdtQZ8bgSPYLQEkK73LC7Uss03B+yzS0PaGgnO0uRVWnNDY9ZVc1
 QUs0r2sM/Fg7ck1q7srj3jOfzebAVkDAAeVGtjQjADHZGVCvuP1AbHYG+4xZQBGJv2kZ3CKNQCA
 cEMr/+QwQ9KDcBQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable framebuffer for early console output.

Due to broken panel driver on tianma and no visual output it's better
to disable the MDSS so the framebuffer stays on. 

In case second patch gets rejected, please apply the first one standalone

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (2):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Introduce framebuffer
      arm64: dts: qcom: sdm845-xiaomi-beryllium-tianma: Disable MDSS

 .../boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi    | 16 ++++++++++++++++
 .../boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts     | 10 ++++++++++
 2 files changed, 26 insertions(+)
---
base-commit: f90aadf1c67c8b4969d1e5e6d4fd7227adb6e4d7
change-id: 20260107-beryllium-fb-d3e87bc20be0

Best regards,
-- 
David Heidelberg <david@ixit.cz>

