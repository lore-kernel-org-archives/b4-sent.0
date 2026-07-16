From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Subject: [PATCH v2 0/3] ASoC: Add LPASS VA CSR HeartBeat pulse clock
 support
Date: Fri, 17 Jul 2026 01:21:14 +0530
Message-Id: <20260717-master-v2-0-ae200627ad62@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADI2WWoC/2WNQQ6CMBREr0L+2pK2WhFW3sOwKPUjNUK1vzQa0
 rtbcOlmkpe8mVmA0FskaIoFPEZL1k0Z5K4AM+jphsxeM4Pk8sgrcWCjpoCeGX2qOtWLWiOHLD8
 99va9DV3aH9Pc3dGEtb0ag6Xg/Gd7imL1/kajYJwJ7FDV9V5KhWdHVL5m/TBuHMsc0KaUvp8h+
 pS1AAAA
X-Change-ID: 20260714-master-ca87b5f19ae0
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784231493; l=2757;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=ynSdBnUoyOi6UoJHyE2audEAzW2KnJocKKBLbmP65Mw=;
 b=/C9B8KGtU5uhM5nYZ8q0JSK6VGi0voUYFXylhkxYG7PmyAnR++MmiAvRTmbU+FD8dechEU4Ui
 na9TynqDWYFCdQhED+QUg25dI7mHPwyuaoFak7noES3RIqdTlve+LFj
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LPASS VA CSR block contains rate generator hardware that produces
a HeartBeat Pulse (also known as RateGen Pulse). This pulse
synchronizes the start of the DMAs and Codec Interfaces for the audio
usecases and can serve as a periodic wakeup source for the DSP.

This series adds the DT binding and driver support to model this
rate generator as a clock provider, and extends the VA macro binding
with a new hawi variant that consumes the heartbeatpulse clock
alongside its existing mclk, macro, and dcodec clocks.

Patch 1 adds the YAML binding for the new qcom,hawi-lpass-va-csr
clock provider node.

Patch 2 extends qcom,lpass-va-macro to describe the new
qcom,hawi-lpass-va-macro compatible with its four-clock constraint.

Patch 3 adds the lpass-va-csr driver that registers the
lpass_heartbeat_pulse clock and enables/disables the rate generator
via regmap when the clock consumer requests it.

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
Changes in v2:
- Split the DT binding patch into two: one for the new
  qcom,lpass-va-csr binding, one for the qcom,lpass-va-macro
  extension (Srinivas).
- Fixed the qcom,lpass-va-csr example so it uses a 2-cell reg
  under a proper #address-cells/#size-cells parent node, fixing
  dt_binding_check (Rob).
- Switched the heartbeatpulse clk_ops from atomic
  enable/disable/is_enabled to sleepable prepare/unprepare/is_prepared,
  since regmap with a maple tree cache is not safe to call from the
  raw spinlock context the atomic ops run under.
- Checked and propagated regmap_write()/regmap_read() return values
  instead of ignoring them.
- Used regmap_set_bits()/regmap_clear_bits()/regmap_test_bits() instead
  of manual regmap_update_bits()/regmap_read() combos (Konrad).
- Used lowercase hex for register offset defines (Konrad).
- Link to v1: https://lore.kernel.org/linux-arm-msm/20260714-master-v1-0-1ebe5993225e@oss.qualcomm.com/

---
Sarath Ganapathiraju (3):
      ASoC: dt-bindings: qcom,lpass-va-csr: Add HeartBeat pulse clock
      ASoC: dt-bindings: qcom,lpass-va-macro: Add hawi heartbeatpulse clock
      ASoC: Add LPASS VA CSR heartbeat pulse clock

 .../bindings/sound/qcom,lpass-va-csr.yaml          |  52 ++++++++
 .../bindings/sound/qcom,lpass-va-macro.yaml        |  18 +++
 sound/soc/codecs/Kconfig                           |  13 ++
 sound/soc/codecs/Makefile                          |   2 +
 sound/soc/codecs/lpass-va-csr.c                    | 143 +++++++++++++++++++++
 5 files changed, 228 insertions(+)
---
base-commit: 1a1757b76427f6201bfe0bf1bea9f7574f332a93
change-id: 20260714-master-ca87b5f19ae0

Best regards,
--  
Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>

