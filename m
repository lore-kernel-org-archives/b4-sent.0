From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Subject: [PATCH v11 0/2] Add LPASS VA CSR HeartBeat pulse clock support
Date: Mon, 12 Oct 2026 17:22:57 +0530
Message-Id: <20261012-master-v11-0-15009e3ecac3@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABnKzGoC/3XO0QqCMBQG4FeRXTc5OzK3ddV7RBdzzlxk1qZSi
 O/eNBChuhmc8X//OSMJ1jsbyD4ZibeDC669xYGxXUJMrW9nS10ZPwgC5qCYoI0OnfU0NyiErLj
 QSpMYvntbuefSdDx95tAXF2u6Wc+J2oWu9a9l1SDn3FfpIClQiVmJhpegQB/aENJHr6+mbZo0P
 mTuHtRGo1y1ihrjWRWoSmlQfzSDDc9g5QyiZ8ARRGE4Cv7DT9P0BrgEwiM0AQAA
X-Change-ID: 20260917-master-6c2778f57a9a
To: andersson@kernel.org, abelvesa@kernel.org, sboyd@kernel.org, 
 bmasney+clk@redhat.com, jbrunet+clk@baylibre.com, robh@kernel.org, 
 krzk+dt@kernel.org, conor+dt@kernel.org, 
 srinivas.kandagatla@oss.qualcomm.com, sarath.ganapathiraju@oss.qualcomm.com
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791805978; l=5722;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=tTPrx9tPFF6GXsRW5o15aooqoG1BjmEQXxJsueO1eTA=;
 b=qLVLKFGBrk2HEafG+rgq3XeCUTSQi2omQbMPqDobGlCBKFI20Ewus+Pga2xv9NehwNt72aJze
 gX5qHAuVam9DruF9jVbIUNP2JhqSboInfMMz33TyEEOZpjYBHl9Cwvz
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

Changes in v11:
- Rebase the series on linux-next next-20261009.
- Drop the custom heartbeat prepare/unprepare callbacks and rely on CCF
  provider runtime PM handling (Ajay).
- Restore the rate generator counter and delay registers from the
  runtime resume callback after the LPASS vote clocks are enabled
  (Sashiko).
- Add an of_device_get_match_data() NULL guard (Sashiko).
- Link to v10: https://patch.msgid.link/20260930-master-v10-0-105207bc5275@oss.qualcomm.com

Changes in v10:
- Rebase the series on linux-next next-20260929.
- Add clk_is_enabled_regmap() to report the heartbeat gate state for
  clk_disable_unused() (Sashiko).
- Add Rob's Reviewed-by tag to the binding patch.
- Link to v9: https://patch.msgid.link/20260928-master-v9-0-2277f09f9a09@oss.qualcomm.com

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

 .../bindings/clock/qcom,hawi-lpass-va-csr.yaml     |  62 +++++++
 drivers/clk/qcom/Kconfig                           |  14 ++
 drivers/clk/qcom/Makefile                          |   1 +
 drivers/clk/qcom/lpass-va-csr.c                    | 180 +++++++++++++++++++++
 4 files changed, 257 insertions(+)
---
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20260917-master-6c2778f57a9a

Best regards,
--  
Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>

