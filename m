From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v10 0/4] media: qcom: venus: add MSM8939 support
Date: Fri, 31 Jul 2026 22:08:19 +0200
Message-Id: <20260731-msm8939-venus-rfc-v10-0-9ac503250fc7@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33QzU7DMAwA4FeZciYocf5qTrwH4tBkzhZEW9RsF
 Wjqu5OOA1GJONqyP//cWKY5UWZPhxubaUk5TWMJpHg4sHDuxxPxdCwJBgKs0NLyIQ8dKuQLjdf
 M5xh4EGCCDk7Hnljp+5gpps87+vL6E+erf6Nw2aCt4pzyZZq/7lMXudX95y+SC94LjCFCAHWMz
 6ehT++PYRrY5i9QCWBaAhQhWiQDXlkQbi+oWnAtQRUBuk6i8d6h/CPoX8GI5hW6CIg6GvIAffB
 7wdRCcwdThKPzhnoIZFDuBVsJUrQEWwSyqK1RzqAQe8HVgm4JrghKBRts9Aid2QtYCdD8AxbBe
 yksRhVJQC2s6/oNl80JKZMCAAA=
X-Change-ID: 20260416-msm8939-venus-rfc-c025c4c74fae
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vikash Garodia <vikash.garodia@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>
Cc: Erikas Bitovtas <xerikasxx@gmail.com>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 linux-arm-msm@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-clk@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785528647; l=6841;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=Na6HkfrhPXQl+SozKGzkuOsDDVi1gh09E88B4T6y8pY=;
 b=QhggbNljO9KqKoFfxZTeGbWWS6a4/zM/OXnmKHL/QD+jxIwdz84R7fZyt2SM3agyCoDFWaPJz
 kbSj82DsVyjBCcsQdif+V9/UNmxcoURHlNeJkjD/dLThcSsHt/zhyJk
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for Venus on MSM8939. It is mostly
similar to MSM8916 Venus, except it needs two additional cores to be
powered on before it can start decoding.

As per Dmitry's request, I am attaching Fluster results and
v4l2-compliance output. Fluster results were very inconsistent and
caused power collapse fails.
H.264: https://pastebin.com/C15qeq5W
H.265 (HEVC): https://pastebin.com/WDsnxvuk
VP8: https://pastebin.com/egAgEm15
v4l2-compliance: https://pastebin.com/VpBhEFc1
Power collapse fail log: https://pastebin.com/rTivMcpK

Signed-off-by: Erikas Bitovtas <xerikasxx@gmail.com>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
Changes in v10:
- Drop applied patches
- Apply R-b tags
- Extend commit message (halt check)
- Improve format of video-codec@1d00000 node
- Link to v9: https://patch.msgid.link/20260526-msm8939-venus-rfc-v9-0-bb1069f3fe02@gmail.com

Changes in v9:
- Squashed conversion of MSM8916 to a new blacklisting mechanism back
  into one commit.
- Extracted passing hardware control to GDSCs into a new function. Power
  control is now passed to hardware after core clocks are enabled, not
  before.
- Set halt check for Venus core clocks to BRANCH_HALT.
- Link to v8: https://patch.msgid.link/20260519-msm8939-venus-rfc-v8-0-542ec7557ebc@gmail.com

Changes in v8:
- Only enable vcodec clks if power domains attatched to them are
  present.
- Reworded GDSC clock commit. Frankly, I'm not sure why exactly it
  happens, I only know that if I don't set this flag and pass control to
  hardware, the cores won't power up.
- Extracted conversion of MSM8916 to a new blacklisting mechanism into a
  commit of its own.
- Fixed GDSC power domain not being powered off after failing to pass
  control to hardware.
- Reordered commits to include schema first, then driver changes, then
  device tree source.
- Link to v7: https://patch.msgid.link/20260514-msm8939-venus-rfc-v7-0-33c6c6fb9285@gmail.com

Changes in v7:
- Moved codec blacklist mechanism to be applied before MSM8939 struct is
  added.
- Vcodec power domains are attached with a managed method now.
- Removed duplicate clock rates in msm8939_freq_tbl.
- Redid the merge of vcodec_clks done in v5.
- Removed the {vdec,venc}_{get,power}() methods and moved them to their
  respective core_* parts. Vcodec cores are now powered up along with
  the core.
- Switched HW_CTRL to HW_CTRL_TRIGGER in Venus core GDSCs. They are now
  powered up first, then their control is passed to hardware.
