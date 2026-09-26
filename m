From: Sam Day <me@samcday.com>
Subject: [PATCH v5 0/3] Add support and enable the debug UART in the Pixel
 3a and Pixel 3a XL
Date: Sat, 26 Sep 2026 18:41:31 +1000
Message-Id: <20260926-pabloyoyoista-debug-uart-on-rdacayan-next-v5-0-db74ff64a7e7@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/53OzW6DMBAE4FdBPmcr478Cp75H1cPaXhK3Daa2Q
 UER716RVsqlOZTjjEb65soypUCZddWVJZpDDnFgXaUPFXMnHI4EwbOuYoILw6VoYET7GZe4xJA
 Lgic7HWHCVCAOkDw6XHCAgS4FTCueldSNo16xQ8XGRH243KzXt5+cJ/tOrmzA7yLR1xRyKPfZK
 eQS03J7ONdbu+fMXAMHbtH2ulHovH0ZYy5nTB9UYn6K6cg2bBa7AQEctETrW2+bnuMDQN4Bw+v
 /ABI4mN47b0wrjaIHgNoNKODgtNe1961xyP8A1nX9BpuTjkMzAgAA
X-Change-ID: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790412092; l=2823;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=kbNYB6AwQiVWj7uPymDdVKanxCUYoEDfo1zBkhPJMiE=;
 b=iCOLr0tjFHaWSubRSaoEj589H/CFuDCD/wqMSSWqEYsvnpeCT39UtpELc3Re2MhDFgVvdh3tI
 NHLM8r9r+R/BrjrEIhCQMWwyvEexHzVmWtjM2iCFVjlWKb2U6f2izey
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to get logs through the SBU pins in Google Pixel devices, it is
necessary to add support to the devicetree, and enable the corresponding
UART. With this code and an USB-Cereal board, I was able to get full kernel
logs through serial.

The previous paragraph is Pablo's original cover letter. I (Sam) decided
to pick this series up and send this v5, since v4 has been sitting on
the list for a while now.

I've been using the v4 series on my Pixel 3a for a few months now. It
works fine, and the unnecessary RX pull-up didn't seem to cause any
issues in practice.

The v5 changes to patch 1 and 3 were authored and verified on device by
an LLM, hence the Assisted-by tag on those two.

The changes were validated with a USB-C breakout and a typical FT232R
USB-TTL dongle wired up to the SBU+GND pins.

The console was tested with and without the RX pull-up and no difference
was observed. However, I did not test a floating RX with nothing
connected. As Konrad pointed out in v4, the downstream sources do not
specify a pull-up (see link), so it was removed.

Link: https://android.googlesource.com/kernel/msm/+/ab4493f31457eea175568b18b8300d4d12aaeea8/arch/arm64/boot/dts/qcom/sdm670-pinctrl.dtsi#963
Signed-off-by: Sam Day <me@samcday.com>
---
Changes in v5:
- Picked up by Sam Day, retaining Pablo's authorship.
- 1/3: Drop the unused qup_uartN_tx/qup_uartN_rx subnode labels
- 1/3: Move default pin config to sdm670.dtsi
- 3/3: Drop board-level TX/RX pinconf, RX pull-up, stale Depends
  link, and v4 R-b tags.
- Link to v4: https://lore.kernel.org/r/20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-0-c5d51dd96ca0@postmarketos.org

Changes in v4:
- Picked Reviewed-by tags
- Link to v3: https://patch.msgid.link/20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-0-6fdcd669364e@postmarketos.org

Changes in v3:
- Drop dependency on already-picked patches
- Link to v2: https://patch.msgid.link/20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-0-53abd9db8f0a@postmarketos.org

Changes in v2:
- Fix typo in (3/3) commit message
- Link to v1: https://patch.msgid.link/20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org

---
Pablo Correa Gómez (3):
      arm64: dts: qcom: sdm670: add default uart pinctrl nodes
      arm64: dts: qcom: sdm670: add debug uart soc node
      arm64: dts: qcom: sdm670-google-common: enable debug uart

 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi |   8 +-
 arch/arm64/boot/dts/qcom/sdm670.dtsi               | 271 +++++++++++++++++++++
 2 files changed, 278 insertions(+), 1 deletion(-)
---
base-commit: fe2ec83746e501645709761605c2464a44fd2929
change-id: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4

Best regards,
-- 
Sam Day <me@samcday.com>

