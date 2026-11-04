From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH 0/7] arm64: dts: qcom: sm8350: Add SoundWire and LPASS
Date: Wed, 04 Nov 2026 18:07:08 +0000
Message-Id: <20261104-b4-sm8350-sound-v1-0-4c872df294fa@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQxFS0VykuTBx1hEbJGBHEu
 ze1y7f4/wShyCTwKk6ItLPwEjL0owA/dWEk5D4bjDKV1sqisyifunwqlCWFHqlzplHW+KFuIFd
 rpIGP+/hu/5bkZvLbbwPX9QXVuT6YcwAAAA==
X-Change-ID: 20261104-b4-sm8350-sound-eab29042cf89
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-sound@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815654; l=2038;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=fNBkRx9oOq8JcXG9i2p9apIYE9Yo40nYXqote7bxW7w=;
 b=o+uWwnaZIlViseX7pK0bL3/DF7R5FDEX9+1gjo8H8V16mzfT87FBFOM2NbKaHW53knKx5DsPq
 DCT8rBR2POgBrl1RdDDSUPI4kKF/80aapRv8Iuwo8cOisy/7jfcwP/j
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8350 has the ADSP audio services in its dtsi but none of the LPASS
codec macros or SoundWire controllers, so boards can't describe their
codecs and DMICs yet. This series adds the RX, TX and VA macros with
their SoundWire controllers, and the SM8350 sound card compatible.

Patches 1-2 go through clk, 3-5 and 7 through ASoC, 6 through qcom
arm64. The macros use the data the drivers already have: RX that of
SM8250, TX that of SM8450, VA that of SC7280.

Tested on the Razer Edge 5G: both DMICs record through the VA macro and
the WCD9380 enumerates on the RX and TX buses. Capture from the
WCD9380's ADCs through the TX macro is silent with the SM8450 data, and
headphone playback isn't tested. The WSA macro is left out: this board
has no WSA amplifiers to test it with.

Prepared with the help of an AI coding assistant, reviewed and tested
by me.

---
Demeter Barna (7):
      dt-bindings: clock: qcom,sc8280xp-lpasscc: Add SM8350 LPASS audio CSR
      clk: qcom: lpassaudiocc-sc7280: Add SM8350 audio CSR resets
      ASoC: dt-bindings: qcom,lpass-rx-macro: Add SM8350 LPASS RX
      ASoC: dt-bindings: qcom,lpass-tx-macro: Add SM8350 LPASS TX
      ASoC: dt-bindings: qcom,lpass-va-macro: Add SM8350 LPASS VA
      arm64: dts: qcom: sm8350: Add SoundWire and LPASS
      ASoC: dt-bindings: qcom,sm8250: Add SM8350 sound card

 .../bindings/clock/qcom,sc8280xp-lpasscc.yaml      |   1 +
 .../bindings/sound/qcom,lpass-rx-macro.yaml        |  12 +-
 .../bindings/sound/qcom,lpass-tx-macro.yaml        |  12 +-
 .../bindings/sound/qcom,lpass-va-macro.yaml        |   3 +
 .../devicetree/bindings/sound/qcom,sm8250.yaml     |   3 +
 arch/arm64/boot/dts/qcom/sm8350.dtsi               | 196 +++++++++++++++++++++
 drivers/clk/qcom/lpassaudiocc-sc7280.c             |   4 +
 7 files changed, 223 insertions(+), 8 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-b4-sm8350-sound-eab29042cf89

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