- For now, document just the change of halt check in the commit message
  of setting GDSCs to hardware controlled. I'm not sure what happens
  exactly, but if they are set to BRANCH_HALT, probing the driver fails:
  https://pastebin.com/EYQekR1p
- Given the power management behavior has changed substantially in the
  power domain enable logic patch, I removed Bryan's "Reviewed-by: "
  tag.
- Link to v6: https://patch.msgid.link/20260510-msm8939-venus-rfc-v6-0-e69465375900@gmail.com

Changes in v6:
- Added a more generic mechanism on blacklisting codecs.
- Reworded a commit for setting Venus core GDSCs to hardware controlled.
- Reworded a commit for adding HEVC decoding to MSM8939.
- Link to v5: https://patch.msgid.link/20260507-msm8939-venus-rfc-v5-0-d7b5ea2ce591@gmail.com

Changes in v5:
- Undid the merge of vcodec_clks, they are split back to
  vcodec{0,1}_clks now.
- Extracted a dev_pm_domain_attach_list() call into a function of its
  own to reduce nesting.
- Added missing "power-domain-names" required property to device tree
  binding.
- Renamed vcodec clocks and power domains to match other Venus bindings.
- Reordered commits and grouped them by subsystems. Now first come DTB
  patches, then clock, then media.
- Removed "status = "disabled"" in the device tree example.
- Link to v4: https://patch.msgid.link/20260506-msm8939-venus-rfc-v4-0-994f5eb22acb@gmail.com

Changes in v4:
- Removed vcodec{0,1}_pmdomains and merged vcodec{0,1}_clks into
  vcodec_clks instead for MSM8939.
- Inlined video decoder and encoder device tree nodes in the driver and
  removed them from the binding.
- Kept vdec and venc methods for HFI v3 separate from HFI v1.
- {vdec,venc}_get() are now called as early as before, since it is no
  longer needed for us to attach power domains to dev_dec and dev_enc.
- Link to v3: https://patch.msgid.link/20260427-msm8939-venus-rfc-v3-0-288195bb7917@gmail.com

Changes in v3:
- Added missing vcodec1_clks to resource struct.
- Removed enc_nodename from resource struct since we include
  video-decoder now.
- Link to v2: https://patch.msgid.link/20260425-msm8939-venus-rfc-v2-0-f69e52b36207@gmail.com

Changes in v2:
- Enabled GDSCs during encoding as well.
- Merged vcodec{0,1}_pmdomains_num into vcodec_pmdomains_num.
- Reworded commit for marking GDSCs as hardware controlled. Same
  situation as in cdc59600bccf ("clk: qcom: gcc-msm8953: fix stuck venus0_core0 clock")
- Clarified the reason for missing firmware-name property in device
  tree.
- Clarified the reason for moving vdec_get and venc_get for later.
- Link to v1: https://patch.msgid.link/20260416-msm8939-venus-rfc-v1-0-a09fcf2c23df@gmail.com

To: Bryan O'Donoghue <bod@kernel.org>
To: Vikash Garodia <vikash.garodia@oss.qualcomm.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: André Apitzsch <git@apitzsch.eu>
To: Erikas Bitovtas <xerikasxx@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney@redhat.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-media@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: ~postmarketos/upstreaming@lists.sr.ht
Cc: phone-devel@vger.kernel.org

---
André Apitzsch (2):
      arm64: dts: qcom: msm8939: Add venus node
      arm64: dts: qcom: msm8939-longcheer-l9100: Enable venus node

Erikas Bitovtas (2):
      clk: qcom: gcc-msm8939: mark Venus core GDSCs as hardware controlled
      arm64: dts: qcom: msm8939-asus-z00t: add Venus

 arch/arm64/boot/dts/qcom/msm8939-asus-z00t.dts     |  8 +++++++
 .../boot/dts/qcom/msm8939-longcheer-l9100.dts      |  8 +++++++
 arch/arm64/boot/dts/qcom/msm8939.dtsi              | 26 ++++++++++++++++++++++
 drivers/clk/qcom/gcc-msm8939.c                     |  4 ++++
 4 files changed, 46 insertions(+)
---
base-commit: 415606a7be939835db9b0d6b711887586646346d
change-id: 20260416-msm8939-venus-rfc-c025c4c74fae

Best regards,
--  
André Apitzsch <git@apitzsch.eu>

