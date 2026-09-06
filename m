From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v6 0/3] Input: support for STM FTS5
Date: Sun, 06 Sep 2026 18:33:48 +0200
Message-Id: <20260906-stmfts5-v6-0-50fbf6af8718@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MS04DMRBF0a1EHmNUVf4zYh+IQftHPCCJ2q1WI
 Oq9UwkSThg+u869iF7mVrp42V3EXNbW2/HAwz7tRNpPh48iW+YtCMgCoZZ9+axLNzJqpxBrzE6
 R4OvTXGo730pv77z3rS/H+esWXvH6+ttQgH+NFSVIoqSNj2FK1r+2c1ue07e4Fla6U2iGIlYOY
 vKqlGACPio1lAY1lGJl8uSsTzUT/FP6XoWhNCura7H85XI0j8oM5RGGMqwgOeVyoBCcHWrbth+
 0aeeLdAEAAA==
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4267; i=david@ixit.cz;
 h=from:subject:message-id; bh=bIh50GL4CnZVQ1HBuupaDiQHAlo2u2EqwjHC3A4x8NM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnZXwEHVJKj3banu+VBWeGlK24lYDc54u8jRjl
 iH/p03zocWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCap2V8AAKCRBgAj/E00kg
 ckL7EACK+MJcE0uhqzVbLiPCH9nA91/x2b4Ava5iRzIU6awN/a34BdV18D/3la3WcJnqC37iWnG
 VJHU/ChWjAscQkYs9WUjEf06wDSCGCldTBy+mcv1T6pv7aeR2db5aSWnWgNE37vVRQ/UERCFbmo
 onTGM8nz9UMPQNaIo0UG3axIB5owkeNtspSl9UShbYvmER4tTM398RnyuBQd9NHHKm7zjNzDU6r
 a9t48vSyfWnKmo6+EKv19EKXxJ0YR7oE1fUk0/NoML8WVSh2yc5do7yaRcR7RHX2cqU/fjiPgVh
 E0qtrGYZ8tk+njoVXwS8Gl8K/fiXe3QyW3Lckh5cXENKa3adwAPwxdhbJvAq2bpn7zhJ8sFtANl
 u6Mpor3+HfSPPE2eCiDVYqu3yCZa1LdNBeZJsvqw1IXpbIgsD/pxxU3vviHP1nBaCeTcEbDUChH
 VXe0y0odVbbe55Xox3uu9lrffMN6kHLkVVKGs9yjALaxOh0iU5cKq4QfVK/Ha2kceyximuSdUVw
 O6WnnGmkjZ8aC2pUzuIeE69mmXDRwXRis25x+n0BxeBghkMgBA4olKCinLcM91+zhcpSYdtkXVn
 NOYSD51mifc1m9LbuvKJ+fQc4iszhuXuQoNWvAZZx13bRlhLsTB4Ax+5eBI+oo9O84yYY4QXXdk
 MgbLRxJ8gUdi9dA==
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

---
David Heidelberg (2):
      dt-bindings: input: touchscreen: st,stmfts: Introduce STM FTS5
      Input: stmfts - support FTS5

Petr Hodina (1):
      arm64: dts: qcom: sdm845-google: Add STM FTS touchscreen support

 .../bindings/input/touchscreen/st,stmfts.yaml      |  29 +-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  19 +-
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |   2 +-
 drivers/input/touchscreen/stmfts.c                 | 407 ++++++++++++++++++---
 4 files changed, 406 insertions(+), 51 deletions(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260214-stmfts5-b47311fbd732

Best regards,
--  
David Heidelberg <david@ixit.cz>

