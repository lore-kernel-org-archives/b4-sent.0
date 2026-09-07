From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v7 0/4] Input: support for STM FTS5
Date: Mon, 07 Sep 2026 12:50:18 +0200
Message-Id: <20260907-stmfts5-v7-0-4a53381cd038@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13Qy07DMBAF0F+pvMZo/JqxWfEfqIv4Rb2greIoK
 q3y7zhFwgnLO55zNfKD1TSWVNnb4cHGNJdaLucW6OXAwmk4fyZeYstMgkSQQvM6feWpGu41KSG
 yj6Qka9vXMeVyezZ9HFs+lTpdxu9n8SzW6W+HAvHXMQsOXMqgjfVuCGjfy61Mr+HO1oZZbpQwX
 cmmCHywKiVnnNgr1ZUG1ZVqysSB0IYcJfxTeqtcV7op1Dlhe6LozV6ZrqyArkxTEEhRdNI5wr3
 CrhxgV7heCNlnHLIlsfmNZVl+AKQTNa2qAQAA
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
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5373; i=david@ixit.cz;
 h=from:subject:message-id; bh=328YlRURSnwE9509rxzvq5+6g3dgVhnXmI0R4w081vU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnpbw7CTfQD20iAy7QP722kBWmhdyptr4YGf1q
 TlII4vMoZCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCap6W8AAKCRBgAj/E00kg
 cpD+EACUOpDB08iVN6wok2XLH/J1kMoL3X0OxfHA5gMFmX/l54JuGUdTJf0wyL6m/bijWlnZ5uq
 E2MC5UM24BbSzYtlNPXobJSkhpLOwEw9ZlVaDWJ45FEMICupqK6KEFgZZZC98m03gYPy9wiWj0N
 WDihKrS16KroCHUO1kHfHHBxnh5hYIMfPfaD0QFEokVH4ZWDupR4JF1VT4eOX25+ltRur/pkYom
 TtMxfclsNuBdlO6gOnk3SGglEO4kUg+jinkHgZyWRRm88U9n3u4AnQ+VVgrfNLf2Y2OwZhXVC5P
 W9XgD/3jO9kJaC64qtkeZv99W+OoS4Km5bS81IpPV8+hG15gH7N6A723BnPVHjNiglmwbBS3+VO
 HbvdI7ARXTm7SR5sM1zk8A4YUpz1Vqp7yFtCUyvoBN6jB7V5/Tgf36j1kx/FOp8ZD55F8qD6KHJ
 acyqM59Ccx8hi1Re0BwZ4yc9yFqzwHo4uHlIuGYCbYBgjgyZMnQslZR0/bVWlGxVUW6oSYEfAfF
 WI/rXRmuVL5CvsQUwOPSmmqJUc3oQiPclVSiT2lSyZpLQ97nrnOFAkxf0sLyiH5Rucu7SlV70Fg
 eoYxclNX3Fo0PRuRjQpV4+KQ5hi9+awS9ncc8HlrdlOfk6ihvwhESXeaz8hh1x4wMgJ2W0XsdmD
 HOCI0f4V7/JoSlQ==
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
David Heidelberg (3):
      Input: stmfts - wait for controller ready after reset
      dt-bindings: input: touchscreen: st,stmfts: Introduce STM FTS5
      Input: stmfts - support FTS5

Petr Hodina (1):
      arm64: dts: qcom: sdm845-google: Add STM FTS touchscreen support

 .../bindings/input/touchscreen/st,stmfts.yaml      |  29 +-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  19 +-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |   2 +-
 drivers/input/touchscreen/stmfts.c                 | 438 ++++++++++++++++++---
 4 files changed, 429 insertions(+), 59 deletions(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
--  
David Heidelberg <david@ixit.cz>

