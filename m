From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] arm64: dts: qcom: sdm845-oneplus: Be more explicit
 touchsreen description
Date: Wed, 19 Aug 2026 15:56:38 +0200
Message-Id: <20260819-oneplus-ts-quirk-v1-0-0cdbcea195a2@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB1IUqvYq4gLq6OOlqiZpBTEu
 5vq8i3+30HIMQm8kh0cfVl4sRE6TaAdGzsQchcNRplcFQ+Ni6X1EwS94BbYzfjsytwolTXalBC
 z1VHPv2tZ1bclvCdq/f8Dx3ECSHyzrXQAAAA=
X-Change-ID: 20260731-oneplus-ts-quirk-5d962004a129
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcus Ramberg <marcus@means.no>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=732; i=david@ixit.cz;
 h=from:subject:message-id; bh=e5ElovP1SCECxirXtW4TEymqPOWYTGsG0NVtgBZtogk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqhbYX9lDvelYDg8+CpZ5TqqR4YrB8qzclbP0md
 ewKd+kYaJaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaoW2FwAKCRBgAj/E00kg
 cozWD/9dgC/dYF1CYKHGfPjxnua0hdVkkBErY0glo23VYp2Yuq4YLetwojX3o0Fcw5HKLqXZoYn
 snzCa7UYA6E2FqfzWonHW5uRu1Vw2lWTFrgxqOpt6164scc/23E6K9/7Y0+jzqYppfypz7P2g7B
 iiEHogcw2+fqYPq1qrmN5tSVmM7tJRuEy61idxLN5ki9YfD7K1FuJNblMX6lDu2B3D8Nc7e/7z1
 vmGH+O2RLDDxlVZq67/brfG8bIklHW1c0CcELZoy+LqYMYjTM2AU8PN+wFbk7sNYXOYfaJA9zJf
 1kOlvMCkWpf7r8AwdnCkow8FIsWLNliEIoyPwXkqGuiU5em8ozYTFr1oUCfs5jGsMkJ8H8FZB5a
 CJMnlctnyrh4qYfm/YhlWw1cFBOJbmJ6PprW3EQoXt1olP4MVPpyIQ4vpNbsBPDYkk69cwcNQ2j
 IgDOgj4IG35ZC6Hhka30kAaPOombBguBIzXBzfCD2Amv+YC+sRGLciOjpqqXoJHwqSIwYqo8g6j
 0l87RLYY27qc16uyihm21p9GHzJCbK6zJT5xIpswSTr02TBlkS0/Mu1LBTfg/aNtLUoonegDjhm
 o+zsPf/RN6/1BNJgFx5XUV4AfH/mQXiT4fy7NdOW4lkBjDG0R/2eXtKh/JvzBcDyY7LBdu6v/F5
 LlMd8slR4cwg32A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Useful for aftermarket touchscreens, which don't fully comply with the
standards.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      arm64: dts: qcom: sdm845-oneplus: Move touchscreen y-axis to the right place
      arm64: dts: qcom: sdm845-oneplus: Define touchscreen in the detail

 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi   | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 5 +++++
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts    | 1 +
 3 files changed, 7 insertions(+), 1 deletion(-)
---
base-commit: 5453bc3279e9f8578ac3e534d476240e40c879e1
change-id: 20260731-oneplus-ts-quirk-5d962004a129

Best regards,
--  
David Heidelberg <david@ixit.cz>

