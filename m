From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v5 0/3] Input: support for STM FTS5
Date: Mon, 10 Aug 2026 17:21:39 +0200
Message-Id: <20260810-stmfts5-v5-0-0c737d929976@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MSw6CMBSF4a2Qjq1pb1/gyH0YB/QlHQiGEoIS9
 m7BxKLD097vn1F0fXARnYoZ9W4MMXRtGuJQINPU7c3hYNNGQEASoBzH4e6HKLDmilHqtVUMULp
 +9M6HaStdrmk3IQ5d/9zCI11fPw1G6LcxUkwwgOGi1FVtZHkOUxiO5oXWwgg7RUVWkJQi2pTMu
 UpU9FexrDhhWbGkhK2VLI23QP4U36sqK56U5N7J9KWsFlkty/IGitIdUz4BAAA=
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
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3611; i=david@ixit.cz;
 h=from:subject:message-id; bh=iYMWF/J+YvooBs3s5WRm/I45yY/IbX0QrmbEUfp4nac=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqeeyNn0JVtxp4V6UivWU56+kfUvLGZXX0LdUJ1
 oUZrgfKzC6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCannsjQAKCRBgAj/E00kg
 chjjEACs+WX8zHWsSWUJn3XSYLpe9ViXMTQJS1UzHOStQU3Z0HVKy2f1Wcljt435qihhY24NC09
 +adKMr3R953WfqiauCqs3o4QERWo6JagGXgwkcSRcpuuslDMW5BlUahygEdyO0D+leerbtVI/io
 SCgN9jyG1Dvo39KXzNj9aec6ODAy4ZnPdsHL171/4DN5vk42cesLSVmvfLCAhogDpROp4J/w6QJ
 c8ljH56wjIQAROPjikliyjRxXjJui4QkoREu6fbc9WORQWgaKjwoaQnUmgPUV1saYfIB7OudD3I
 eEtjJMNko9Mzch+ofnA2UslIx9HwVIpAzVnm0MaNyOKfRudxlUpu0KO/oihC/3j5x+uCIDzCoP6
 igtfc2jMYN3yZgOAkOxRJslp/HVHBddS1Iqot2jO2G0XfnACaf5XyBzEVzcYUFJM+RPCtx7yVth
 irx/tYyI9sScIOTK41ZK33WfdEPab4RWS3ucw2F7pB9TdSEqPXiiGfU47PDBLyHbn3SoNO3y57X
 8c0ZljpconkjFWvFUG2M1PHU+2kLQf8ySvN71EdVmP7WabjUslF4wSf1LJop2JKwVfihh72norh
 3Cz5BGbkBOnj6Sw4apz9D3t2cG7DBynS7Sq7OATGmS0IrPPHpZDgHzwF8R9b1piZAq6fWlla5k6
 k5eI9vs3dBHk1ug==
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
Changes in v5:
- 3.3V is analog, 1.8V is digital supply. Fix that.
- Name the error variables "err" (Dmitry)
- Use scoped_guard() for ->running, and only set it once the scan
  mode has actually been enabled. (Dmitry)
- Use i2c_master_send() instead of open-coding a single-message
  i2c_transfer(). (Dmitry)
- Drivers may report coordinates outside the declared min/max, so
  remove the clamping. (Dmitry)
- BTN_TOUCH and INPUT_PROP_DIRECT are already set up by
  input_mt_init_slots(..., INPUT_MT_DIRECT). (Dmitry)
- Let the input core track contacts: drop the touch_id/stylus_id
  bitmaps and the hand-rolled BTN_TOUCH reporting, and sync the frame
  once per interrupt with input_mt_sync_frame() instead of calling
  input_sync() per contact event. The controller pushes contacts one
  by one into the event FIFO and only resends the ones that changed,
  so INPUT_MT_DROP_UNUSED is wrong here and is dropped as well. (Dmitry)
- Restore the FTS4 interrupts accidentally dropped by introduction of
  FTS5.
- mode-switch-gpios isn't required with stmfts5. Some designs, such as
  Xiaomi Mi 8, has no such GPIO connected and is limited to AP mode.
- Nit: updated example to use interrupts-extended.
- Nit: (maximum x/y coordinate reported + 1), corrected example.
- Link to v4: https://lore.kernel.org/r/20260409-stmfts5-v4-0-64fe62027db5@ixit.cz

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
David Heidelberg (2):
      dt-bindings: input: touchscreen: st,stmfts: Introduce STM FTS5
      Input: stmfts - support FTS5

Petr Hodina (1):
      arm64: dts: qcom: sdm845-google: Add STM FTS touchscreen support

 .../bindings/input/touchscreen/st,stmfts.yaml      |  29 +-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  19 +-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |   2 +-
 drivers/input/touchscreen/stmfts.c                 | 430 +++++++++++++++++++--
 4 files changed, 436 insertions(+), 44 deletions(-)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
--  
David Heidelberg <david@ixit.cz>

