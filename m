From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 00/11] Input: support for STM FTS5
Date: Thu, 09 Apr 2026 00:15:43 +0200
Message-Id: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI/T1mkC/1XMTQ7CIBCG4asY1mJggNK68h7GRfmzLGwNEFJte
 ndpTWxdfpN53glFG7yN6HyYULDZRz/0ZfDjAemu7e8We1M2AgIVAcpxTA+XosCKS0apU0YyQOX
 7Gazz41q63srufExDeK3hTJfrt8EI/TUyxQQDaC5q1bS6qi9+9Omk32gpZNgpKjYFRUmidM2sb
 URD/xXbFCdsU6woYVpZ1doZIDs1z/MHAYjuawgBAAA=
X-Change-ID: 20260214-stmfts5-b47311fbd732
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2723; i=david@ixit.cz;
 h=from:subject:message-id; bh=KEpr4zJFKU/KOf0lTdcERja2Oc3rB1xw26v3jW80j10=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tORj8Tz8uq8GTC1dEqjNeUZc9jKY8+OcF1HE
 gWaiIeQF1OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkQAKCRBgAj/E00kg
 csZwEACUcK4e6blbpGOxU1nC7RkaviK2zL+5IB8QV5bmROBL3UOw8GzYJr9xKE5FDAjx08xsloV
 IeFAmw9cRqlVnSXFIp7wP6FsB/Z4n2mb/5aZxmh4loULzdzneXGEYm5Hu60nyMhpMc66WOZ+UkR
 sGfsfVaoQrJsL4SNeJItTYoayRwhYKcirluxBbsNxZpZ6/JHa61bbY9j3yLkxca+IHS+Vj+q+fi
 weAxo+naTXefK/v8EbRgrQXWv/TIFaZ8Mqi3tBqNEQVOdZ9rP6x/CsV3ySR2DudA7Uj6KaJwtV1
 S2/2pIYv3YpWBcknNuBThDLS8ZgIBpumUY1roXksBlFvAVGVxXiBTQ51M0CqFWpffSQYreeGpAo
 IG4M9uScArO91G6pWqIJRJkCM1MPZ9MpJbiNBBrr1+IH2e8a6B3d/ccJYKwk4D0noOXYqA2Ob2r
 qaqve6GK2KwWTHEWab3PBQg3R52v6o5gaLmX1B3QIS2au02qr9bwSP/KVJjC3CGJlESfsfm4KtL
 KnzMD6AwQK2rTdXiMQp2lL/oIa8HaJOZ59GELbUhgTYHK0zsjSsScjkwFLjAHUjx42QxHRxOJpo
 QCERx6t6yPC6eR1lLR3FewECmpwTWwxTYQBUtLlTrE6m3Q9L5uDJKgsbGEJ1aPgWnD8PNhdYmHB
 AXhpNMpFLZBpAxg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Used on various phones. Minimal viable driver.

Includes device-tree enabling touchscreen on Pixel 3.

What is missing:
 - switching between AP and SLPI mode (to be able to wake up phone by touch)
 - firmware loading
 - anything above basic touch

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v4:
- Wrap everything below enabling the supplies into stmfts_configure()
  to avoid bunch of gotos to power off on error (Dmitry T.)
- Finished chip specific ops and removed is_fts5. (Dmitry T.)
- Link to v3: https://lore.kernel.org/r/20260403-stmfts5-v3-0-5da768cfd201@ixit.cz

Changes in v3:
- s/touchscreen_pins/touchscreen_irq_n. (Konrad)
- Use interrupts-extended. (Konrad)
- Fixed rebase conflict against 8665ceb926ec ("Input: stmfts - use guard notation when acquiring mutex")
- Rename switch-gpios to mode-switch-gpios.
- Do not define properties in if:then: branches. (Krzysztof)
- Link to v2: https://lore.kernel.org/r/20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz

Changes in v2:
- Fix typo in the binding s/switch-gpio/switch-gpios/.
- Deduplacate allOf. (Rob yamllint)
- Add missing S-off-by. (Dmitry B.)
- Dropped irq-gpios as it's not needed. (Konrad)
- Correct x and y touchscreen area size. (Konrad)
- Correct reset introduction commit description. (Krzysztof)
- Partially implemented chip specific ops. (Dmitry T.)
- Separeted license naming cleanup into separate commit (Dmitry T.)
- Link to v1: https://lore.kernel.org/r/20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz

---
David Heidelberg (7):
      Input: stmfts - Fix the MODULE_LICENSE() string
      Input: stmfts - Use dev struct directly
      Input: stmfts - Switch to devm_regulator_bulk_get_const
      Input: stmfts - abstract reading information from the firmware
      Input: stmfts - disable regulators when power on fails
      dt-bindings: input: touchscreen: st,stmfts: Introduce reset GPIO
      dt-bindings: input: touchscreen: st,stmfts: Introduce STM FTS5

Petr Hodina (4):
      Input: stmfts - use client to make future code cleaner
      Input: stmfts - add optional reset GPIO support
      Input: stmfts - support FTS5
      arm64: dts: qcom: sdm845-google: Add STM FTS touchscreen support

 .../bindings/input/touchscreen/st,stmfts.yaml      |  19 +-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  19 +-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |   2 +-
 drivers/input/touchscreen/stmfts.c                 | 601 +++++++++++++++++++--
 4 files changed, 580 insertions(+), 61 deletions(-)
---
base-commit: db7efce4ae23ad5e42f5f55428f529ff62b86fab
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
-- 
David Heidelberg <david@ixit.cz>

