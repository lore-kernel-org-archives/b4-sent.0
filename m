From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v8 0/5] Input: support for STM FTS5
Date: Fri, 25 Sep 2026 23:22:18 +0200
Message-Id: <20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13QTU7DMBAF4KtUXhM047E9NivugVjEf9QLWhRHU
 aHK3XGKhNMu33i+p5GvoqappCpeDlcxpaXUcj61YJ8OIhzH00caSmxZSJAGJKqhzp95rnrwigk
 x+8gkRdv+mlIul1vT23vLx1Ln8/R9K15wm/51EOB/x4IDDFIGpa13YzD2tVzK/Bx+xNawyJ1C3
 ZVsisEHSyk57fBeUVcKqCtqSseRjQ05SnhQaq9cV6opo3Iy7Ymj1/dKd2URutJNQWDi6KRzbO6
 V6cqB6cpsF0L22YzZMj78Bu8Vd8VNqVETWQwRaKfWdf0FhRF3QeABAAA=
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
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5706; i=david@ixit.cz;
 h=from:subject:message-id; bh=NYGGX08Rh22ux8AkT9s+UILhXOkXRQN1DhjSewJHGj4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtuYMZRK6dVaJ8gJpvVKh2HmICVoHNTi2sCpAt
 jefMomniYaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarbmDAAKCRBgAj/E00kg
 chd4D/0W2SNOEooROfqD6meWgaQDNnkiYb0LaZSwBE9pwsOD20aRosXFOkB23BHUkmsBXRJhvg3
 ROuuOp9OuOR1RVpbzPuyLp132K9cs7KAeWOw7IODS6qPmJMfYC8HE1EaJfxgYaVmDZEG5W+vDup
 EuiULs74RDDlQmcX5qgbMEydMGwzuLzXGrWnrfUM+PkTp8+lThqxf8WxKRgyLsYn6/aL2nuRpn5
 ZiqJFJ4qoYKDIn3yH7pwvfNzb30shKGSFxI/UpMB1X61X93gLWjas9FgyvIgfzvFcdX6XR270yy
 pHfLjpuH5OQoOckxaKddivReiX/m80PwDyznLl9AugrZMpjtVzg1MT1u9NgAsMD9kxJ0HcrM6Bu
 tiz2zvZncgWyQKCdMn1WLLjrEgcvJp5mgAoqEbDJJFC07W5+Qk5oF4Wsx2VV8Yzvd9qzVWM4WIG
 zIHWfZW+xvSemfAJ0htIXGwtfTXvlkWcGBtp0KRvOtEekejIl0Z/YDl+yI5Ctefu+M+s8yDlIBd
 CGbR0wkWJRR1A65YPrlTfHdWxaOUJtuVMuXSbB5If4XZwTNAk0dFdj2Tg8ZKqVqInhHidSbKj1g
 IbhcK6KZFNi3IMPxiPzDeG/LhRzkG2bqjyKT80CuCjz+X39NDP+Hx0PMucz5JZKiK09jA01X2hu
 JAY7lx0s38bWwTA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Used on various phones. Minimal viable driver.

Includes device-tree enabling touchscreen on Pixel 3.
Also, tested on Xiaomi Mi 8 (device-tree is not yet inside the mainline).

What is missing:
 - switching between AP and SLPI mode (to be able to wake up phone by touch)
 - firmware loading
 - anything above basic touch

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v8:
- Split DT binding example changes into own commit (Krzysztof, Dmitry)
- Refectored the stmfts_power_on fix. (Dmitry)
- Added ABS_MT_TOOL_TYPE. (Dmitry, Sashiko)
- Link to v7: https://patch.msgid.link/20260907-stmfts5-v7-0-4a53381cd038@ixit.cz

Changes in v7:
- Added 'Input: stmfts - wait for controller ready after reset',
  the waiting is done for both FTS4 and FTS5, similarly to the
  downstream driver. Should improve reliability everywhere.
- Link to v6: https://patch.msgid.link/20260906-stmfts5-v6-0-50fbf6af8718@ixit.cz

Changes in v6:
- Enable only the multi-touch scan on FTS5 sense-on (0xff was wrong,
  only 0x01 is needed. This broke Xiaomi Mi 8 toucschreen).
- Fixed Y-coordinate comments. (Dmitry)
- Corrected event[0] parsing. (Dmitry)
- Dropped checking < 0 on unsigned area. (Dmitry)
- Dropped unnecessary i2c writes after reset. Verified against
  downstream driver. (Dmitry, Sashiko)
- Added pieces for supporting non-OF integration. (Sashiko)
- Shared input open/close into one impl. (Dmitry).
- Link to v5: https://patch.msgid.link/20260810-stmfts5-v5-0-0c737d929976@ixit.cz

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

To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>
To: Alexandre Torgue <alexandre.torgue@foss.st.com>
To: Petr Hodina <petr.hodina@protonmail.com>
To: David Heidelberg <david@ixit.cz>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Henrik Rydberg <rydberg@bitmath.org>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org
Cc: linux-stm32@st-md-mailman.stormreply.com
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-kernel@vger.kernel.org
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-msm@vger.kernel.org

---
David Heidelberg (4):
      Input: stmfts - wait for controller ready after reset
      dt-bindings: input: touchscreen: st,stmfts: Improve example
      dt-bindings: input: touchscreen: st,stmfts: Introduce STM FTS5
      Input: stmfts - support FTS5

Petr Hodina (1):
      arm64: dts: qcom: sdm845-google: Add STM FTS touchscreen support

 .../bindings/input/touchscreen/st,stmfts.yaml      |  29 +-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  19 +-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |   2 +-
 drivers/input/touchscreen/stmfts.c                 | 462 ++++++++++++++++++---
 4 files changed, 443 insertions(+), 69 deletions(-)
---
base-commit: 944a035ecca915ae947905dcfb03f2b9dc6d032c
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
--  
David Heidelberg <david@ixit.cz>

