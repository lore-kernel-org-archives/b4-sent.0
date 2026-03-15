From: David Heidelberg <david@ixit.cz>
Subject: [PATCH WIP v2 00/11] Input: support for STM FTS5
Date: Sun, 15 Mar 2026 19:52:36 +0100
Message-Id: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPT/tmkC/z3Muw7CIBQG4FdpziwGDvSik6ubm4PpUCi1Z7A1Q
 Ei14d0lDI7/Jd8O3jqyHs7VDs5G8rQuOeChAjMPy9MyGnMG5NhwFIr58JqCr5lWrRRi0mMrEfL
 77exEW5EecL/eoM/lTD6s7lP0KMpUIMnFH4qCcYZoVN3p02Ca7kIbhaP5Qp9S+gE5EevqoQAAA
 A==
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
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2295; i=david@ixit.cz;
 h=from:subject:message-id; bh=o4sD9z+DOoFeCBJ7SrXYHJ3jpMK6dfrsLjScjTrYeek=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptv/5jsfTlXQXhPhxCDEmBDtICy4aS4OGijRGR
 eKk3Yv8mWuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+QAKCRBgAj/E00kg
 cqgbD/9XPEettkTdq7HsP8ymzT+1/jEZLNLoqIu8npKK7gPL2EhVadWpF6N8smn+5TjulTrCvJB
 YMf6zNPtF1qnBuR1eucX94IPn8RXaen5eNvKXcQ8vBZSx+PHMdJeUa8UqEY2+Rb2Zo5epFcKWno
 dFPzqn874nsJOb/2QC43eFaiiSL6g06RLbNJStWnEGRH9UVXpbw4N8IhjUpjwbu/aw0aMNXLUUV
 yhL6s5N9n51+ZNWsIATdwfj2VkX8WFRKg/ontk7eKcJcsQJcVvZrrO0zBa3VvnTNmQVkc83FWvw
 1ypgCNDSQHQkhGupxGEAJTZJcHcjf+0mDya65u4kKZU/ngeQr8rrReJ0PtRe2Q1cNU21bsNVt2U
 ryZGszRXz1QG2kwQugOVEWlrqspr1roU0Z8ErhNLyvTPA3uyvlhoweq/dfSxkpfvRrduu6ApMKN
 8FoUPiQAe21HjeHjdmMmEPyYEpfHe8OluUsssqbUnp6EMbQAifvHgQYut2sXsJPXnrGvligcH2w
 K580k7rJ0Qzo5sc0yHq6RVAgK0b5yL3CgJfTb8hNjHAn/NOQKSDZf58GZfuDWB37sgmsiE94V9M
 lDBhb+9f8Teo3VH1DnpJk6Ar+rsqUoWUnAZQAJd/Vww6Q/XQwAMQz5VrrLBqvNddGlqHru8lbcF
 iG3eqYq0SsgjcQg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Used on various phones. Minimal basic support.

Includes device-tree enabling touchscreen on Pixel 3.

Sending as WIP, as not all comments we're addressed, but please to apply
any patch which does look ready for inclusion.

What is missing:
 - firmware loading
 - switching between AP and SLPI mode (to wake up phone by touch)
 - anything above basic touch

Signed-off-by: David Heidelberg <david@ixit.cz>
---
TODO for v3:
- wrap everything below enabling the supplies into stmfts_configure()
  to avoid bunch of gotos to power off on error? (Dmitry T.)
- finish chip specific ops and potentinally remove is_fts5. (Dmitry T.)
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
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  20 +-
 drivers/input/touchscreen/stmfts.c                 | 593 +++++++++++++++++++--
 3 files changed, 573 insertions(+), 59 deletions(-)
---
base-commit: 9cdfeb2399709fcc7e5ec0e6a29e283d0d9a9902
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
-- 
David Heidelberg <david@ixit.cz>

