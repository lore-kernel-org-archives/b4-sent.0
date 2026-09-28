From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Subject: [PATCH v9 0/2] Add LPASS VA CSR HeartBeat pulse clock support
Date: Mon, 28 Sep 2026 21:27:37 +0530
Message-Id: <20260928-master-v9-0-2277f09f9a09@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHGOumoC/2WNQQ6CMBREr0L+2pJaA21deQ/DopaP1AjFfmg0p
 He34NLNJC95M7MCYXBIcC5WCBgdOT9m0IcCbG/GOzLXZgbBRc31UbLB0IyB1VZIqbpKGm0gy1P
 Azr33oWvzY1puD7Tz1t6M3tHsw2d/imrz/kajYpwpcWqFrVquubl4ovK1mKf1w1DmgCal9AUGo
 EqVtQAAAA==
X-Change-ID: 20260917-master-6c2778f57a9a
To: andersson@kernel.org, abelvesa@kernel.org, sboyd@kernel.org, 
 bmasney+clk@redhat.com, jbrunet+clk@baylibre.com, robh@kernel.org, 
 krzk+dt@kernel.org, conor+dt@kernel.org, 
 srinivas.kandagatla@oss.qualcomm.com, sarath.ganapathiraju@oss.qualcomm.com
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790611058; l=4925;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=0xzcm5sj4SGekYrVH6AWqOH+QnQkY5AbJXpOYR12MLY=;
 b=AchSNcp2Ob6OdJmmvMA1NoLcL2EmHizVL7J3nE+d8lH8dWdGXQ9aPVQge9qeNdjYc6TOyVkE+
 CN75Q6oOVn8Aj6oGAPnJoAbyIPza0DaRgon4rVvKelV2vrscRklrJPK
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LPASS VA CSR block contains rate generator hardware that produces
a HeartBeat Pulse (also known as RateGen Pulse). This pulse
synchronizes the start of the DMAs and Codec Interfaces for the audio
usecases and can serve as a periodic wakeup source for the DSP.

This series adds the DT binding and driver support to model this
rate generator as a clock provider.

Patch 1 adds the YAML binding for the new qcom,hawi-lpass-va-csr
clock provider node under Documentation/devicetree/bindings/clock/.

Patch 2 adds the lpass-va-csr driver under drivers/clk/qcom that
registers the lpass_heartbeat_pulse clock and enables/disables the
rate generator via regmap when the clock consumer requests it.

Changes in v9:
- Rebase the series on linux-next next-20260928.
- Add runtime PM callbacks so the LPASS LPR and audio vote clocks are
  enabled by pm_runtime_resume_and_get() before touching VA CSR
  registers.
- Keep the LPASS vote clocks enabled across heartbeat clock
  enable/disable register accesses by taking a runtime PM reference from
  the heartbeat clock prepare path.
- Use synchronous runtime PM put on probe success and error paths.
- Drop the one-use runtime PM error label while keeping synchronous puts (Konrad).
- Wrap the runtime PM ops with pm_ptr() from HTML review.
- Link to v8: https://patch.msgid.link/20260917-master-v8-0-823d2c5d090a@oss.qualcomm.com

Changes in v8:
- Rebase the series on linux-next next-20260916.
- Require the LPASS LPR and audio vote clocks to access VA CSR
  register space safely.
- Attach the DT vote clocks to runtime PM and resume the device before
  programming the rate generator registers.
- Program the counter and delay registers once during probe.
- Use qcom's simple regmap gate ops for the enable bit (Srinivas).
- Drop the unreachable of_device_get_match_data() NULL check (Srinivas).
- Drop stale Reviewed-by/Tested-by tags after the binding and driver
  changes.
- Link to v7: https://patch.msgid.link/20260831-heartbeat-v7-next-20260828-v7-0-e3ffeac46a51@oss.qualcomm.com

Changes in v7:
- Rebase the series on linux-next next-20260828.
- Add Prasad's Reviewed-by and Tested-by tags to patch 2.
- Link to v6: https://patch.msgid.link/20260821-heartbeat-v6-next-20260821-send-v6-0-62c5df84ce21@oss.qualcomm.com

Changes in v6:
- Rebase the series on linux-next next-20260821.
- Capitalize Hawi in binding text (Bjorn).
- Simplify the binding example by removing the soc wrapper and
  two-cell address/size setup (Bjorn).
- Keep the full VA CSR register window in the binding and describe it
  as the VA CSR register block after Konrad clarified the earlier
  register-range concern (Bjorn, Konrad).
- Link to v5: https://patch.msgid.link/20260806-master-20260805-sync-v5-0-0ff42e9b6431@oss.qualcomm.com

Changes in v5:
- Add explicit ARM64 Kconfig gating and Qualcomm default-module policy
  for QCOM_CLK_LPASS_HEARTBEAT_PULSE to align with nearby qcom clock
  entries.
- Link to v4: https://patch.msgid.link/20260805-master-20260805-sync-v4-0-dfbcbf427c2c@oss.qualcomm.com

Changes in v4:
- Rename the binding filename and schema ID to hawi-specific naming:
  qcom,lpass-va-csr.yaml -> qcom,hawi-lpass-va-csr.yaml (Krzysztof).
- Rename Kconfig symbol QCOM_CLK_LPASS_VA_CSR to
  QCOM_CLK_LPASS_HEARTBEAT_PULSE (Konrad).
- Add devm_pm_runtime_enable() in the lpass-va-csr probe path.
- Drop the qcom,lpass-va-macro binding extension patch; it will be
  resubmitted with the Hawi DTSI changes.
- Drop sound/soc/codecs/Kconfig select wiring to keep this series
  clock-only (Konrad).
- Link to v3: https://lore.kernel.org/all/20260723-master-v3-0-3d67b79b0515@oss.qualcomm.com/

Changes in v3:
- Move the qcom,lpass-va-csr binding under
  Documentation/devicetree/bindings/clock/ (Krzysztof).
- Move the driver under drivers/clk/qcom/ (Krzysztof).
- Improve the schema description and use generic clock-controller node
  naming (Krzysztof).
- Use additionalProperties: false and keep compatibles sorted.

Changes in v2:
- Split the qcom,lpass-va-csr and qcom,lpass-va-macro bindings into
  separate patches.

Changes in v1:
- Initial version

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
Sarath Ganapathiraju (2):
      dt-bindings: clock: qcom: Add LPASS VA CSR HeartBeat pulse clock
      clk: qcom: Add LPASS VA CSR heartbeat pulse clock

 .../bindings/clock/qcom,hawi-lpass-va-csr.yaml     |  62 ++++++++
 drivers/clk/qcom/Kconfig                           |  14 ++
 drivers/clk/qcom/Makefile                          |   1 +
 drivers/clk/qcom/lpass-va-csr.c                    | 174 +++++++++++++++++++++
 4 files changed, 251 insertions(+)
---
base-commit: 6375e61c01e93e35ee7acd336a689ac1fae4b509
change-id: 20260917-master-6c2778f57a9a

Best regards,
--  
Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>

