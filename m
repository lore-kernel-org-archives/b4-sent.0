From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/2] Improve older camss supply descriptions
Date: Tue, 16 Dec 2025 13:24:49 +0100
Message-Id: <20251216-docs-camss-fixes-v3-0-c238b6810771@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJFPQWkC/33Nuw7CMAwF0F+pMhMUuzWvif9ADFEe1AMtiquoU
 PXfSbvAgBjvtc71pCQkDqJO1aRSyCzcdyXUm0q51na3oNmXrNAgAQJq3zvRzt5FdOQxiDbREhL
 u4UigCnuksB6KulxLblmGPj3XDxmW9s9YBg2anAEgQzHS8cwjD1v3UstUxm9e/+BYuD3Yxjeew
 O3ch8/z/AbQIwE67QAAAA==
X-Change-ID: 20251212-docs-camss-fixes-0fa525271951
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vikram Sharma <quic_vikramsa@quicinc.com>, 
 Kapatrala Syed <akapatra@quicinc.com>, 
 Hariram Purushothaman <hariramp@quicinc.com>, 
 Richard Acayan <mailingradian@gmail.com>, Bryan O'Donoghue <bod@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Depeng Shao <quic_depengs@quicinc.com>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1412; i=david@ixit.cz;
 h=from:subject:message-id; bh=ioJNJf6E3iqakh89UOBaktoghK6qUOL79hbpE/KqCRI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQU+TMUrOS2fCW3hRVB4ctdcSTSInlnWDipJxy
 arm18T5D3+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUFPkwAKCRBgAj/E00kg
 cky3D/0fHzJJ6PiAsMbr8iHCykuCUboqMdggD8hCafYdDg3D4dDCYClmeqPNtWlbKDVZwnKGtok
 0++tHUtd4Z+RyUrtvbjAhzDEvF7OV0WXMaohedlw7XDUU8LOSrrXLErERNPdpVSoPfVho/LJ0zp
 c0iDJ/P7PMQ6RyV6ctFeLrBvCZc9USaSqsdcRgrxJJ8hPbSP1B83VTCkFfQ6zBgtXc0c0gqJEFa
 8G50D/iAL0Ut5MW8mcrH1MYDscmRblwVNwED/BSV7Pkwx6I9Az30up5geEssGP16pD9DfnUrW9R
 r9vsxuMbYHJ2QXv0wHEKmvIVmrjjqop2ShRzdo8fOORg+4fL13QvJZgxnh+nDaMfBMonYlJJ0sx
 5XMHbox4r3sgddBPb4NNR0X0b/Xrzh7yaYstXa+ap8aHfPHaNkcb+vuz9CLEvpecnwCYYD8kXW6
 5vpkQxbaEOIJnv8+LyengGEnnm+WxCr2d6Of55fU5Yfc737k2Fd8bUNyzeCyK7Q8q+0sEvS6T4n
 YBtXS4zmph7I4iskyLGncjLJ5SOXbGuCQwWyRqMscxCxr6MwzXVc60cN+hekVEOLWhDN6nVqHsa
 QmPM7yaK4kiigAYdiuWVymAx0pbI+CcC5xRgV3uwPjeX7FVloHkieRk6FNCU1hY41kcfBygUnzM
 l8GGUskxXUixapQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Add commit improving vdda-phy-supply description to match more recent
  bindings.
- Double-checked and specified it's 1.2 V vdda-pll-supply. (Vladimir)
- Link to v2: https://lore.kernel.org/r/20251213-docs-camss-fixes-v2-1-a8a4d4d51c6c@ixit.cz

Changes in v2:
- Applied suggestion to clarify the description. (Krzysztof)
- Link to v1: https://lore.kernel.org/r/20251212-docs-camss-fixes-v1-1-5c011505ff59@ixit.cz

---
David Heidelberg (2):
      media: dt-bindings: Correct camss VDDA PLL supply description
      media: dt-bindings: Update camss VDDA PHY supply description

 Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml  | 4 ++--
 Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml   | 4 ++--
 Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml | 4 ++--
 Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml   | 4 ++--
 Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml   | 4 ++--
 Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml   | 4 ++--
 Documentation/devicetree/bindings/media/qcom,sm8550-camss.yaml   | 2 +-
 7 files changed, 13 insertions(+), 13 deletions(-)
---
base-commit: 563c8dd425b59e44470e28519107b1efc99f4c7b
change-id: 20251212-docs-camss-fixes-0fa525271951

Best regards,
-- 
David Heidelberg <david@ixit.cz>

