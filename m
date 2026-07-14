From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v3 0/3] SM8450 QoL changes (dispcc)
Date: Mon, 13 Jul 2026 23:28:16 -0400
Message-Id: <20260713-sm8450-qol-dispcc-v3-0-56fd05822270@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23OTQ7CIBAF4Ks0rMXAVPrjynsYFxSmFqOlQiWap
 ncX2oVduHzJe9/MRDw6g54cs4k4DMYb28eQ7zKiOtlfkRodMwEGBSs5p/5RHQSjT3un2vhBKcr
 qBmrBNYiGkbgbHLbmvZjny5r9q7mhGhOUGp3xo3Wf5Wjgqbf6BcDWD5wympcIiJVuay1Pg7Oj7
 fcPJAkO8Jv+fy1AFFrFJSulEgXjW2Ge5y/b+/eL/wAAAA==
X-Change-ID: 20260711-sm8450-qol-dispcc-09b2951d25b0
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Jagadeesh Kona <quic_jkona@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783999716; l=1177;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=JdOoLbfe0MaF2NMru1U5JBxp1QJaJwlAcDS/AaomInI=;
 b=B+1ZcpSdJMfXW2NFB/f1nGzhhq0xUceCDKASb0H43sdOqHf+HQf22wUfgQcRPYyT+t3r6QCcV
 A06wQ0ylBX3BejDF/BchCCBL6Wc0ZbyLg42uD+YC7+FT3kzgTFy1/jE
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches are mainly focused on getting a flickerless boot process
on SM8475 based devices.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v3:
- Apply suggestions from Konrad
- Link to v2: https://patch.msgid.link/20260711-sm8450-qol-dispcc-v2-0-fc1a07ac5601@proton.me

Changes in v2:
- Split series in subseries (dispcc, dts, qmp, smmu)
- Migrate to qcom_cc_driver_data (Konrad)
- Split mdss patch into 3 patches
- Use Fixes tag where applicable (Krzysztof)
- Link to v1: https://patch.msgid.link/20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me

---
Esteban Urrutia (3):
      clk: qcom: dispcc-sm8450: Fix disp_cc_mdss_mdp_clk_src ops
      clk: qcom: dispcc-sm8450: Migrate to qcom_cc_driver_data
      clk: qcom: alpha-pll: Check Lucid Ole PLL status before configuring

 drivers/clk/qcom/clk-alpha-pll.c |  9 +++++++++
 drivers/clk/qcom/dispcc-sm8450.c | 40 +++++++++++++++++++++++++++++-----------
 2 files changed, 38 insertions(+), 11 deletions(-)
---
base-commit: bee763d5f341b99cf472afeb508d4988f62a6ca1
change-id: 20260711-sm8450-qol-dispcc-09b2951d25b0

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

